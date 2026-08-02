package com.offline.ledger.data.prefs

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class BudgetItem(
    @SerialName("id")
    val id: String,
    @SerialName("name")
    val name: String,
    @SerialName("budget_cent")
    val budgetCent: Long = 0,
    @SerialName("category_ids")
    val categoryIds: List<Long> = emptyList(),
    @SerialName("preset")
    val preset: Boolean = false,
)

