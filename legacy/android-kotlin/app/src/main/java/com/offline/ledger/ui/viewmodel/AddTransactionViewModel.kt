package com.offline.ledger.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import androidx.lifecycle.SavedStateHandle
import com.offline.ledger.data.db.entity.CategoryEntity
import com.offline.ledger.data.db.entity.TransactionEntity
import com.offline.ledger.data.repo.CategoryRepository
import com.offline.ledger.data.repo.TransactionRepository
import com.offline.ledger.model.TransactionType
import com.offline.ledger.utils.DateTimeUtils
import com.offline.ledger.utils.MoneyUtils
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

data class AddTransactionUiState(
    val type: Int = TransactionType.Expense,
    val categories: List<CategoryEntity> = emptyList(),
    val selectedCategoryId: Long? = null,
    val editingId: Long? = null,
    val amountInput: String = "",
    val amountCent: Long = 0,
    val note: String = "",
    val occurredAt: Long = DateTimeUtils.nowMillis(),
    val canSubmit: Boolean = false,
    val isSaving: Boolean = false,
)

sealed interface AddTransactionEvent {
    data object Saved : AddTransactionEvent
    data object Deleted : AddTransactionEvent
    data class Error(val message: String) : AddTransactionEvent
}

@HiltViewModel
class AddTransactionViewModel @Inject constructor(
    private val transactionRepository: TransactionRepository,
    private val categoryRepository: CategoryRepository,
    savedStateHandle: SavedStateHandle,
) : ViewModel() {
    private val type = MutableStateFlow(TransactionType.Expense)
    private val selectedCategoryId = MutableStateFlow<Long?>(null)
    private val amountInput = MutableStateFlow("")
    private val note = MutableStateFlow("")
    private val occurredAt = MutableStateFlow(DateTimeUtils.nowMillis())
    private val isSaving = MutableStateFlow(false)
    private val editingId = MutableStateFlow<Long?>(null)
    private val originalTx = MutableStateFlow<TransactionEntity?>(null)

    private val categories: StateFlow<List<CategoryEntity>> = type
        .flatMapLatest { categoryRepository.observeCategories(it) }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    val events: MutableSharedFlow<AddTransactionEvent> = MutableSharedFlow(extraBufferCapacity = 8)

    private data class CategorySelectionState(
        val type: Int,
        val categories: List<CategoryEntity>,
        val selectedCategoryId: Long?,
    )

    private val categorySelection: StateFlow<CategorySelectionState> = combine(
        type,
        categories,
        selectedCategoryId,
    ) { t, cats, selectedId ->
        CategorySelectionState(type = t, categories = cats, selectedCategoryId = selectedId)
    }.stateIn(
        viewModelScope,
        SharingStarted.WhileSubscribed(5_000),
        CategorySelectionState(TransactionType.Expense, emptyList(), null),
    )

    private data class SelectionEditState(
        val selection: CategorySelectionState,
        val editingId: Long?,
    )

    private val selectionEditState: StateFlow<SelectionEditState> = combine(
        categorySelection,
        editingId,
    ) { sel, id ->
        SelectionEditState(selection = sel, editingId = id)
    }.stateIn(
        viewModelScope,
        SharingStarted.WhileSubscribed(5_000),
        SelectionEditState(categorySelection.value, null),
    )

    val uiState: StateFlow<AddTransactionUiState> = combine(
        selectionEditState,
        amountInput,
        note,
        occurredAt,
        isSaving,
    ) { selEdit, amountStr, n, time, saving ->
        val normalizedAmount = MoneyUtils.sanitizeAmountInput(amountStr)
        val cents = MoneyUtils.amountInputToCents(normalizedAmount) ?: 0L

        val sel = selEdit.selection
        val selectedExists = sel.selectedCategoryId != null && sel.categories.any { it.id == sel.selectedCategoryId }
        val resolvedSelectedId = when {
            sel.categories.isEmpty() -> null
            selectedExists -> sel.selectedCategoryId
            else -> sel.categories.first().id
        }

        AddTransactionUiState(
            type = sel.type,
            categories = sel.categories,
            selectedCategoryId = resolvedSelectedId,
            editingId = selEdit.editingId,
            amountInput = normalizedAmount,
            amountCent = cents,
            note = n,
            occurredAt = time,
            canSubmit = cents > 0 && resolvedSelectedId != null && !saving,
            isSaving = saving,
        )
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), AddTransactionUiState())

    init {
        val idStr = savedStateHandle.get<String>("txId")
        val id = idStr?.toLongOrNull()
        if (id != null) {
            viewModelScope.launch {
                val tx = transactionRepository.getById(id) ?: return@launch
                originalTx.value = tx
                editingId.value = tx.id
                type.value = tx.type
                selectedCategoryId.value = tx.categoryId
                amountInput.value = MoneyUtils.formatCents(tx.amountCent)
                note.value = tx.note
                occurredAt.value = tx.occurredAt
            }
        }
    }

    fun setType(newType: Int) {
        if (newType != TransactionType.Expense && newType != TransactionType.Income) return
        type.value = newType
    }

    fun selectCategory(id: Long) {
        selectedCategoryId.value = id
    }

    fun setNote(value: String) {
        note.value = value
    }

    fun setOccurredAt(millis: Long) {
        occurredAt.value = millis
    }

    fun pressDigit(digit: Int) {
        if (digit !in 0..9) return
        val current = amountInput.value
        amountInput.value = appendAmountChar(current, ('0'.code + digit).toChar())
    }

    fun pressDot() {
        val current = amountInput.value
        if (current.contains('.')) return
        amountInput.value = if (current.isBlank()) "0." else "$current."
    }

    fun backspace() {
        val current = amountInput.value
        amountInput.value = if (current.isNotEmpty()) current.dropLast(1) else ""
    }

    fun clearAmount() {
        amountInput.value = ""
    }

    fun submit() {
        val state = uiState.value
        val categoryId = state.selectedCategoryId ?: return
        if (state.amountCent <= 0L) return
        if (isSaving.value) return

        viewModelScope.launch {
            isSaving.value = true
            try {
                val editId = state.editingId
                if (editId == null) {
                    transactionRepository.addTransaction(
                        type = state.type,
                        amountCent = state.amountCent,
                        categoryId = categoryId,
                        occurredAt = state.occurredAt,
                        note = state.note.trim(),
                    )
                } else {
                    val base = originalTx.value ?: transactionRepository.getById(editId) ?: error("记录不存在")
                    transactionRepository.updateTransaction(
                        base.copy(
                            type = state.type,
                            amountCent = state.amountCent,
                            categoryId = categoryId,
                            occurredAt = state.occurredAt,
                            note = state.note.trim(),
                        ),
                    )
                }
                amountInput.value = ""
                note.value = ""
                events.tryEmit(AddTransactionEvent.Saved)
            } catch (t: Throwable) {
                events.tryEmit(AddTransactionEvent.Error(t.message ?: "保存失败"))
            } finally {
                isSaving.value = false
            }
        }
    }

    fun deleteEditing() {
        val id = editingId.value ?: return
        if (isSaving.value) return
        viewModelScope.launch {
            isSaving.value = true
            try {
                transactionRepository.deleteTransaction(id)
                events.tryEmit(AddTransactionEvent.Deleted)
            } catch (t: Throwable) {
                events.tryEmit(AddTransactionEvent.Error(t.message ?: "删除失败"))
            } finally {
                isSaving.value = false
            }
        }
    }

    private fun appendAmountChar(current: String, char: Char): String {
        val sanitized = MoneyUtils.sanitizeAmountInput(current)
        if (sanitized.length >= 16) return sanitized

        if (sanitized.contains('.')) {
            val fraction = sanitized.substringAfter('.', "")
            if (fraction.length >= 2) return sanitized
        }

        val next = sanitized + char
        return MoneyUtils.sanitizeAmountInput(next)
    }
}
