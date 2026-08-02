package com.offline.ledger.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.offline.ledger.data.db.model.DailySummaryRow
import com.offline.ledger.data.prefs.BudgetItem
import com.offline.ledger.data.prefs.SettingsRepository
import com.offline.ledger.data.repo.CategoryRepository
import com.offline.ledger.data.repo.StatsRepository
import com.offline.ledger.data.repo.TransactionFilter
import com.offline.ledger.data.repo.TransactionRepository
import com.offline.ledger.model.TransactionType
import com.offline.ledger.utils.DateTimeUtils
import dagger.hilt.android.lifecycle.HiltViewModel
import java.time.YearMonth
import javax.inject.Inject
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

data class BudgetItemSummaryUi(
    val id: String,
    val name: String,
    val budgetCent: Long,
    val spentCent: Long,
    val remainingCent: Long,
    val remainingRatio: Float,
    val preset: Boolean,
)

data class DiscoverUiState(
    val yearMonth: YearMonth = YearMonth.now(),
    val monthIncomeCent: Long = 0,
    val monthExpenseCent: Long = 0,
    val monthBalanceCent: Long = 0,
    val budgetCent: Long = 0,
    val budgetRemainingCent: Long = 0,
    val budgetRemainingRatio: Float = 0f,
    val budgetItems: List<BudgetItemSummaryUi> = emptyList(),
)

@HiltViewModel
class DiscoverViewModel @Inject constructor(
    statsRepository: StatsRepository,
    private val settingsRepository: SettingsRepository,
    private val categoryRepository: CategoryRepository,
    transactionRepository: TransactionRepository,
) : ViewModel() {
    private val yearMonth: YearMonth = YearMonth.now()
    private val start = DateTimeUtils.startOfMonthMillis(yearMonth)
    private val end = DateTimeUtils.endOfMonthMillis(yearMonth)

    private val dailyFlow = statsRepository.observeDailySummary(start, end)
    private val expenseTxFlow = transactionRepository.observeTransactions(
        TransactionFilter(
            startInclusive = start,
            endInclusive = end,
            type = TransactionType.Expense,
            categoryId = null,
            keyword = null,
        ),
    )

    val uiState: StateFlow<DiscoverUiState> = combine(
        dailyFlow,
        settingsRepository.monthlyBudgetCentFlow,
        settingsRepository.budgetItemsFlow,
        expenseTxFlow,
    ) { dailyRows: List<DailySummaryRow>, budgetCent: Long, items: List<BudgetItem>, expenseTxs ->
        val expenseCent = dailyRows.sumOf { it.expenseCent }
        val incomeCent = dailyRows.sumOf { it.incomeCent }
        val balanceCent = incomeCent - expenseCent
        val remainingCent = (budgetCent - expenseCent).coerceAtLeast(0L)
        val remainingRatio = if (budgetCent <= 0L) 0f else (remainingCent.toFloat() / budgetCent.toFloat()).coerceIn(0f, 1f)

        val sumsByCategory: Map<Long, Long> = expenseTxs
            .groupBy { it.categoryId }
            .mapValues { (_, list) -> list.sumOf { it.amountCent } }

        val budgetItems = items
            .sortedWith(compareByDescending<BudgetItem> { it.preset }.thenBy { it.name })
            .map { item ->
                val spent = item.categoryIds.sumOf { sumsByCategory[it] ?: 0L }
                val itemRemaining = (item.budgetCent - spent).coerceAtLeast(0L)
                val itemRatio = if (item.budgetCent <= 0L) 0f else (itemRemaining.toFloat() / item.budgetCent.toFloat()).coerceIn(0f, 1f)
                BudgetItemSummaryUi(
                    id = item.id,
                    name = item.name,
                    budgetCent = item.budgetCent,
                    spentCent = spent,
                    remainingCent = itemRemaining,
                    remainingRatio = itemRatio,
                    preset = item.preset,
                )
            }

        DiscoverUiState(
            yearMonth = yearMonth,
            monthIncomeCent = incomeCent,
            monthExpenseCent = expenseCent,
            monthBalanceCent = balanceCent,
            budgetCent = budgetCent,
            budgetRemainingCent = remainingCent,
            budgetRemainingRatio = remainingRatio,
            budgetItems = budgetItems,
        )
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), DiscoverUiState())

    init {
        viewModelScope.launch {
            ensurePresetItems()
        }
    }

    private suspend fun ensurePresetItems() {
        val current = settingsRepository.getBudgetItems()
        val byId = current.associateBy { it.id }
        val expenseCategories = categoryRepository.getAllCategories().filter { it.type == TransactionType.Expense }
        val nameToId = expenseCategories.associate { it.name to it.id }

        val presets = listOf(
            PresetDef(
                id = "preset_food",
                name = "伙食费",
                categoryNames = setOf("餐费", "漂亮饭", "蔬菜", "水果", "零食"),
            ),
            PresetDef(
                id = "preset_utilities",
                name = "水电费",
                categoryNames = setOf("水费", "电费"),
            ),
            PresetDef(
                id = "preset_fun",
                name = "娱乐费",
                categoryNames = setOf("娱乐", "运动", "烟酒", "彩票"),
            ),
            PresetDef(
                id = "preset_shopping",
                name = "网购费",
                categoryNames = setOf("购物", "日用", "数码", "服饰", "美容", "快递"),
            ),
        )

        var changed = false
        val updated = current.toMutableList()

        presets.forEach { def ->
            val resolvedIds = def.categoryNames.mapNotNull { nameToId[it] }
            val existing = byId[def.id]
            if (existing == null) {
                updated.add(
                    BudgetItem(
                        id = def.id,
                        name = def.name,
                        budgetCent = 0L,
                        categoryIds = resolvedIds,
                        preset = true,
                    ),
                )
                changed = true
            } else {
                val needsPresetFlag = !existing.preset
                val needsCategories = existing.categoryIds.isEmpty() && resolvedIds.isNotEmpty()
                if (needsPresetFlag || needsCategories) {
                    val newItem = existing.copy(
                        preset = true,
                        categoryIds = if (needsCategories) resolvedIds else existing.categoryIds,
                    )
                    val idx = updated.indexOfFirst { it.id == existing.id }
                    if (idx >= 0) updated[idx] = newItem
                    changed = true
                }
            }
        }

        if (changed) {
            settingsRepository.setBudgetItems(updated)
        }
    }

    private data class PresetDef(
        val id: String,
        val name: String,
        val categoryNames: Set<String>,
    )
}
