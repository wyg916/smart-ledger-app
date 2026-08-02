package com.offline.ledger.backup

import kotlinx.serialization.Serializable

@Serializable
data class BackupMeta(
    val version: Int,
    val createdAt: Long,
    val appVersionName: String,
    val isAuto: Boolean,
)

