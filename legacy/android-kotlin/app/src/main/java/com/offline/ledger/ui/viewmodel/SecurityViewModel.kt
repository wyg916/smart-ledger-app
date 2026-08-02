package com.offline.ledger.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.offline.ledger.data.prefs.LockSettings
import com.offline.ledger.data.prefs.SettingsRepository
import com.offline.ledger.security.AppLockManager
import com.offline.ledger.security.SecurePrefs
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

data class SecurityUiState(
    val lockSettings: LockSettings = LockSettings(enabled = false, timeoutMinutes = 1, biometricEnabled = true),
    val hasPin: Boolean = false,
)

@HiltViewModel
class SecurityViewModel @Inject constructor(
    private val settingsRepository: SettingsRepository,
    private val securePrefs: SecurePrefs,
    private val appLockManager: AppLockManager,
) : ViewModel() {
    private val hasPin = MutableStateFlow(securePrefs.hasPin())

    private val lockSettings: StateFlow<LockSettings> =
        settingsRepository.lockSettingsFlow.stateIn(
            viewModelScope,
            SharingStarted.WhileSubscribed(5_000),
            LockSettings(enabled = false, timeoutMinutes = 1, biometricEnabled = true),
        )

    val uiState: StateFlow<SecurityUiState> = combine(lockSettings, hasPin) { settings, pinSet ->
        SecurityUiState(lockSettings = settings, hasPin = pinSet)
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), SecurityUiState())

    fun refreshPinState() {
        hasPin.value = securePrefs.hasPin()
    }

    fun setLockEnabled(enabled: Boolean) {
        viewModelScope.launch { settingsRepository.setAppLockEnabled(enabled) }
    }

    fun setBiometricEnabled(enabled: Boolean) {
        viewModelScope.launch { settingsRepository.setAppLockBiometricEnabled(enabled) }
    }

    fun setTimeoutMinutes(minutes: Int) {
        viewModelScope.launch { settingsRepository.setAppLockTimeoutMinutes(minutes) }
    }

    fun lockNow() {
        appLockManager.lockNow()
    }

    fun clearPinAndDisableLock() {
        securePrefs.clearPin()
        refreshPinState()
        viewModelScope.launch { settingsRepository.setAppLockEnabled(false) }
        appLockManager.unlock()
    }
}

