package com.offline.ledger.data.db.model

import androidx.room.ColumnInfo

data class CategorySummaryRow(
    @ColumnInfo(name = "category_id")
    val categoryId: Long,
    @ColumnInfo(name = "category_name")
    val categoryName: String,
    @ColumnInfo(name = "icon_code")
    val iconCode: String,
    @ColumnInfo(name = "total_cent")
    val totalCent: Long,
    @ColumnInfo(name = "count")
    val count: Long,
)

