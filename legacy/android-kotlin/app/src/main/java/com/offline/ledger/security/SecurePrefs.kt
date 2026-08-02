package com.offline.ledger.security

import android.content.Context
import android.util.Base64
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import dagger.hilt.android.qualifiers.ApplicationContext
import java.security.MessageDigest
import java.security.SecureRandom
import javax.crypto.Cipher
import javax.crypto.spec.GCMParameterSpec
import javax.crypto.SecretKeyFactory
import javax.crypto.spec.SecretKeySpec
import javax.crypto.spec.PBEKeySpec
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class SecurePrefs @Inject constructor(
    @ApplicationContext context: Context,
) {
    private val masterKey: MasterKey = MasterKey.Builder(context)
        .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
        .build()

    private val prefs = EncryptedSharedPreferences.create(
        context,
        "secure_prefs",
        masterKey,
        EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
        EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM,
    )

    fun hasPin(): Boolean = prefs.contains(KEY_PIN_HASH) && prefs.contains(KEY_PIN_SALT) && prefs.contains(KEY_PIN_ITER)

    fun clearPin() {
        prefs.edit()
            .remove(KEY_PIN_HASH)
            .remove(KEY_PIN_SALT)
            .remove(KEY_PIN_ITER)
            .apply()
    }

    fun setPin(pin: String) {
        require(pin.length == 6 && pin.all { it.isDigit() }) { "PIN must be 6 digits" }
        val salt = ByteArray(SALT_BYTES).also { SecureRandom().nextBytes(it) }
        val iterations = DEFAULT_ITERATIONS
        val hash = pbkdf2(pin, salt, iterations)

        prefs.edit()
            .putString(KEY_PIN_SALT, Base64.encodeToString(salt, Base64.NO_WRAP))
            .putString(KEY_PIN_HASH, Base64.encodeToString(hash, Base64.NO_WRAP))
            .putInt(KEY_PIN_ITER, iterations)
            .apply()
    }

    fun verifyPin(pin: String): Boolean {
        if (pin.length != 6 || !pin.all { it.isDigit() }) return false
        val saltB64 = prefs.getString(KEY_PIN_SALT, null) ?: return false
        val hashB64 = prefs.getString(KEY_PIN_HASH, null) ?: return false
        val iterations = prefs.getInt(KEY_PIN_ITER, DEFAULT_ITERATIONS)

        val salt = Base64.decode(saltB64, Base64.NO_WRAP)
        val expected = Base64.decode(hashB64, Base64.NO_WRAP)
        val actual = pbkdf2(pin, salt, iterations)
        return MessageDigest.isEqual(expected, actual)
    }

    private fun pbkdf2(pin: String, salt: ByteArray, iterations: Int): ByteArray {
        val spec = PBEKeySpec(pin.toCharArray(), salt, iterations, KEY_BITS)
        val factory = SecretKeyFactory.getInstance("PBKDF2WithHmacSHA256")
        return factory.generateSecret(spec).encoded
    }

    fun hasBackupPasswordConfigured(): Boolean {
        return prefs.contains(KEY_BACKUP_MASTER_KEY) &&
            prefs.contains(KEY_BACKUP_WRAP_SALT) &&
            prefs.contains(KEY_BACKUP_WRAP_NONCE) &&
            prefs.contains(KEY_BACKUP_WRAP_ITER) &&
            prefs.contains(KEY_BACKUP_WRAPPED_KEY)
    }

    fun getOrCreateBackupMasterKey(): ByteArray {
        val existing = prefs.getString(KEY_BACKUP_MASTER_KEY, null)
        if (existing != null) {
            return Base64.decode(existing, Base64.NO_WRAP)
        }
        val key = ByteArray(BACKUP_KEY_BYTES).also { SecureRandom().nextBytes(it) }
        prefs.edit()
            .putString(KEY_BACKUP_MASTER_KEY, Base64.encodeToString(key, Base64.NO_WRAP))
            .apply()
        return key
    }

    fun setBackupPassword(password: String) {
        require(password.isNotBlank()) { "Password must not be blank" }
        val masterKeyBytes = getOrCreateBackupMasterKey()

        val salt = ByteArray(SALT_BYTES).also { SecureRandom().nextBytes(it) }
        val nonce = ByteArray(GCM_NONCE_BYTES).also { SecureRandom().nextBytes(it) }
        val iterations = DEFAULT_ITERATIONS

        val wrapKeyBytes = pbkdf2Password(password, salt, iterations)
        val wrappedKey = aesGcmEncrypt(
            keyBytes = wrapKeyBytes,
            nonce = nonce,
            plaintext = masterKeyBytes,
        )

        prefs.edit()
            .putString(KEY_BACKUP_WRAP_SALT, Base64.encodeToString(salt, Base64.NO_WRAP))
            .putString(KEY_BACKUP_WRAP_NONCE, Base64.encodeToString(nonce, Base64.NO_WRAP))
            .putInt(KEY_BACKUP_WRAP_ITER, iterations)
            .putString(KEY_BACKUP_WRAPPED_KEY, Base64.encodeToString(wrappedKey, Base64.NO_WRAP))
            .apply()
    }

    fun getBackupKeyWrapInfo(): BackupKeyWrapInfo? {
        val saltB64 = prefs.getString(KEY_BACKUP_WRAP_SALT, null) ?: return null
        val nonceB64 = prefs.getString(KEY_BACKUP_WRAP_NONCE, null) ?: return null
        val wrappedB64 = prefs.getString(KEY_BACKUP_WRAPPED_KEY, null) ?: return null
        val iter = prefs.getInt(KEY_BACKUP_WRAP_ITER, DEFAULT_ITERATIONS)
        return BackupKeyWrapInfo(
            iterations = iter,
            salt = Base64.decode(saltB64, Base64.NO_WRAP),
            nonce = Base64.decode(nonceB64, Base64.NO_WRAP),
            wrappedKey = Base64.decode(wrappedB64, Base64.NO_WRAP),
        )
    }

    fun clearBackupPassword() {
        prefs.edit()
            .remove(KEY_BACKUP_WRAP_SALT)
            .remove(KEY_BACKUP_WRAP_NONCE)
            .remove(KEY_BACKUP_WRAP_ITER)
            .remove(KEY_BACKUP_WRAPPED_KEY)
            .apply()
    }

    fun resetBackupPassword() {
        prefs.edit()
            .remove(KEY_BACKUP_MASTER_KEY)
            .remove(KEY_BACKUP_WRAP_SALT)
            .remove(KEY_BACKUP_WRAP_NONCE)
            .remove(KEY_BACKUP_WRAP_ITER)
            .remove(KEY_BACKUP_WRAPPED_KEY)
            .apply()
    }

    fun verifyBackupPassword(password: String): Boolean {
        if (!hasBackupPasswordConfigured()) return false
        val wrap = getBackupKeyWrapInfo() ?: return false
        val masterKeyB64 = prefs.getString(KEY_BACKUP_MASTER_KEY, null) ?: return false
        val expectedMasterKey = Base64.decode(masterKeyB64, Base64.NO_WRAP)

        return try {
            val wrapKeyBytes = pbkdf2Password(password, wrap.salt, wrap.iterations)
            val unwrapped = aesGcmDecrypt(
                keyBytes = wrapKeyBytes,
                nonce = wrap.nonce,
                ciphertext = wrap.wrappedKey,
            )
            MessageDigest.isEqual(expectedMasterKey, unwrapped)
        } catch (t: Throwable) {
            false
        }
    }

    private fun pbkdf2Password(password: String, salt: ByteArray, iterations: Int): ByteArray {
        val spec = PBEKeySpec(password.toCharArray(), salt, iterations, KEY_BITS)
        val factory = SecretKeyFactory.getInstance("PBKDF2WithHmacSHA256")
        return factory.generateSecret(spec).encoded
    }

    private fun aesGcmEncrypt(keyBytes: ByteArray, nonce: ByteArray, plaintext: ByteArray): ByteArray {
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        val key = SecretKeySpec(keyBytes, "AES")
        cipher.init(Cipher.ENCRYPT_MODE, key, GCMParameterSpec(GCM_TAG_BITS, nonce))
        return cipher.doFinal(plaintext)
    }

    private fun aesGcmDecrypt(keyBytes: ByteArray, nonce: ByteArray, ciphertext: ByteArray): ByteArray {
        val cipher = Cipher.getInstance("AES/GCM/NoPadding")
        val key = SecretKeySpec(keyBytes, "AES")
        cipher.init(Cipher.DECRYPT_MODE, key, GCMParameterSpec(GCM_TAG_BITS, nonce))
        return cipher.doFinal(ciphertext)
    }

    private companion object {
        private const val KEY_BITS: Int = 256
        private const val SALT_BYTES: Int = 16
        private const val DEFAULT_ITERATIONS: Int = 120_000
        private const val BACKUP_KEY_BYTES: Int = 32
        private const val GCM_NONCE_BYTES: Int = 12
        private const val GCM_TAG_BITS: Int = 128

        private const val KEY_PIN_SALT: String = "pin_salt_b64"
        private const val KEY_PIN_HASH: String = "pin_hash_b64"
        private const val KEY_PIN_ITER: String = "pin_iter"

        private const val KEY_BACKUP_MASTER_KEY: String = "backup_master_key_b64"
        private const val KEY_BACKUP_WRAP_SALT: String = "backup_wrap_salt_b64"
        private const val KEY_BACKUP_WRAP_NONCE: String = "backup_wrap_nonce_b64"
        private const val KEY_BACKUP_WRAP_ITER: String = "backup_wrap_iter"
        private const val KEY_BACKUP_WRAPPED_KEY: String = "backup_wrapped_key_b64"
    }
}
