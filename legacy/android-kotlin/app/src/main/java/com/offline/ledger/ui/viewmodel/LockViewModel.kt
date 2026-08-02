package com.offline.ledger.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.offline.ledger.data.prefs.LockSettings
import com.offline.ledger.data.prefs.SettingsRepository
import com.offline.ledger.security.AppLockManager
import com.offline.ledger.security.SecurePrefs
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

data class LockUiState(
    val locked: Boolean = false,
    val pinInput: String = "",
    val error: String? = null,
    val lockSettings: LockSettings = LockSettings(enabled = false, timeoutMinutes = 1, biometricEnabled = true),
    val hasPin: Boolean = false,
)

@HiltViewModel
class LockViewModel @Inject constructor(
    private val appLockManager: AppLockManager,
    private val settingsRepository: SettingsRepository,
    private val securePrefs: SecurePrefs,
) : ViewModel() {
    private val pinInput = MutableStateFlow("")
    private val error = MutableStateFlow<String?>(null)
    private val hasPin = MutableStateFlow(securePrefs.hasPin())

    private val lockSettings: StateFlow<LockSettings> =
        settingsRepository.lockSettingsFlow.stateIn(
            viewModelScope,
            SharingStarted.WhileSubscribed(5_000),
            LockSettings(enabled = false, timeoutMinutes = 1, biometricEnabled = true),
        )

    val uiState: StateFlow<LockUiState> = combine(
        appLockManager.locked,
        pinInput,
        error,
        lockSettings,
        hasPin,
    ) { locked, pin, err, settings, pinSet ->
        LockUiState(
            locked = locked,
            pinInput = pin,
            error = err,
            lockSettings = settings,
            hasPin = pinSet,
        )
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), LockUiState())

    fun refreshPinState() {
        hasPin.value = securePrefs.hasPin()
    }

    fun pressDigit(digit: Int) {
        if (digit !in 0..9) return
        if (pinInput.value.length >= 6) return
        error.value = null
        pinInput.value += digit.toString()
        if (pinInput.value.length == 6) {
            verifyAndUnlock()
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

    fun unlockFromBiometric() {
        clear()
        appLockManager.unlock()
    }

    private fun verifyAndUnlock() {
        val pin = pinInput.value
        viewModelScope.launch(Dispatchers.Default) {
            val ok = securePrefs.verifyPin(pin)
            if (ok) {
                clear()
                appLockManager.unlock()
            } else {
                pinInput.value = ""
                error.value = "PIN错误"
            }
        }
    }
}

