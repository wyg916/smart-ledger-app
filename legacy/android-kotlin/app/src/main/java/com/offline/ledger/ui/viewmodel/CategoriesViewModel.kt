package com.offline.ledger.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.offline.ledger.data.db.entity.CategoryEntity
import com.offline.ledger.data.repo.CategoryRepository
import com.offline.ledger.model.TransactionType
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

data class CategoriesUiState(
    val type: Int = TransactionType.Expense,
    val categories: List<CategoryEntity> = emptyList(),
)

sealed interface CategoriesEvent {
    data class Toast(val message: String) : CategoriesEvent
}

@HiltViewModel
class CategoriesViewModel @Inject constructor(
    private val categoryRepository: CategoryRepository,
) : ViewModel() {
    private val type = MutableStateFlow(TransactionType.Expense)

    private val categories: StateFlow<List<CategoryEntity>> = type
        .flatMapLatest { categoryRepository.observeCategories(it) }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    val events: MutableSharedFlow<CategoriesEvent> = MutableSharedFlow(extraBufferCapacity = 8)

    val uiState: StateFlow<CategoriesUiState> = combine(type, categories) { t, cats ->
        CategoriesUiState(type = t, categories = cats)
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), CategoriesUiState())

    fun setType(newType: Int) {
        if (newType != TransactionType.Expense && newType != TransactionType.Income) return
        type.value = newType
    }

    fun addCategory(name: String, iconCode: String) {
        val t = type.value
        val sortOrder = uiState.value.categories.size
        viewModelScope.launch {
            try {
                categoryRepository.addCategory(type = t, name = name.trim(), iconCode = iconCode, sortOrder = sortOrder)
                events.tryEmit(CategoriesEvent.Toast("已新增"))
            } catch (e: Throwable) {
                events.tryEmit(CategoriesEvent.Toast(e.message ?: "新增失败"))
            }
        }
    }

    fun updateCategory(category: CategoryEntity) {
        viewModelScope.launch {
            try {
                categoryRepository.updateCategory(category)
                events.tryEmit(CategoriesEvent.Toast("已保存"))
            } catch (e: Throwable) {
                events.tryEmit(CategoriesEvent.Toast(e.message ?: "保存失败"))
            }
        }
    }

    fun deleteCategory(category: CategoryEntity) {
        viewModelScope.launch {
            categoryRepository.deleteCategory(category)
        }
    }

    fun reorder(categoriesInOrder: List<CategoryEntity>) {
        viewModelScope.launch {
            categoryRepository.reorderCategories(categoriesInOrder)
        }
    }
}

