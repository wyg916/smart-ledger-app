package com.offline.ledger.ui.viewmodel

import android.content.Context
import android.net.Uri
import androidx.work.ExistingPeriodicWorkPolicy
import com.offline.ledger.backup.BackupManager
import com.offline.ledger.data.prefs.SettingsRepository
import com.offline.ledger.data.repo.CategoryRepository
import com.offline.ledger.data.repo.TransactionRepository
import com.offline.ledger.export.ExportCategorySummaryRow
import com.offline.ledger.export.ExportDailySummaryRow
import com.offline.ledger.export.ExportTransactionRow
import com.offline.ledger.export.XlsxExporter
import com.offline.ledger.model.TransactionType
import com.offline.ledger.security.SecurePrefs
import com.offline.ledger.utils.DateTimeUtils
import com.offline.ledger.utils.MoneyUtils
import com.offline.ledger.worker.AutoBackupScheduler
import dagger.hilt.android.lifecycle.HiltViewModel
import dagger.hilt.android.qualifiers.ApplicationContext
import java.io.File
import java.time.YearMonth
import javax.inject.Inject
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope

enum class ExportRange { ThisMonth, LastMonth }
enum class ExportType { All, Expense, Income }

data class BackupUiItem(
    val uri: Uri,
    val displayName: String,
    val sizeBytes: Long,
    val modifiedAtMillis: Long,
    val isAuto: Boolean,
)

data class ToolsUiState(
    val exportRange: ExportRange = ExportRange.ThisMonth,
    val exportType: ExportType = ExportType.All,
    val autoBackupEnabled: Boolean = false,
    val backupPasswordConfigured: Boolean = false,
    val backups: List<BackupUiItem> = emptyList(),
    val busy: Boolean = false,
)

sealed interface ToolsEvent {
    data class Toast(val message: String) : ToolsEvent
    data object RestoreOk : ToolsEvent
    data object ExportOk : ToolsEvent
    data object BackupOk : ToolsEvent
    data object BackupPasswordSetOk : ToolsEvent
}

