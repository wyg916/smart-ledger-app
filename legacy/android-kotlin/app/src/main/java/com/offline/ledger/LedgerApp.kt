package com.offline.ledger

import android.app.Application
import androidx.work.ExistingPeriodicWorkPolicy
import com.offline.ledger.backup.BackupManager
import com.offline.ledger.data.prefs.SettingsRepository
import com.offline.ledger.security.SecurePrefs
import com.offline.ledger.worker.AutoBackupScheduler
import dagger.hilt.android.HiltAndroidApp
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch

@HiltAndroidApp
class LedgerApp : Application() {
    override fun onCreate() {
        super.onCreate()

        val appContext = applicationContext
        CoroutineScope(SupervisorJob() + Dispatchers.Default).launch {
            val enabled = SettingsRepository(appContext).autoBackupEnabledFlow.first()
            if (enabled) {
                AutoBackupScheduler.scheduleDaily(appContext, ExistingPeriodicWorkPolicy.KEEP)
            } else {
                AutoBackupScheduler.cancelDaily(appContext)
            }

            runCatching {
                val securePrefs = SecurePrefs(appContext)
                BackupManager(appContext, securePrefs).migrateLegacyBackupsToMediaStoreIfPossible()
            }
        }
    }
}
