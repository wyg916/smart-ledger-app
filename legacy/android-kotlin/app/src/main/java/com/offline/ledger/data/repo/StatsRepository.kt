package com.offline.ledger.data.repo

import com.offline.ledger.data.db.dao.TransactionDao
import com.offline.ledger.data.db.model.CategorySummaryRow
import com.offline.ledger.data.db.model.DailySummaryRow
import com.offline.ledger.data.db.model.MonthlySummaryRow
import kotlinx.coroutines.flow.Flow
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class StatsRepository @Inject constructor(
    private val transactionDao: TransactionDao,
) {
    fun observeDailySummary(startInclusive: Long, endInclusive: Long): Flow<List<DailySummaryRow>> {
        return transactionDao.observeDailySummary(startInclusive, endInclusive)
    }

    fun observeMonthlySummary(startInclusive: Long, endInclusive: Long): Flow<List<MonthlySummaryRow>> {
        return transactionDao.observeMonthlySummary(startInclusive, endInclusive)
    }

    suspend fun getCategorySummary(type: Int, startInclusive: Long, endInclusive: Long): List<CategorySummaryRow> {
        return transactionDao.getCategorySummary(type, startInclusive, endInclusive)
    }

    suspend fun getTotalForType(type: Int, startInclusive: Long, endInclusive: Long): Long {
        return transactionDao.getTotalForType(type, startInclusive, endInclusive) ?: 0L
    }
}
