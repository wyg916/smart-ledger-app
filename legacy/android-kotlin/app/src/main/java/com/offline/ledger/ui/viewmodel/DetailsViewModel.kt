package com.offline.ledger.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.offline.ledger.data.db.entity.CategoryEntity
import com.offline.ledger.data.db.entity.TransactionEntity
import com.offline.ledger.data.repo.CategoryRepository
import com.offline.ledger.data.repo.TransactionFilter
import com.offline.ledger.data.repo.TransactionRepository
import com.offline.ledger.model.TransactionType
import com.offline.ledger.utils.DateTimeUtils
import dagger.hilt.android.lifecycle.HiltViewModel
import java.time.LocalDate
import java.time.YearMonth
import javax.inject.Inject
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

data class DetailsTransactionUi(
    val id: Long,
    val type: Int,
    val amountCent: Long,
    val categoryName: String,
    val iconCode: String,
    val note: String,
    val occurredAt: Long,
)

data class DetailsDayGroupUi(
    val day: LocalDate,
    val expenseTotalCent: Long,
    val incomeTotalCent: Long,
    val items: List<DetailsTransactionUi>,
)

data class DetailsUiState(
    val yearMonth: YearMonth = YearMonth.now(),
    val filterType: Int? = null,
    val filterKeyword: String = "",
    val filterCategoryId: Long? = null,
    val expenseTotalCent: Long = 0,
    val incomeTotalCent: Long = 0,
    val dayGroups: List<DetailsDayGroupUi> = emptyList(),
    val allCategories: List<CategoryEntity> = emptyList(),
)

@HiltViewModel
class DetailsViewModel @Inject constructor(
    private val transactionRepository: TransactionRepository,
    private val categoryRepository: CategoryRepository,
) : ViewModel() {
    private val yearMonth = MutableStateFlow(YearMonth.now())
    private val filterType = MutableStateFlow<Int?>(null)
    private val filterKeyword = MutableStateFlow("")
    private val filterCategoryId = MutableStateFlow<Long?>(null)

    private val categoriesMap: StateFlow<Map<Long, CategoryEntity>> =
        categoryRepository.observeAllCategories()
            .map { list -> list.associateBy { it.id } }
            .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyMap())

    private val allCategories: StateFlow<List<CategoryEntity>> =
        categoryRepository.observeAllCategories()
            .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    private data class FilterUi(
        val yearMonth: YearMonth,
        val type: Int?,
        val keyword: String,
        val categoryId: Long?,
    )

    private data class BaseFilterUi(
        val yearMonth: YearMonth,
        val keyword: String,
        val categoryId: Long?,
    )

    private val filterUi: StateFlow<FilterUi> = combine(
        yearMonth,
        filterType,
        filterKeyword,
        filterCategoryId,
    ) { ym, type, keyword, categoryId ->
        FilterUi(
            yearMonth = ym,
            type = type,
            keyword = keyword,
            categoryId = categoryId,
        )
    }.stateIn(
        viewModelScope,
        SharingStarted.WhileSubscribed(5_000),
        FilterUi(YearMonth.now(), null, "", null),
    )

    private val baseFilterUi: StateFlow<BaseFilterUi> = combine(
        yearMonth,
        filterKeyword,
        filterCategoryId,
    ) { ym, keyword, categoryId ->
        BaseFilterUi(
            yearMonth = ym,
            keyword = keyword,
            categoryId = categoryId,
        )
    }.stateIn(
        viewModelScope,
        SharingStarted.WhileSubscribed(5_000),
        BaseFilterUi(YearMonth.now(), "", null),
    )

    private val transactions: StateFlow<List<TransactionEntity>> = filterUi
        .map { f ->
            val start = DateTimeUtils.startOfMonthMillis(f.yearMonth)
            val end = DateTimeUtils.endOfMonthMillis(f.yearMonth)
            TransactionFilter(
                startInclusive = start,
                endInclusive = end,
                type = f.type,
                categoryId = f.categoryId,
                keyword = f.keyword,
            )
        }
        .map { filter -> transactionRepository.observeTransactions(filter) }
        .flatMapLatest { it }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    private val transactionsAllTypes: StateFlow<List<TransactionEntity>> = baseFilterUi
        .map { f ->
            val start = DateTimeUtils.startOfMonthMillis(f.yearMonth)
            val end = DateTimeUtils.endOfMonthMillis(f.yearMonth)
            TransactionFilter(
                startInclusive = start,
                endInclusive = end,
                type = null,
                categoryId = f.categoryId,
                keyword = f.keyword,
            )
        }
        .map { filter -> transactionRepository.observeTransactions(filter) }
        .flatMapLatest { it }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    private val totals: StateFlow<Pair<Long, Long>> = transactionsAllTypes
        .map { txs ->
            val expense = txs.filter { it.type == TransactionType.Expense }.sumOf { it.amountCent }
            val income = txs.filter { it.type == TransactionType.Income }.sumOf { it.amountCent }
            expense to income
        }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), 0L to 0L)

    private val dayGroups: StateFlow<List<DetailsDayGroupUi>> = combine(
        transactions,
        categoriesMap,
    ) { txs, catMap ->
        val groups = txs
            .groupBy { DateTimeUtils.localDateFromMillis(it.occurredAt) }
            .toSortedMap(compareByDescending { it })
            .map { (day, list) ->
                val sorted = list.sortedWith(
                    compareByDescending<TransactionEntity> { it.occurredAt }
                        .thenByDescending { it.id },
                )
                val expense = sorted.filter { it.type == TransactionType.Expense }.sumOf { it.amountCent }
                val income = sorted.filter { it.type == TransactionType.Income }.sumOf { it.amountCent }
                DetailsDayGroupUi(
                    day = day,
                    expenseTotalCent = expense,
                    incomeTotalCent = income,
                    items = sorted.map { tx ->
                        val cat = catMap[tx.categoryId]
                        DetailsTransactionUi(
                            id = tx.id,
                            type = tx.type,
                            amountCent = tx.amountCent,
                            categoryName = cat?.name ?: "未知分类",
                            iconCode = cat?.iconCode ?: "other",
                            note = tx.note,
                            occurredAt = tx.occurredAt,
                        )
                    },
                )
            }
        groups
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    val uiState: StateFlow<DetailsUiState> = combine(
        filterUi,
        totals,
        dayGroups,
        allCategories,
    ) { f, totalsPair, groups, categories ->
        DetailsUiState(
            yearMonth = f.yearMonth,
            filterType = f.type,
            filterKeyword = f.keyword,
            filterCategoryId = f.categoryId,
            expenseTotalCent = totalsPair.first,
            incomeTotalCent = totalsPair.second,
            dayGroups = groups,
            allCategories = categories,
        )
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), DetailsUiState())

    fun prevMonth() {
        yearMonth.value = yearMonth.value.minusMonths(1)
    }

    fun nextMonth() {
        yearMonth.value = yearMonth.value.plusMonths(1)
    }

    fun setFilterType(type: Int?) {
        if (type != null && type != TransactionType.Expense && type != TransactionType.Income) return
        filterType.value = type
    }

    fun setKeyword(keyword: String) {
        filterKeyword.value = keyword
    }

    fun setCategoryId(categoryId: Long?) {
        filterCategoryId.value = categoryId
    }

    fun deleteTransaction(id: Long) {
        viewModelScope.launch {
            transactionRepository.deleteTransaction(id)
        }
    }
}
