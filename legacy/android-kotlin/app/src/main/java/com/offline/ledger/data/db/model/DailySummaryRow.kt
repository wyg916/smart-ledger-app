package com.offline.ledger.data.db.model

import androidx.room.ColumnInfo

data class DailySummaryRow(
    @ColumnInfo(name = "day")
    val day: String, // yyyy-MM-dd in localtime
    @ColumnInfo(name = "expense_cent")
    val expenseCent: Long,
    @ColumnInfo(name = "income_cent")
    val incomeCent: Long,
)

