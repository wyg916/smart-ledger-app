package com.offline.ledger.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.offline.ledger.data.db.model.MonthlySummaryRow
import com.offline.ledger.data.repo.StatsRepository
import com.offline.ledger.utils.DateTimeUtils
import dagger.hilt.android.lifecycle.HiltViewModel
import java.time.LocalDate
import javax.inject.Inject
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn

data class BillsMonthRowUi(
    val month: Int,
    val incomeCent: Long,
    val expenseCent: Long,
) {
    val balanceCent: Long = incomeCent - expenseCent
}

data class BillsUiState(
    val year: Int = LocalDate.now().year,
    val yearIncomeCent: Long = 0,
    val yearExpenseCent: Long = 0,
    val months: List<BillsMonthRowUi> = emptyList(),
) {
    val yearBalanceCent: Long = yearIncomeCent - yearExpenseCent
}

@HiltViewModel
class BillsViewModel @Inject constructor(
    private val statsRepository: StatsRepository,
) : ViewModel() {
    private val year = MutableStateFlow(LocalDate.now().year)

    private val monthlyRows: StateFlow<List<MonthlySummaryRow>> = year
        .map { y ->
            val start = DateTimeUtils.millisFromLocalDate(LocalDate.of(y, 1, 1))
            val end = DateTimeUtils.millisFromLocalDate(LocalDate.of(y + 1, 1, 1)) - 1
            start to end
        }
        .flatMapLatest { (start, end) -> statsRepository.observeMonthlySummary(start, end) }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), emptyList())

    val uiState: StateFlow<BillsUiState> = combine(year, monthlyRows) { y, rows ->
        val monthMap: Map<Int, MonthlySummaryRow> = rows.associateBy { it.month.substring(5, 7).toInt() }

        val now = LocalDate.now()
        val monthsRange = if (y == now.year) (now.monthValue downTo 1) else (12 downTo 1)

        val monthUis = monthsRange.map { m ->
            val r = monthMap[m]
            BillsMonthRowUi(
                month = m,
                incomeCent = r?.incomeCent ?: 0L,
                expenseCent = r?.expenseCent ?: 0L,
            )
        }

        BillsUiState(
            year = y,
            yearIncomeCent = monthUis.sumOf { it.incomeCent },
            yearExpenseCent = monthUis.sumOf { it.expenseCent },
            months = monthUis,
        )
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), BillsUiState())

    fun prevYear() {
        year.value = year.value - 1
    }

    fun nextYear() {
        year.value = year.value + 1
    }
}

