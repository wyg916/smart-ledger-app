package com.offline.ledger.security

data class BackupKeyWrapInfo(
    val iterations: Int,
    val salt: ByteArray,
    val nonce: ByteArray,
    val wrappedKey: ByteArray,
)

