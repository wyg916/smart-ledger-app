package com.offline.ledger.data.db.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update
import com.offline.ledger.data.db.entity.TransactionEntity
import com.offline.ledger.data.db.model.CategorySummaryRow
import com.offline.ledger.data.db.model.DailySummaryRow
import com.offline.ledger.data.db.model.MonthlySummaryRow
import kotlinx.coroutines.flow.Flow

@Dao
interface TransactionDao {
    @Query("SELECT * FROM transactions WHERE id = :id")
    suspend fun getById(id: Long): TransactionEntity?

    @Insert(onConflict = OnConflictStrategy.ABORT)
    suspend fun insert(entity: TransactionEntity): Long

    @Update
    suspend fun update(entity: TransactionEntity)

    @Query("UPDATE transactions SET deleted = 1, updated_at = :updatedAt WHERE id = :id")
    suspend fun softDelete(id: Long, updatedAt: Long)

    @Query(
        """
        SELECT * FROM transactions
        WHERE deleted = 0
          AND occurred_at BETWEEN :startInclusive AND :endInclusive
          AND (:type IS NULL OR type = :type)
          AND (:categoryId IS NULL OR category_id = :categoryId)
          AND (:keyword IS NULL OR note LIKE '%' || :keyword || '%')
        ORDER BY occurred_at DESC, id DESC
        """,
    )
    fun observeTransactions(
        startInclusive: Long,
        endInclusive: Long,
        type: Int?,
        categoryId: Long?,
        keyword: String?,
    ): Flow<List<TransactionEntity>>

    @Query(
        """
        SELECT * FROM transactions
        WHERE deleted = 0
          AND occurred_at BETWEEN :startInclusive AND :endInclusive
          AND (:type IS NULL OR type = :type)
        ORDER BY occurred_at ASC, id ASC
        """,
    )
    suspend fun getTransactionsForExport(
        startInclusive: Long,
        endInclusive: Long,
        type: Int?,
    ): List<TransactionEntity>

    @Query(
        """
        SELECT
            strftime('%Y-%m-%d', occurred_at/1000, 'unixepoch', 'localtime') as day,
            SUM(CASE WHEN type = 0 THEN amount_cent ELSE 0 END) as expense_cent,
            SUM(CASE WHEN type = 1 THEN amount_cent ELSE 0 END) as income_cent
        FROM transactions
        WHERE deleted = 0
          AND occurred_at BETWEEN :startInclusive AND :endInclusive
        GROUP BY day
        ORDER BY day DESC
        """,
    )
    fun observeDailySummary(
        startInclusive: Long,
        endInclusive: Long,
    ): Flow<List<DailySummaryRow>>

    @Query(
        """
        SELECT
            strftime('%Y-%m', occurred_at/1000, 'unixepoch', 'localtime') as month,
            SUM(CASE WHEN type = 0 THEN amount_cent ELSE 0 END) as expense_cent,
            SUM(CASE WHEN type = 1 THEN amount_cent ELSE 0 END) as income_cent
        FROM transactions
        WHERE deleted = 0
          AND occurred_at BETWEEN :startInclusive AND :endInclusive
        GROUP BY month
        ORDER BY month DESC
        """,
    )
    fun observeMonthlySummary(
        startInclusive: Long,
        endInclusive: Long,
    ): Flow<List<MonthlySummaryRow>>

    @Query(
        """
        SELECT
            c.id as category_id,
            c.name as category_name,
            c.icon_code as icon_code,
            SUM(t.amount_cent) as total_cent,
            COUNT(*) as count
        FROM transactions t
        JOIN categories c ON c.id = t.category_id
        WHERE t.deleted = 0
          AND t.type = :type
          AND t.occurred_at BETWEEN :startInclusive AND :endInclusive
        GROUP BY c.id, c.name, c.icon_code
        ORDER BY total_cent DESC
        """,
    )
    suspend fun getCategorySummary(
        type: Int,
        startInclusive: Long,
        endInclusive: Long,
    ): List<CategorySummaryRow>

    @Query(
        """
        SELECT SUM(amount_cent) FROM transactions
        WHERE deleted = 0
          AND type = :type
          AND occurred_at BETWEEN :startInclusive AND :endInclusive
        """,
    )
    suspend fun getTotalForType(
        type: Int,
        startInclusive: Long,
        endInclusive: Long,
    ): Long?
}
