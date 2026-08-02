package com.offline.ledger.data.repo

import com.offline.ledger.data.db.dao.TransactionDao
import com.offline.ledger.data.db.entity.TransactionEntity
import kotlinx.coroutines.flow.Flow
import javax.inject.Inject
import javax.inject.Singleton

data class TransactionFilter(
    val startInclusive: Long,
    val endInclusive: Long,
    val type: Int? = null,
    val categoryId: Long? = null,
    val keyword: String? = null,
)

@Singleton
class TransactionRepository @Inject constructor(
    private val transactionDao: TransactionDao,
) {
    fun observeTransactions(filter: TransactionFilter): Flow<List<TransactionEntity>> {
        return transactionDao.observeTransactions(
            startInclusive = filter.startInclusive,
            endInclusive = filter.endInclusive,
            type = filter.type,
            categoryId = filter.categoryId,
            keyword = filter.keyword?.takeIf { it.isNotBlank() },
        )
    }

    suspend fun getById(id: Long): TransactionEntity? = transactionDao.getById(id)

    suspend fun getTransactionsForExport(
        startInclusive: Long,
        endInclusive: Long,
        type: Int?,
    ): List<TransactionEntity> {
        return transactionDao.getTransactionsForExport(
            startInclusive = startInclusive,
            endInclusive = endInclusive,
            type = type,
        )
    }

    suspend fun addTransaction(
        type: Int,
        amountCent: Long,
        categoryId: Long,
        occurredAt: Long,
        note: String,
        bookId: Long = 1,
    ): Long {
        val now = System.currentTimeMillis()
        return transactionDao.insert(
            TransactionEntity(
                type = type,
                amountCent = amountCent,
                categoryId = categoryId,
                bookId = bookId,
                occurredAt = occurredAt,
                note = note,
                createdAt = now,
                updatedAt = now,
                deleted = false,
            ),
        )
    }

    suspend fun updateTransaction(updated: TransactionEntity) {
        transactionDao.update(updated.copy(updatedAt = System.currentTimeMillis()))
    }

    suspend fun deleteTransaction(id: Long) {
        transactionDao.softDelete(id = id, updatedAt = System.currentTimeMillis())
    }
}
