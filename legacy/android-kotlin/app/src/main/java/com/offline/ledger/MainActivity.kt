package com.offline.ledger

import android.os.Bundle
import androidx.activity.compose.setContent
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.ProcessLifecycleOwner
import androidx.lifecycle.lifecycleScope
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.fragment.app.FragmentActivity
import android.view.WindowManager
import com.offline.ledger.ui.theme.LedgerTheme
import com.offline.ledger.data.prefs.SettingsRepository
import com.offline.ledger.security.AppLockManager
import com.offline.ledger.ui.screens.LockScreen
import com.offline.ledger.ui.viewmodel.LockViewModel
import dagger.hilt.android.AndroidEntryPoint
import javax.inject.Inject
import kotlinx.coroutines.launch

@AndroidEntryPoint
class MainActivity : FragmentActivity() {
    @Inject lateinit var appLockManager: AppLockManager
    @Inject lateinit var settingsRepository: SettingsRepository

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        ProcessLifecycleOwner.get().lifecycle.addObserver(
            object : DefaultLifecycleObserver {
                override fun onStart(owner: LifecycleOwner) {
                    appLockManager.onAppForegrounded()
                }

                override fun onStop(owner: LifecycleOwner) {
                    appLockManager.onAppBackgrounded()
                }
            },
        )

        lifecycleScope.launch {
            settingsRepository.lockSettingsFlow.collect { settings ->
                if (settings.enabled) {
                    window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                } else {
                    window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                }
            }
        }

        setContent {
            LedgerTheme {
                Surface(color = MaterialTheme.colorScheme.background) {
                    val lockViewModel: LockViewModel = hiltViewModel()
                    val lockState by lockViewModel.uiState.collectAsState()
                    if (lockState.locked) {
                        LockScreen(viewModel = lockViewModel)
                    } else {
                        com.offline.ledger.ui.LedgerAppRoot()
                    }
                }
            }
        }
    }
}
