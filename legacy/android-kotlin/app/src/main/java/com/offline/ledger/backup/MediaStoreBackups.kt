package com.offline.ledger.backup

import android.content.ContentResolver
import android.content.ContentUris
import android.content.ContentValues
import android.content.Context
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.annotation.RequiresApi

@RequiresApi(Build.VERSION_CODES.Q)
internal class MediaStoreBackups(
    private val context: Context,
) {
    private val resolver: ContentResolver = context.contentResolver
    private val collection: Uri = MediaStore.Downloads.EXTERNAL_CONTENT_URI

    private val relativePath: String = "${Environment.DIRECTORY_DOWNLOADS}/OfflineLedger/Backups/"

    fun listAll(): List<BackupEntry> {
        val projection = arrayOf(
            MediaStore.Downloads._ID,
            MediaStore.Downloads.DISPLAY_NAME,
            MediaStore.Downloads.SIZE,
            MediaStore.Downloads.DATE_MODIFIED,
        )
        val selection = "${MediaStore.Downloads.RELATIVE_PATH}=?"
        val selectionArgs = arrayOf(relativePath)
        val sortOrder = "${MediaStore.Downloads.DATE_MODIFIED} DESC"

        val result = mutableListOf<BackupEntry>()
        resolver.query(collection, projection, selection, selectionArgs, sortOrder)?.use { cursor ->
            val idIndex = cursor.getColumnIndexOrThrow(MediaStore.Downloads._ID)
            val nameIndex = cursor.getColumnIndexOrThrow(MediaStore.Downloads.DISPLAY_NAME)
            val sizeIndex = cursor.getColumnIndexOrThrow(MediaStore.Downloads.SIZE)
            val modifiedIndex = cursor.getColumnIndexOrThrow(MediaStore.Downloads.DATE_MODIFIED)

            while (cursor.moveToNext()) {
                val id = cursor.getLong(idIndex)
                val name = cursor.getString(nameIndex) ?: continue
                if (!name.endsWith(".zip.enc")) continue
                val size = cursor.getLong(sizeIndex).coerceAtLeast(0L)
                val modifiedSeconds = cursor.getLong(modifiedIndex).coerceAtLeast(0L)
                val uri = ContentUris.withAppendedId(collection, id)
                result.add(
                    BackupEntry(
                        uri = uri,
                        displayName = name,
                        sizeBytes = size,
                        modifiedAtMillis = modifiedSeconds * 1000L,
                        isAuto = name.contains("_auto"),
                    ),
                )
            }
        }
        return result
    }

    fun writeBackup(displayName: String, bytes: ByteArray): BackupEntry {
        val values = ContentValues().apply {
            put(MediaStore.Downloads.DISPLAY_NAME, displayName)
            put(MediaStore.Downloads.MIME_TYPE, "application/octet-stream")
            put(MediaStore.Downloads.RELATIVE_PATH, relativePath)
            put(MediaStore.Downloads.IS_PENDING, 1)
        }
        val uri = resolver.insert(collection, values) ?: error("无法创建备份文件")
        try {
            resolver.openOutputStream(uri)?.use { out ->
                out.write(bytes)
            } ?: error("无法写入备份文件")
        } finally {
            val done = ContentValues().apply { put(MediaStore.Downloads.IS_PENDING, 0) }
            resolver.update(uri, done, null, null)
        }

        val now = System.currentTimeMillis()
        return BackupEntry(
            uri = uri,
            displayName = displayName,
            sizeBytes = bytes.size.toLong(),
            modifiedAtMillis = now,
            isAuto = displayName.contains("_auto"),
        )
    }

    fun delete(uri: Uri) {
        resolver.delete(uri, null, null)
    }

    fun enforceRetention(keepCount: Int) {
        val all = listAll()
        all.drop(keepCount).forEach { delete(it.uri) }
    }
}

