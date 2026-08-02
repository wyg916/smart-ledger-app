package com.offline.ledger.utils

import android.content.Context
import android.content.Intent
import android.os.Process

object AppRestart {
    fun restart(context: Context) {
        val pm = context.packageManager
        val intent = pm.getLaunchIntentForPackage(context.packageName) ?: return
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
        context.startActivity(intent)
        Process.killProcess(Process.myPid())
    }
}

