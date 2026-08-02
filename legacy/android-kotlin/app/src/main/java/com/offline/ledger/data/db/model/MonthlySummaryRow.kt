package com.offline.ledger.data.db.model

import androidx.room.ColumnInfo

data class MonthlySummaryRow(
    @ColumnInfo(name = "month")
    val month: String, // yyyy-MM in localtime
    @ColumnInfo(name = "expense_cent")
    val expenseCent: Long,
    @ColumnInfo(name = "income_cent")
    val incomeCent: Long,
)

