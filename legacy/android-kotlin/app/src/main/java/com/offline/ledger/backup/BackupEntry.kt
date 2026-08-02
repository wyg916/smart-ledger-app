package com.offline.ledger.backup

import android.net.Uri

data class BackupEntry(
    val uri: Uri,
    val displayName: String,
    val sizeBytes: Long,
    val modifiedAtMillis: Long,
    val isAuto: Boolean,
)

