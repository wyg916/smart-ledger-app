package com.offline.ledger.ui.viewmodel

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.offline.ledger.data.db.entity.CategoryEntity
import com.offline.ledger.data.prefs.BudgetItem
import com.offline.ledger.data.prefs.SettingsRepository
import com.offline.ledger.data.repo.CategoryRepository
import com.offline.ledger.model.TransactionType
import dagger.hilt.android.lifecycle.HiltViewModel
import java.util.UUID
import javax.inject.Inject
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

data class BudgetItemsUiState(
    val items: List<BudgetItem> = emptyList(),
    val expenseCategories: List<CategoryEntity> = emptyList(),
    val openItemId: String? = null,
)

sealed interface BudgetItemsEvent {
    data class Toast(val message: String) : BudgetItemsEvent
}

@HiltViewModel
class BudgetItemsViewModel @Inject constructor(
    private val settingsRepository: SettingsRepository,
    private val categoryRepository: CategoryRepository,
    savedStateHandle: SavedStateHandle,
) : ViewModel() {
    private val openItemId = MutableStateFlow(savedStateHandle.get<String>("itemId"))

    val events: MutableSharedFlow<BudgetItemsEvent> = MutableSharedFlow(extraBufferCapacity = 8)

    private val categoriesFlow = categoryRepository.observeCategories(TransactionType.Expense)

    val uiState: StateFlow<BudgetItemsUiState> = combine(
        settingsRepository.budgetItemsFlow,
        categoriesFlow,
        openItemId,
    ) { items, categories, openId ->
        BudgetItemsUiState(
            items = items,
            expenseCategories = categories,
            openItemId = openId,
        )
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), BudgetItemsUiState())

    init {
        viewModelScope.launch {
            ensurePresetItems()
        }
    }

    fun consumeOpenItem() {
        openItemId.value = null
    }

    fun addItem(
        name: String,
        budgetCent: Long,
        categoryIds: List<Long>,
    ) {
        val trimmed = name.trim()
        if (trimmed.isBlank()) {
            events.tryEmit(BudgetItemsEvent.Toast("请输入名称"))
            return
        }
        val item = BudgetItem(
            id = UUID.randomUUID().toString(),
            name = trimmed,
            budgetCent = budgetCent.coerceAtLeast(0L),
            categoryIds = categoryIds.distinct(),
            preset = false,
        )
        viewModelScope.launch {
            settingsRepository.upsertBudgetItem(item)
        }
    }

    fun updateItem(
        id: String,
        name: String,
        budgetCent: Long,
        categoryIds: List<Long>,
        preset: Boolean,
    ) {
        val trimmed = name.trim()
        if (trimmed.isBlank()) {
            events.tryEmit(BudgetItemsEvent.Toast("请输入名称"))
            return
        }
        val item = BudgetItem(
            id = id,
            name = trimmed,
            budgetCent = budgetCent.coerceAtLeast(0L),
            categoryIds = categoryIds.distinct(),
            preset = preset,
        )
        viewModelScope.launch {
            settingsRepository.upsertBudgetItem(item)
        }
    }

    fun deleteItem(id: String) {
        val existing = uiState.value.items.firstOrNull { it.id == id } ?: return
        if (existing.preset) return
        viewModelScope.launch {
            settingsRepository.deleteBudgetItem(id)
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

