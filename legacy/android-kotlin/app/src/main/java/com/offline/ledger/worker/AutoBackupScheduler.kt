package com.offline.ledger.worker

import android.content.Context
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.ExistingWorkPolicy
import androidx.work.OneTimeWorkRequestBuilder
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import java.time.Duration
import java.time.ZonedDateTime
import java.util.concurrent.TimeUnit

object AutoBackupScheduler {
    private const val UNIQUE_DAILY: String = "auto_backup_daily"
    private const val UNIQUE_NOW: String = "auto_backup_now"
    private const val TARGET_HOUR: Int = 3

    fun scheduleDaily(context: Context, policy: ExistingPeriodicWorkPolicy) {
        val request = PeriodicWorkRequestBuilder<AutoBackupWorker>(1, TimeUnit.DAYS)
            .setInitialDelay(initialDelayMillis(), TimeUnit.MILLISECONDS)
            .build()
        WorkManager.getInstance(context).enqueueUniquePeriodicWork(
            UNIQUE_DAILY,
            policy,
            request,
        )
    }

    fun enqueueNow(context: Context) {
        val request = OneTimeWorkRequestBuilder<AutoBackupWorker>().build()
        WorkManager.getInstance(context).enqueueUniqueWork(
            UNIQUE_NOW,
            ExistingWorkPolicy.REPLACE,
            request,
        )
    }

    fun cancelDaily(context: Context) {
        WorkManager.getInstance(context).cancelUniqueWork(UNIQUE_DAILY)
    }

    private fun initialDelayMillis(now: ZonedDateTime = ZonedDateTime.now()): Long {
        val next = now.withHour(TARGET_HOUR).withMinute(0).withSecond(0).withNano(0).let { t ->
            if (t.isAfter(now)) t else t.plusDays(1)
        }
        return Duration.between(now, next).toMillis().coerceAtLeast(0L)
    }
}

