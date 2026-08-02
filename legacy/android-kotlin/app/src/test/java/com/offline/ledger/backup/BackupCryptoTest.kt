package com.offline.ledger.backup

import com.offline.ledger.security.BackupKeyWrapInfo
import java.security.SecureRandom
import javax.crypto.Cipher
import javax.crypto.SecretKeyFactory
import javax.crypto.spec.GCMParameterSpec
import javax.crypto.spec.PBEKeySpec
import javax.crypto.spec.SecretKeySpec
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertThrows
import org.junit.Test

class BackupCryptoTest {
    @Test
    fun encryptDecrypt_roundTrip_ok() {
        val password = "pass12345"
        val zipBytes = ByteArray(1024).also { SecureRandom().nextBytes(it) }
        val backupMasterKey = ByteArray(32).also { SecureRandom().nextBytes(it) }

        val wrapInfo = createWrapInfo(password, backupMasterKey, iterations = 5_000)

        val encrypted = BackupCrypto.encryptZip(
            zipBytes = zipBytes,
            backupMasterKey = backupMasterKey,
            wrapInfo = wrapInfo,
        )
        val decrypted = BackupCrypto.decryptToZip(encrypted, password)
        assertArrayEquals(zipBytes, decrypted)
    }

    @Test
    fun decrypt_wrongPassword_throws() {
        val password = "pass12345"
        val zipBytes = "hello".toByteArray()
        val backupMasterKey = ByteArray(32).also { SecureRandom().nextBytes(it) }
        val wrapInfo = createWrapInfo(password, backupMasterKey, iterations = 5_000)
        val encrypted = BackupCrypto.encryptZip(zipBytes, backupMasterKey, wrapInfo)

        assertThrows(Exception::class.java) {
            BackupCrypto.decryptToZip(encrypted, "wrong-pass")
        }
    }

    private fun createWrapInfo(password: String, backupMasterKey: ByteArray, iterations: Int): BackupKeyWrapInfo {
        val salt = ByteArray(16).also { SecureRandom().nextBytes(it) }
        val nonce = ByteArray(12).also { SecureRandom().nextBytes(it) }

        val wrapKeyBytes = pbkdf2(password, salt, iterations)
        val wrapped = aesGcmEncrypt(wrapKeyBytes, nonce, backupMasterKey)

        return BackupKeyWrapInfo(iterations = iterations, salt = salt, nonce = nonce, wrappedKey = wrapped)
    }

    private fun pbkdf2(password: String, salt: ByteArray, iterations: Int): ByteArray {
        val spec = PBEKeySpec(password.toCharArray(), salt, iterations, 256)
        val factory = SecretKeyFactory.getInstance("PBKDF2WithHmacSHA256")
        return factory.generateSecret(spec).encoded
    }

    private fun aesGcmEncrypt(keyBytes: ByteArray, nonce: ByteArray, plaintext: ByteArray): ByteArray {
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        val key = SecretKeySpec(keyBytes, "AES")
        cipher.init(Cipher.ENCRYPT_MODE, key, GCMParameterSpec(128, nonce))
        return cipher.doFinal(plaintext)
    }
}

