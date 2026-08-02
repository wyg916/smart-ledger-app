package com.offline.ledger.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.offline.ledger.data.prefs.SettingsRepository
import com.offline.ledger.security.SecurePrefs
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

sealed interface PinSetupEvent {
    data object Done : PinSetupEvent
    data class Error(val message: String) : PinSetupEvent
}

data class PinSetupUiState(
    val step: Int = 1,
    val pinInput: String = "",
    val hint: String = "设置 6 位 PIN",
    val error: String? = null,
)

@HiltViewModel
class PinSetupViewModel @Inject constructor(
    private val securePrefs: SecurePrefs,
    private val settingsRepository: SettingsRepository,
) : ViewModel() {
    private val step = MutableStateFlow(1)
    private val firstPin = MutableStateFlow<String?>(null)
    private val pinInput = MutableStateFlow("")
    private val error = MutableStateFlow<String?>(null)

    val events: MutableSharedFlow<PinSetupEvent> = MutableSharedFlow(extraBufferCapacity = 4)

    val uiState: StateFlow<PinSetupUiState> = combine(step, pinInput, error) { s, pin, err ->
        PinSetupUiState(
            step = s,
            pinInput = pin,
            hint = if (s == 1) "设置 6 位 PIN" else "再次输入确认",
            error = err,
        )
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), PinSetupUiState())

    fun pressDigit(digit: Int) {
        if (digit !in 0..9) return
        if (pinInput.value.length >= 6) return
        error.value = null
        pinInput.value += digit.toString()
        if (pinInput.value.length == 6) {
            onPinComplete()
        }
    }

    fun backspace() {
        if (pinInput.value.isEmpty()) return
        pinInput.value = pinInput.value.dropLast(1)
    }

    fun clear() {
        pinInput.value = ""
        error.value = null
    }

    private fun onPinComplete() {
        val current = pinInput.value
        if (step.value == 1) {
            firstPin.value = current
            step.value = 2
            pinInput.value = ""
            return
        }

        val first = firstPin.value
        if (first == null) {
            resetWithError("请重新设置")
            return
        }

        if (current != first) {
            resetWithError("两次 PIN 不一致")
            return
        }

        viewModelScope.launch {
            try {
                securePrefs.setPin(current)
                settingsRepository.setAppLockEnabled(true)
                events.tryEmit(PinSetupEvent.Done)
            } catch (t: Throwable) {
                events.tryEmit(PinSetupEvent.Error(t.message ?: "设置失败"))
                resetWithError("设置失败")
            }
        }
    }

    private fun resetWithError(message: String) {
        step.value = 1
        firstPin.value = null
        pinInput.value = ""
        error.value = message
    }
}

