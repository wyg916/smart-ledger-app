package com.offline.ledger.backup

import android.content.Context
import android.net.Uri
import android.os.Build
import androidx.core.content.FileProvider
import com.offline.ledger.BuildConfig
import com.offline.ledger.data.db.LedgerDatabase
import com.offline.ledger.security.SecurePrefs
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileOutputStream
import java.time.LocalDateTime
import java.time.format.DateTimeFormatter
import java.util.zip.ZipEntry
import java.util.zip.ZipInputStream
import java.util.zip.ZipOutputStream
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

class BackupManager(
    private val context: Context,
    private val securePrefs: SecurePrefs,
) {
    private val json = Json { encodeDefaults = true }

    private fun getLegacyBackupsDir(): File {
        val dir = File(context.getExternalFilesDir(null), "Backups")
        if (!dir.exists()) dir.mkdirs()
        return dir
    }

    fun listBackups(): List<BackupEntry> {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            MediaStoreBackups(context).listAll().take(RETENTION_COUNT)
        } else {
            listLegacyBackups()
        }
    }

    suspend fun migrateLegacyBackupsToMediaStoreIfPossible() = withContext(Dispatchers.IO) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return@withContext

        val legacyDir = getLegacyBackupsDir()
        val legacyFiles = legacyDir.listFiles { f -> f.isFile && f.name.endsWith(EXT) }?.toList().orEmpty()
            .sortedByDescending { it.lastModified() }

        if (legacyFiles.isEmpty()) return@withContext

        val store = MediaStoreBackups(context)
        val existingNames = store.listAll().mapTo(mutableSetOf()) { it.displayName }

        legacyFiles.forEach { file ->
            if (existingNames.contains(file.name)) {
                file.delete()
                return@forEach
            }
            runCatching {
                store.writeBackup(displayName = file.name, bytes = file.readBytes())
                existingNames.add(file.name)
                file.delete()
            }
        }

        store.enforceRetention(RETENTION_COUNT)
        enforceLegacyRetention(legacyDir)
    }

    suspend fun createBackup(isAuto: Boolean): BackupEntry = withContext(Dispatchers.IO) {
        val wrapInfo = securePrefs.getBackupKeyWrapInfo() ?: error("未设置备份密码")
        val masterKey = securePrefs.getOrCreateBackupMasterKey()

        val dbFile = context.getDatabasePath(LedgerDatabase.DB_NAME)
        require(dbFile.exists()) { "DB not found" }

        val meta = BackupMeta(
            version = 1,
            createdAt = System.currentTimeMillis(),
            appVersionName = BuildConfig.VERSION_NAME,
            isAuto = isAuto,
        )

        val zipBytes = buildZip(dbFile = dbFile, meta = meta)
        val encrypted = BackupCrypto.encryptZip(zipBytes, masterKey, wrapInfo)

        val ts = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMdd_HHmmss"))
        val displayName = "backup_${ts}_${if (isAuto) "auto" else "manual"}$EXT"

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val store = MediaStoreBackups(context)
            val entry = store.writeBackup(displayName = displayName, bytes = encrypted)
            store.enforceRetention(RETENTION_COUNT)
            entry
        } else {
            val dir = getLegacyBackupsDir()
            val outFile = File(dir, displayName)
            FileOutputStream(outFile).use { it.write(encrypted) }
            enforceLegacyRetention(dir)
            BackupEntry(
                uri = fileToUri(outFile),
                displayName = outFile.name,
                sizeBytes = outFile.length().coerceAtLeast(0L),
                modifiedAtMillis = outFile.lastModified().coerceAtLeast(0L),
                isAuto = isAuto,
            )
        }
    }

    suspend fun restoreFromUri(uri: Uri, password: String) = withContext(Dispatchers.IO) {
        val bytes = context.contentResolver.openInputStream(uri)?.use { it.readBytes() }
            ?: error("无法读取文件")
        restoreFromEncryptedBytes(bytes, password)
    }

    suspend fun restoreFromFile(file: File, password: String) = withContext(Dispatchers.IO) {
        val bytes = file.readBytes()
        restoreFromEncryptedBytes(bytes, password)
    }

    private fun restoreFromEncryptedBytes(encrypted: ByteArray, password: String) {
        val zipBytes = BackupCrypto.decryptToZip(encrypted, password)
        val dbBytes = unzipDb(zipBytes) ?: error("备份内缺少数据库")

        val dbFile = context.getDatabasePath(LedgerDatabase.DB_NAME)
        val tmp = File(dbFile.parentFile, "${dbFile.name}.restore.tmp")
        FileOutputStream(tmp).use { it.write(dbBytes) }

        // Clean up potential SQLite side files.
        runCatching { File("${dbFile.absolutePath}-journal").delete() }
        runCatching { File("${dbFile.absolutePath}-wal").delete() }
        runCatching { File("${dbFile.absolutePath}-shm").delete() }

        if (dbFile.exists()) dbFile.delete()
        if (!tmp.renameTo(dbFile)) {
            tmp.copyTo(dbFile, overwrite = true)
            tmp.delete()
        }
    }

    private fun buildZip(dbFile: File, meta: BackupMeta): ByteArray {
        val out = ByteArrayOutputStream()
        ZipOutputStream(out).use { zos ->
            zos.putNextEntry(ZipEntry("db.sqlite"))
            dbFile.inputStream().use { it.copyTo(zos) }
            zos.closeEntry()

            zos.putNextEntry(ZipEntry("meta.json"))
            val metaJson = json.encodeToString(meta).toByteArray(Charsets.UTF_8)
            zos.write(metaJson)
            zos.closeEntry()
        }
        return out.toByteArray()
    }

    private fun unzipDb(zipBytes: ByteArray): ByteArray? {
        ZipInputStream(ByteArrayInputStream(zipBytes)).use { zis ->
            while (true) {
                val entry = zis.nextEntry ?: break
                if (!entry.isDirectory && entry.name == "db.sqlite") {
                    return zis.readBytes()
                }
            }
        }
        return null
    }

    private fun listLegacyBackups(): List<BackupEntry> {
        val dir = getLegacyBackupsDir()
        val files = dir.listFiles { f -> f.isFile && f.name.endsWith(EXT) }?.toList().orEmpty()
            .sortedByDescending { it.lastModified() }
            .take(RETENTION_COUNT)

        return files.map { f ->
            BackupEntry(
                uri = fileToUri(f),
                displayName = f.name,
                sizeBytes = f.length().coerceAtLeast(0L),
                modifiedAtMillis = f.lastModified().coerceAtLeast(0L),
                isAuto = f.name.contains("_auto"),
            )
        }
    }

    private fun enforceLegacyRetention(dir: File) {
        val files = dir.listFiles { f -> f.isFile && f.name.endsWith(EXT) }?.toList().orEmpty()
            .sortedByDescending { it.lastModified() }
        files.drop(RETENTION_COUNT).forEach { it.delete() }
    }

    private fun fileToUri(file: File): Uri {
        return FileProvider.getUriForFile(
            context,
            "${context.packageName}.fileprovider",
            file,
        )
    }

    private companion object {
        private const val RETENTION_COUNT: Int = 5
        private const val EXT: String = ".zip.enc"
    }
}

