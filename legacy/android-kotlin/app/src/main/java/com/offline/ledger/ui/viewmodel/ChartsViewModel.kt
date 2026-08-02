package com.offline.ledger.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.offline.ledger.data.db.model.CategorySummaryRow
import com.offline.ledger.data.db.model.DailySummaryRow
import com.offline.ledger.data.repo.StatsRepository
import com.offline.ledger.model.TransactionType
import com.offline.ledger.utils.DateTimeUtils
import dagger.hilt.android.lifecycle.HiltViewModel
import java.time.YearMonth
import javax.inject.Inject
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

enum class ChartsRange { Week, Month, Year }

data class ChartsUiState(
    val type: Int = TransactionType.Expense,
    val range: ChartsRange = ChartsRange.Month,
    val totalCent: Long = 0,
    val daily: List<DailySummaryRow> = emptyList(),
    val categories: List<CategorySummaryRow> = emptyList(),
)

@HiltViewModel
class ChartsViewModel @Inject constructor(
    private val statsRepository: StatsRepository,
) : ViewModel() {
    private val type = MutableStateFlow(TransactionType.Expense)
    private val range = MutableStateFlow(ChartsRange.Month)
    private val total = MutableStateFlow(0L)
    private val categories = MutableStateFlow<List<CategorySummaryRow>>(emptyList())

    private val rangeMillis: StateFlow<Pair<Long, Long>> = combine(type, range) { _, r ->
        val now = System.currentTimeMillis()
        val today = DateTimeUtils.localDateFromMillis(now)
        when (r) {
            ChartsRange.Week -> {
                val start = DateTimeUtils.millisFromLocalDate(today.minusDays(6))
                val end = DateTimeUtils.millisFromLocalDate(today.plusDays(1)) - 1
                start to end
            }

            ChartsRange.Month -> {
                val ym = YearMonth.from(today)
                DateTimeUtils.startOfMonthMillis(ym) to DateTimeUtils.endOfMonthMillis(ym)
            }

            ChartsRange.Year -> {
                val start = DateTimeUtils.millisFromLocalDate(today.withDayOfYear(1))
                val end = DateTimeUtils.millisFromLocalDate(today.withDayOfYear(1).plusYears(1)) - 1
                start to end
            }
        }
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), 0L to 0L)

    private val daily: StateFlow<List<DailySummaryRow>> = rangeMillis
        .flatMapLatest { (start, end) -> statsRepository.observeDailySummary(start, end) }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    val uiState: StateFlow<ChartsUiState> = combine(type, range, total, daily, categories) { t, r, tot, d, cats ->
        ChartsUiState(
            type = t,
            range = r,
            totalCent = tot,
            daily = d,
            categories = cats,
        )
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), ChartsUiState())

    init {
        viewModelScope.launch {
            combine(type, rangeMillis) { t, (start, end) -> Triple(t, start, end) }
                .collect { (t, start, end) ->
                    total.value = statsRepository.getTotalForType(t, start, end)
                    categories.value = statsRepository.getCategorySummary(t, start, end).take(10)
                }
        }
    }

    fun setType(newType: Int) {
        if (newType != TransactionType.Expense && newType != TransactionType.Income) return
        type.value = newType
    }

    fun setRange(newRange: ChartsRange) {
        range.value = newRange
    }
}
