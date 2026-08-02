package com.offline.ledger.ui.viewmodel

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.offline.ledger.data.repo.CategoryRepository
import com.offline.ledger.data.repo.TransactionRepository
import com.offline.ledger.model.TransactionType
import com.offline.ledger.utils.DateTimeUtils
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

data class TransactionDetailUiState(
    val txId: Long? = null,
    val loading: Boolean = true,
    val exists: Boolean = true,
    val type: Int = TransactionType.Expense,
    val amountCent: Long = 0,
    val categoryName: String = "",
    val iconCode: String = "other",
    val note: String = "",
    val occurredAt: Long = DateTimeUtils.nowMillis(),
)

sealed interface TransactionDetailEvent {
    data object Deleted : TransactionDetailEvent
    data class Error(val message: String) : TransactionDetailEvent
}

@HiltViewModel
class TransactionDetailViewModel @Inject constructor(
    private val transactionRepository: TransactionRepository,
    private val categoryRepository: CategoryRepository,
    savedStateHandle: SavedStateHandle,
) : ViewModel() {
    private val txId: Long? = savedStateHandle.get<String>("txId")?.toLongOrNull()

    private val _uiState = MutableStateFlow(TransactionDetailUiState(txId = txId))
    val uiState: StateFlow<TransactionDetailUiState> = _uiState.asStateFlow()

    val events: MutableSharedFlow<TransactionDetailEvent> = MutableSharedFlow(extraBufferCapacity = 8)

    init {
        refresh()
    }

    fun refresh() {
        val id = txId
        if (id == null) {
            _uiState.value = _uiState.value.copy(loading = false, exists = false)
            return
        }

        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(loading = true)
            try {
                val tx = transactionRepository.getById(id)
                if (tx == null) {
                    _uiState.value = _uiState.value.copy(loading = false, exists = false)
                    return@launch
                }
                val category = categoryRepository.getAllCategories().firstOrNull { it.id == tx.categoryId }
                _uiState.value = TransactionDetailUiState(
                    txId = tx.id,
                    loading = false,
                    exists = true,
                    type = tx.type,
                    amountCent = tx.amountCent,
                    categoryName = category?.name ?: "未知分类",
                    iconCode = category?.iconCode ?: "other",
                    note = tx.note,
                    occurredAt = tx.occurredAt,
                )
            } catch (t: Throwable) {
                _uiState.value = _uiState.value.copy(loading = false)
                events.tryEmit(TransactionDetailEvent.Error(t.message ?: "加载失败"))
            }
        }
    }

    fun delete() {
        val id = txId ?: return
        viewModelScope.launch {
            try {
                transactionRepository.deleteTransaction(id)
                events.tryEmit(TransactionDetailEvent.Deleted)
            } catch (t: Throwable) {
                events.tryEmit(TransactionDetailEvent.Error(t.message ?: "删除失败"))
            }
        }
    }
}

