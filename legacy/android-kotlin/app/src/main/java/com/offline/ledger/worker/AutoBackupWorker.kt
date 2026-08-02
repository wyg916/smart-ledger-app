package com.offline.ledger.worker

import android.content.Context
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import com.offline.ledger.backup.BackupManager
import com.offline.ledger.data.prefs.SettingsRepository
import com.offline.ledger.security.SecurePrefs
import kotlinx.coroutines.flow.first

class AutoBackupWorker(
    appContext: Context,
    params: WorkerParameters,
) : CoroutineWorker(appContext, params) {
    override suspend fun doWork(): Result {
        val settings = SettingsRepository(applicationContext)
        val enabled = settings.autoBackupEnabledFlow.first()
        if (!enabled) return Result.success()

        val securePrefs = SecurePrefs(applicationContext)
        if (!securePrefs.hasBackupPasswordConfigured()) return Result.success()

        return try {
            BackupManager(applicationContext, securePrefs).createBackup(isAuto = true)
            Result.success()
        } catch (t: Throwable) {
            Result.retry()
        }
    }
}

