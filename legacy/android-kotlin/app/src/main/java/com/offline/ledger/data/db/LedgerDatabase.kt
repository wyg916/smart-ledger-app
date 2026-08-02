package com.offline.ledger.data.db

import androidx.room.Database
import androidx.room.RoomDatabase
import com.offline.ledger.data.db.dao.BookDao
import com.offline.ledger.data.db.dao.CategoryDao
import com.offline.ledger.data.db.dao.TransactionDao
import com.offline.ledger.data.db.entity.BookEntity
import com.offline.ledger.data.db.entity.CategoryEntity
import com.offline.ledger.data.db.entity.TransactionEntity

@Database(
    entities = [
        BookEntity::class,
        CategoryEntity::class,
        TransactionEntity::class,
    ],
    version = 1,
    exportSchema = false,
)
abstract class LedgerDatabase : RoomDatabase() {
    abstract fun bookDao(): BookDao
    abstract fun categoryDao(): CategoryDao
    abstract fun transactionDao(): TransactionDao

    companion object {
        const val DB_NAME: String = "ledger.db"
    }
}
