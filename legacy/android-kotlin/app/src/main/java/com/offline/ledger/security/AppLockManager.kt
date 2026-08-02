package com.offline.ledger.security

import com.offline.ledger.data.prefs.SettingsRepository
import javax.inject.Inject
import javax.inject.Singleton
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

@Singleton
class AppLockManager @Inject constructor(
    settingsRepository: SettingsRepository,
    private val securePrefs: SecurePrefs,
) {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)

    private val _locked = MutableStateFlow(false)
    val locked: StateFlow<Boolean> = _locked.asStateFlow()

    @Volatile
    private var lockEnabled: Boolean = false

    @Volatile
    private var timeoutMillis: Long = 60_000L

    @Volatile
    private var initialized: Boolean = false

    @Volatile
    private var lastBackgroundAt: Long? = null

    init {
        scope.launch {
            settingsRepository.lockSettingsFlow.collect { settings ->
                val previousEnabled = lockEnabled
                lockEnabled = settings.enabled
                timeoutMillis = settings.timeoutMinutes.coerceAtLeast(0).toLong() * 60_000L

                if (!lockEnabled) {
                    _locked.value = false
                } else if (!initialized) {
                    // App cold start: require unlock when enabled.
                    _locked.value = securePrefs.hasPin()
                } else if (!previousEnabled && lockEnabled) {
                    // Enabled at runtime: don't force lock immediately.
                }

                initialized = true
            }
        }
    }

    fun onAppBackgrounded() {
        lastBackgroundAt = System.currentTimeMillis()
        if (lockEnabled && timeoutMillis == 0L && securePrefs.hasPin()) {
            _locked.value = true
        }
    }

    fun onAppForegrounded() {
        if (!lockEnabled) return
        if (!securePrefs.hasPin()) return
        val last = lastBackgroundAt ?: return
        val elapsed = System.currentTimeMillis() - last
        if (elapsed >= timeoutMillis) {
            _locked.value = true
        }
    }

    fun lockNow() {
        if (lockEnabled && securePrefs.hasPin()) _locked.value = true
    }

    fun unlock() {
        _locked.value = false
        lastBackgroundAt = null
    }
}
