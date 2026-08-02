package com.offline.ledger.ui.components

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.*
import androidx.compose.ui.graphics.vector.ImageVector

object CategoryIcons {
    val choices: List<String> = listOf(
        // Expense presets / common
        "meal",
        "fine_meal",
        "shopping",
        "daily",
        "transport",
        "vegetable",
        "fruit",
        "snack",
        "sport",
        "entertainment",
        "communication",
        "clothes",
        "beauty",
        "housing",
        "water",
        "electric",
        "living",
        "express",
        "elder",
        "social",
        "travel",
        "smoke_alcohol",
        "digital",
        "medical",
        "books",
        "study",
        "pets",
        "cat_food",
        "cat_litter",
        "gift_money",
        "gift_box",
        "office",
        "repair",
        "lottery",
        "relatives",
        // Income / generic
        "salary",
        "bonus",
        "gift",
        "other",
    )

    fun forCode(code: String): ImageVector {
        return when (code) {
            // Backward-compatible group codes
            "food" -> Icons.Outlined.Restaurant
            "fun" -> Icons.Outlined.Theaters
            "gift" -> Icons.Outlined.Redeem
            "other" -> Icons.Outlined.Category
            "transport" -> Icons.Outlined.DirectionsCar
            "shopping" -> Icons.Outlined.ShoppingCart
            "housing" -> Icons.Outlined.Home
            "medical" -> Icons.Outlined.LocalHospital
            "education" -> Icons.Outlined.School

            // Expense codes (more specific)
            "meal" -> Icons.Outlined.Restaurant
            "fine_meal" -> Icons.Outlined.RamenDining
            "daily" -> Icons.Outlined.ShoppingBag
            "vegetable" -> Icons.Outlined.Eco
            "fruit" -> Icons.Outlined.LocalGroceryStore
            "snack" -> Icons.Outlined.Icecream
            "sport" -> Icons.Outlined.FitnessCenter
            "entertainment" -> Icons.Outlined.Theaters
            "communication" -> Icons.Outlined.Phone
            "clothes" -> Icons.Outlined.Checkroom
            "beauty" -> Icons.Outlined.FaceRetouchingNatural
            "water" -> Icons.Outlined.WaterDrop
            "electric" -> Icons.Outlined.Bolt
            "living" -> Icons.Outlined.Weekend
            "express" -> Icons.Outlined.LocalShipping
            "elder" -> Icons.Outlined.Elderly
            "social" -> Icons.Outlined.People
            "travel" -> Icons.Outlined.Flight
            "smoke_alcohol" -> Icons.Outlined.WineBar
            "digital" -> Icons.Outlined.Computer
            "books" -> Icons.Outlined.MenuBook
            "study" -> Icons.Outlined.School
            "pets" -> Icons.Outlined.Pets
            "cat_food" -> Icons.Outlined.SetMeal
            "cat_litter" -> Icons.Outlined.CleaningServices
            "gift_money" -> Icons.Outlined.Paid
            "gift_box" -> Icons.Outlined.CardGiftcard
            "office" -> Icons.Outlined.Work
            "repair" -> Icons.Outlined.Handyman
            "lottery" -> Icons.Outlined.Casino
            "relatives" -> Icons.Outlined.FamilyRestroom

            // Income codes
            "salary" -> Icons.Outlined.AttachMoney
            "bonus" -> Icons.Outlined.EmojiEvents

            else -> Icons.Outlined.Category
        }
    }

    fun suggestCodeForName(
        name: String,
        usedCodes: Set<String>,
    ): String {
        val n = name.trim()
        if (n.isBlank()) {
            return choices.firstOrNull { it !in usedCodes && it != "other" } ?: "other"
        }

        val candidates = when {
            n.contains("餐") || n.contains("饭") || n.contains("伙食") -> listOf("meal", "fine_meal", "snack")
            n.contains("蔬菜") -> listOf("vegetable", "meal")
            n.contains("水果") -> listOf("fruit", "meal")
            n.contains("零食") -> listOf("snack", "meal")
            n.contains("购物") || n.contains("网购") -> listOf("shopping", "daily")
            n.contains("日用") -> listOf("daily", "shopping")
            n.contains("交通") || n.contains("出行") -> listOf("transport", "travel")
            n.contains("运动") -> listOf("sport", "entertainment")
            n.contains("娱乐") || n.contains("电影") || n.contains("游戏") -> listOf("entertainment", "sport")
            n.contains("通讯") || n.contains("电话") || n.contains("网") -> listOf("communication", "digital")
            n.contains("服饰") || n.contains("衣") -> listOf("clothes", "shopping")
            n.contains("美容") || n.contains("化妆") -> listOf("beauty", "shopping")
            n.contains("住房") || n.contains("房") -> listOf("housing", "living")
            n.contains("水费") -> listOf("water", "housing")
            n.contains("电费") -> listOf("electric", "housing")
            n.contains("居家") -> listOf("living", "housing")
            n.contains("快递") -> listOf("express", "shopping")
            n.contains("长辈") -> listOf("elder", "relatives")
            n.contains("社交") -> listOf("social", "gift")
            n.contains("亲友") || n.contains("朋友") || n.contains("家人") -> listOf("relatives", "social")
            n.contains("旅行") || n.contains("出差") -> listOf("travel", "transport")
            n.contains("烟") || n.contains("酒") -> listOf("smoke_alcohol", "entertainment")
            n.contains("数码") || n.contains("电脑") || n.contains("手机") -> listOf("digital", "communication")
            n.contains("医疗") || n.contains("药") -> listOf("medical", "other")
            n.contains("书") || n.contains("阅读") -> listOf("books", "study")
            n.contains("学习") || n.contains("教育") -> listOf("study", "books")
            n.contains("宠物") -> listOf("pets", "other")
            n.contains("猫粮") -> listOf("cat_food", "pets")
            n.contains("猫砂") -> listOf("cat_litter", "pets")
            n.contains("礼金") -> listOf("gift_money", "gift")
            n.contains("礼物") -> listOf("gift_box", "gift")
            n.contains("办公") -> listOf("office", "other")
            n.contains("维修") || n.contains("修") -> listOf("repair", "other")
            n.contains("彩票") -> listOf("lottery", "other")
            else -> listOf("other")
        }

        return candidates.firstOrNull { it !in usedCodes } ?: candidates.firstOrNull() ?: "other"
    }
}
