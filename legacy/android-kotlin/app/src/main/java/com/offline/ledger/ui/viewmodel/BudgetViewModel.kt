package com.offline.ledger.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.offline.ledger.data.prefs.SettingsRepository
import com.offline.ledger.utils.MoneyUtils
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

data class BudgetUiState(
    val currentBudgetCent: Long = 0,
    val input: String = "",
    val inputCent: Long = 0,
    val canSave: Boolean = false,
)

sealed interface BudgetEvent {
    data object Saved : BudgetEvent
    data class Error(val message: String) : BudgetEvent
}

@HiltViewModel
class BudgetViewModel @Inject constructor(
    private val settingsRepository: SettingsRepository,
) : ViewModel() {
    private val input = MutableStateFlow("")
    val events: MutableSharedFlow<BudgetEvent> = MutableSharedFlow(extraBufferCapacity = 8)

    private val currentBudget: StateFlow<Long> = settingsRepository.monthlyBudgetCentFlow
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), 0L)

    val uiState: StateFlow<BudgetUiState> = combine(currentBudget, input) { budgetCent, inStr ->
        val sanitized = MoneyUtils.sanitizeAmountInput(inStr)
        val cents = MoneyUtils.amountInputToCents(sanitized) ?: 0L
        BudgetUiState(
            currentBudgetCent = budgetCent,
            input = sanitized,
            inputCent = cents,
            canSave = cents >= 0L,
        )
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), BudgetUiState())

    fun setInput(value: String) {
        input.value = value
    }

    fun initIfEmpty() {
        if (input.value.isNotBlank()) return
        val current = currentBudget.value
        input.value = if (current == 0L) "" else MoneyUtils.formatCents(current)
    }

    fun save() {
        val cents = uiState.value.inputCent
        viewModelScope.launch {
            try {
                settingsRepository.setMonthlyBudgetCent(cents)
                events.tryEmit(BudgetEvent.Saved)
            } catch (t: Throwable) {
                events.tryEmit(BudgetEvent.Error(t.message ?: "保存失败"))
            }
        }
    }
}

