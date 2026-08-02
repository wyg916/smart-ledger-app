package com.offline.ledger.backup

import com.offline.ledger.security.BackupKeyWrapInfo
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.io.DataInputStream
import java.io.DataOutputStream
import java.security.SecureRandom
import javax.crypto.Cipher
import javax.crypto.SecretKeyFactory
import javax.crypto.spec.GCMParameterSpec
import javax.crypto.spec.PBEKeySpec
import javax.crypto.spec.SecretKeySpec

object BackupCrypto {
    private const val MAGIC: String = "LGBK"
    private const val VERSION: Byte = 1
    private const val KEY_BITS: Int = 256
    private const val GCM_TAG_BITS: Int = 128
    private const val DATA_NONCE_BYTES: Int = 12

    fun encryptZip(
        zipBytes: ByteArray,
        backupMasterKey: ByteArray,
        wrapInfo: BackupKeyWrapInfo,
    ): ByteArray {
        val dataNonce = ByteArray(DATA_NONCE_BYTES).also { SecureRandom().nextBytes(it) }
        val ciphertext = aesGcmEncrypt(keyBytes = backupMasterKey, nonce = dataNonce, plaintext = zipBytes)

        val out = ByteArrayOutputStream()
        DataOutputStream(out).use { dos ->
            dos.writeBytes(MAGIC)
            dos.writeByte(VERSION.toInt())

            dos.writeInt(wrapInfo.iterations)
            dos.writeByte(wrapInfo.salt.size)
            dos.write(wrapInfo.salt)
            dos.writeByte(wrapInfo.nonce.size)
            dos.write(wrapInfo.nonce)
            dos.writeInt(wrapInfo.wrappedKey.size)
            dos.write(wrapInfo.wrappedKey)

            dos.writeByte(dataNonce.size)
            dos.write(dataNonce)

            dos.write(ciphertext)
        }
        return out.toByteArray()
    }

    fun decryptToZip(
        encryptedBytes: ByteArray,
        password: String,
    ): ByteArray {
        val dis = DataInputStream(ByteArrayInputStream(encryptedBytes))
        val magicBytes = ByteArray(4)
        dis.readFully(magicBytes)
        val magic = String(magicBytes, Charsets.US_ASCII)
        require(magic == MAGIC) { "Bad backup magic" }

        val version = dis.readByte()
        require(version == VERSION) { "Unsupported backup version: $version" }

        val iterations = dis.readInt()
        val saltLen = dis.readUnsignedByte()
        val salt = ByteArray(saltLen)
        dis.readFully(salt)

        val wrapNonceLen = dis.readUnsignedByte()
        val wrapNonce = ByteArray(wrapNonceLen)
        dis.readFully(wrapNonce)

        val wrappedKeyLen = dis.readInt()
        val wrappedKey = ByteArray(wrappedKeyLen)
        dis.readFully(wrappedKey)

        val dataNonceLen = dis.readUnsignedByte()
        val dataNonce = ByteArray(dataNonceLen)
        dis.readFully(dataNonce)

        val ciphertext = dis.readBytes()

        val wrapKeyBytes = pbkdf2(password, salt, iterations)
        val backupMasterKey = aesGcmDecrypt(keyBytes = wrapKeyBytes, nonce = wrapNonce, ciphertext = wrappedKey)

        return aesGcmDecrypt(keyBytes = backupMasterKey, nonce = dataNonce, ciphertext = ciphertext)
    }

    private fun pbkdf2(password: String, salt: ByteArray, iterations: Int): ByteArray {
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
}