@HiltViewModel
class ToolsViewModel @Inject constructor(
    @ApplicationContext private val context: Context,
    private val transactionRepository: TransactionRepository,
    private val categoryRepository: CategoryRepository,
    private val settingsRepository: SettingsRepository,
    private val securePrefs: SecurePrefs,
) : ViewModel() {
    private val exportRange = MutableStateFlow(ExportRange.ThisMonth)
    private val exportType = MutableStateFlow(ExportType.All)
    private val busy = MutableStateFlow(false)
    private val backupPasswordConfigured = MutableStateFlow(securePrefs.hasBackupPasswordConfigured())
    private val backups = MutableStateFlow<List<BackupUiItem>>(emptyList())

    private var backupPasswordFailCount: Int = 0
    private var backupPasswordLockedUntilMillis: Long = 0L

    private val autoBackupEnabled: StateFlow<Boolean> =
        settingsRepository.autoBackupEnabledFlow.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), false)

    val events: MutableSharedFlow<ToolsEvent> = MutableSharedFlow(extraBufferCapacity = 16)

    private data class CoreState(
        val range: ExportRange,
        val type: ExportType,
        val autoBackup: Boolean,
        val backupPasswordConfigured: Boolean,
        val backups: List<BackupUiItem>,
    )

    private val coreState: StateFlow<CoreState> = combine(
        exportRange,
        exportType,
        autoBackupEnabled,
        backupPasswordConfigured,
        backups,
    ) { range, type, auto, pwd, list ->
        CoreState(
            range = range,
            type = type,
            autoBackup = auto,
            backupPasswordConfigured = pwd,
            backups = list,
        )
    }.stateIn(
        viewModelScope,
        SharingStarted.WhileSubscribed(5_000),
        CoreState(ExportRange.ThisMonth, ExportType.All, false, false, emptyList()),
    )

    val uiState: StateFlow<ToolsUiState> = combine(coreState, busy) { core, b ->
        ToolsUiState(
            exportRange = core.range,
            exportType = core.type,
            autoBackupEnabled = core.autoBackup,
            backupPasswordConfigured = core.backupPasswordConfigured,
            backups = core.backups,
            busy = b,
        )
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), ToolsUiState())

    init {
        refreshBackups()
    }

    fun setExportRange(range: ExportRange) {
        exportRange.value = range
    }

    fun setExportType(type: ExportType) {
        exportType.value = type
    }

    fun setBackupPassword(
        newPassword: String,
        oldPassword: String? = null,
    ) {
        viewModelScope.launch {
            if (newPassword.isBlank()) {
                events.tryEmit(ToolsEvent.Toast("密码不能为空"))
                return@launch
            }

            busy.value = true
            try {
                val now = System.currentTimeMillis()
                if (now < backupPasswordLockedUntilMillis) {
                    events.tryEmit(ToolsEvent.Toast("请稍后再试"))
                    return@launch
                }

                val hasOld = securePrefs.hasBackupPasswordConfigured()
                if (hasOld) {
                    val old = oldPassword.orEmpty()
                    if (old.isBlank()) {
                        events.tryEmit(ToolsEvent.Toast("请输入旧密码"))
                        return@launch
                    }
                    val ok = withContext(Dispatchers.Default) { securePrefs.verifyBackupPassword(old) }
                    if (!ok) {
                        backupPasswordFailCount += 1
                        if (backupPasswordFailCount >= 5) {
                            backupPasswordFailCount = 0
                            backupPasswordLockedUntilMillis = now + 30_000L
                            events.tryEmit(ToolsEvent.Toast("旧密码错误次数过多，请稍后再试"))
                        } else {
                            events.tryEmit(ToolsEvent.Toast("旧密码错误"))
                        }
                        return@launch
                    }
                }

                withContext(Dispatchers.Default) { securePrefs.setBackupPassword(newPassword) }
                backupPasswordFailCount = 0
                backupPasswordLockedUntilMillis = 0L
                backupPasswordConfigured.value = securePrefs.hasBackupPasswordConfigured()
                events.tryEmit(ToolsEvent.Toast("备份密码已设置"))
                events.tryEmit(ToolsEvent.BackupPasswordSetOk)

                if (autoBackupEnabled.value) scheduleAutoBackup()
            } catch (t: Throwable) {
                events.tryEmit(ToolsEvent.Toast(t.message ?: "设置失败"))
            } finally {
                busy.value = false
            }
        }
    }

    fun resetBackupPassword() {
        viewModelScope.launch {
            busy.value = true
            try {
                withContext(Dispatchers.Default) { securePrefs.resetBackupPassword() }
                backupPasswordConfigured.value = securePrefs.hasBackupPasswordConfigured()

                settingsRepository.setAutoBackupEnabled(false)
                cancelAutoBackup()

                events.tryEmit(ToolsEvent.Toast("已清除备份密码"))
                events.tryEmit(ToolsEvent.BackupPasswordSetOk)
            } catch (t: Throwable) {
                events.tryEmit(ToolsEvent.Toast(t.message ?: "操作失败"))
            } finally {
                busy.value = false
            }
        }
    }

    fun setAutoBackupEnabled(enabled: Boolean) {
        viewModelScope.launch {
            settingsRepository.setAutoBackupEnabled(enabled)
            if (enabled) scheduleAutoBackup() else cancelAutoBackup()
        }
    }

    fun createManualBackup() {
        if (!securePrefs.hasBackupPasswordConfigured()) {
            events.tryEmit(ToolsEvent.Toast("请先设置备份密码"))
            return
        }
        viewModelScope.launch {
            busy.value = true
            try {
                BackupManager(context, securePrefs).createBackup(isAuto = false)
                refreshBackups()
                events.tryEmit(ToolsEvent.BackupOk)
            } catch (t: Throwable) {
                events.tryEmit(ToolsEvent.Toast(t.message ?: "备份失败"))
            } finally {
                busy.value = false
            }
        }
    }

    fun restoreFromUri(uri: Uri, password: String) {
        viewModelScope.launch {
            busy.value = true
            try {
                BackupManager(context, securePrefs).restoreFromUri(uri, password)
                events.tryEmit(ToolsEvent.RestoreOk)
            } catch (t: Throwable) {
                events.tryEmit(ToolsEvent.Toast(t.message ?: "恢复失败"))
            } finally {
                busy.value = false
            }
        }
    }

    fun restoreFromFile(file: File, password: String) {
        viewModelScope.launch {
            busy.value = true
            try {
                BackupManager(context, securePrefs).restoreFromFile(file, password)
                events.tryEmit(ToolsEvent.RestoreOk)
            } catch (t: Throwable) {
                events.tryEmit(ToolsEvent.Toast(t.message ?: "恢复失败"))
            } finally {
                busy.value = false
            }
        }
    }

    fun exportExcel(uri: Uri) {
        viewModelScope.launch {
            busy.value = true
            try {
                val (start, end, typeFilter) = exportConfig()
                val txs = withContext(Dispatchers.IO) {
                    transactionRepository.getTransactionsForExport(start, end, typeFilter)
                }
                val categories = withContext(Dispatchers.IO) { categoryRepository.getAllCategories() }
                val catMap = categories.associateBy { it.id }

                val details = txs.map { tx ->
                    val cat = catMap[tx.categoryId]
                    ExportTransactionRow(
                        dateTime = DateTimeUtils.formatDateTime(tx.occurredAt),
                        type = if (tx.type == TransactionType.Expense) "支出" else "收入",
                        category = cat?.name ?: "未知分类",
                        amountNumber = MoneyUtils.formatCents(tx.amountCent),
                        note = tx.note,
                    )
                }

                val categorySummary = buildCategorySummary(details)
                val dailySummary = buildDailySummary(txs)

                val xlsxBytes = XlsxExporter.export(details, categorySummary, dailySummary)
                withContext(Dispatchers.IO) {
                    context.contentResolver.openOutputStream(uri)?.use { it.write(xlsxBytes) }
                        ?: error("无法写入文件")
                }
                events.tryEmit(ToolsEvent.ExportOk)
            } catch (t: Throwable) {
                events.tryEmit(ToolsEvent.Toast(t.message ?: "导出失败"))
            } finally {
                busy.value = false
            }
        }
    }

    fun refreshBackups() {
        viewModelScope.launch {
            val items = withContext(Dispatchers.IO) {
                val manager = BackupManager(context, securePrefs)
                manager.migrateLegacyBackupsToMediaStoreIfPossible()
                manager.listBackups()
            }
            backups.value = items.map { e ->
                BackupUiItem(
                    uri = e.uri,
                    displayName = e.displayName,
                    sizeBytes = e.sizeBytes,
                    modifiedAtMillis = e.modifiedAtMillis,
                    isAuto = e.isAuto,
                )
            }
            backupPasswordConfigured.value = securePrefs.hasBackupPasswordConfigured()
        }
    }

    private fun scheduleAutoBackup() {
        AutoBackupScheduler.scheduleDaily(context, ExistingPeriodicWorkPolicy.UPDATE)
        AutoBackupScheduler.enqueueNow(context)
    }

    private fun cancelAutoBackup() {
        AutoBackupScheduler.cancelDaily(context)
    }

    private fun exportConfig(): Triple<Long, Long, Int?> {
        val ym = when (exportRange.value) {
            ExportRange.ThisMonth -> YearMonth.now()
            ExportRange.LastMonth -> YearMonth.now().minusMonths(1)
        }
        val start = DateTimeUtils.startOfMonthMillis(ym)
        val end = DateTimeUtils.endOfMonthMillis(ym)
        val typeFilter = when (exportType.value) {
            ExportType.All -> null
            ExportType.Expense -> TransactionType.Expense
            ExportType.Income -> TransactionType.Income
        }
        return Triple(start, end, typeFilter)
    }

    private fun buildCategorySummary(details: List<ExportTransactionRow>): List<ExportCategorySummaryRow> {
        val grouped = details.groupBy { it.type }
        val result = mutableListOf<ExportCategorySummaryRow>()

        grouped.forEach { (type, rows) ->
            val sums = rows.groupBy { it.category }.mapValues { (_, list) ->
                list.sumOf { centsFromNumberString(it.amountNumber) }
            }
            val counts = rows.groupBy { it.category }.mapValues { (_, list) -> list.size.toLong() }
            val total = sums.values.sum()

            sums.entries.sortedByDescending { it.value }.forEach { (cat, sumCent) ->
                val percent = if (total <= 0L) "0.00%" else {
                    val bp = (sumCent * 10000) / total
                    "${bp / 100}.${(bp % 100).toString().padStart(2, '0')}%"
                }
                result.add(
                    ExportCategorySummaryRow(
                        type = type,
                        category = cat,
                        totalNumber = MoneyUtils.formatCents(sumCent),
                        count = counts[cat] ?: 0L,
                        percent = percent,
                    ),
                )
            }
        }
        return result
    }

    private fun buildDailySummary(txs: List<com.offline.ledger.data.db.entity.TransactionEntity>): List<ExportDailySummaryRow> {
        val byDay = txs.groupBy { DateTimeUtils.localDateFromMillis(it.occurredAt) }.toSortedMap()
        return byDay.map { (day, list) ->
            val expense = list.filter { it.type == TransactionType.Expense }.sumOf { it.amountCent }
            val income = list.filter { it.type == TransactionType.Income }.sumOf { it.amountCent }
            val net = income - expense
            ExportDailySummaryRow(
                date = day.toString(),
                expenseNumber = MoneyUtils.formatCents(expense),
                incomeNumber = MoneyUtils.formatCents(income),
                netNumber = MoneyUtils.formatCents(net),
            )
        }
    }

    private fun centsFromNumberString(number: String): Long {
        return MoneyUtils.amountInputToCents(number) ?: 0L
    }

}
