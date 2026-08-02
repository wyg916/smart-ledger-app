package com.offline.ledger.di

import android.content.Context
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.sqlite.db.SupportSQLiteDatabase
import com.offline.ledger.data.db.LedgerDatabase
import com.offline.ledger.data.db.dao.BookDao
import com.offline.ledger.data.db.dao.CategoryDao
import com.offline.ledger.data.db.dao.TransactionDao
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object AppModule {
    @Provides
    @Singleton
    fun provideDatabase(@ApplicationContext context: Context): LedgerDatabase {
        return Room.databaseBuilder(context, LedgerDatabase::class.java, LedgerDatabase.DB_NAME)
            .setJournalMode(RoomDatabase.JournalMode.TRUNCATE)
            .addCallback(
                object : RoomDatabase.Callback() {
                    override fun onCreate(db: SupportSQLiteDatabase) {
                        super.onCreate(db)
                        val now = System.currentTimeMillis()
                        db.execSQL("INSERT INTO books (id, name, created_at) VALUES (1, '个人账本', $now)")

                        // Expense categories (type=0)
                        val expense = listOf(
                            Triple(1001, "餐费", "meal"),
                            Triple(1002, "漂亮饭", "fine_meal"),
                            Triple(1003, "购物", "shopping"),
                            Triple(1004, "日用", "daily"),
                            Triple(1005, "交通", "transport"),
                            Triple(1006, "蔬菜", "vegetable"),
                            Triple(1007, "水果", "fruit"),
                            Triple(1008, "零食", "snack"),
                            Triple(1009, "运动", "sport"),
                            Triple(1010, "娱乐", "entertainment"),
                            Triple(1011, "通讯", "communication"),
                            Triple(1012, "服饰", "clothes"),
                            Triple(1013, "美容", "beauty"),
                            Triple(1014, "住房", "housing"),
                            Triple(1015, "水费", "water"),
                            Triple(1016, "电费", "electric"),
                            Triple(1017, "居家", "living"),
                            Triple(1018, "快递", "express"),
                            Triple(1019, "长辈", "elder"),
                            Triple(1020, "社交", "social"),
                            Triple(1021, "旅行", "travel"),
                            Triple(1022, "烟酒", "smoke_alcohol"),
                            Triple(1023, "数码", "digital"),
                            Triple(1024, "医疗", "medical"),
                            Triple(1025, "书籍", "books"),
                            Triple(1026, "学习", "study"),
                            Triple(1027, "宠物", "pets"),
                            Triple(1028, "猫粮", "cat_food"),
                            Triple(1029, "猫砂", "cat_litter"),
                            Triple(1030, "礼金", "gift_money"),
                            Triple(1031, "礼物", "gift_box"),
                            Triple(1032, "办公", "office"),
                            Triple(1033, "维修", "repair"),
                            Triple(1034, "彩票", "lottery"),
                            Triple(1035, "亲友", "relatives"),
                        )
                        expense.forEachIndexed { index, (id, name, icon) ->
                            db.execSQL(
                                "INSERT INTO categories (id, type, name, icon_code, sort_order, enabled, is_default) " +
                                    "VALUES ($id, 0, '$name', '$icon', $index, 1, 0)",
                            )
                        }

                        // Income categories (type=1)
                        val income = listOf(
                            Triple(2001, "工资", "salary"),
                            Triple(2002, "奖金", "bonus"),
                            Triple(2003, "礼金", "gift_money"),
                            Triple(2004, "其他", "other"),
                        )
                        income.forEachIndexed { index, (id, name, icon) ->
                            db.execSQL(
                                "INSERT INTO categories (id, type, name, icon_code, sort_order, enabled, is_default) " +
                                    "VALUES ($id, 1, '$name', '$icon', $index, 1, 0)",
                            )
                        }
                    }

                    override fun onOpen(db: SupportSQLiteDatabase) {
                        super.onOpen(db)
                        // Ensure required default categories exist for upgraded installs.
                        val requiredExpense = listOf(
                            "餐费" to "meal",
                            "漂亮饭" to "fine_meal",
                            "购物" to "shopping",
                            "日用" to "daily",
                            "交通" to "transport",
                            "蔬菜" to "vegetable",
                            "水果" to "fruit",
                            "零食" to "snack",
                            "运动" to "sport",
                            "娱乐" to "entertainment",
                            "通讯" to "communication",
                            "服饰" to "clothes",
                            "美容" to "beauty",
                            "住房" to "housing",
                            "水费" to "water",
                            "电费" to "electric",
                            "居家" to "living",
                            "快递" to "express",
                            "长辈" to "elder",
                            "社交" to "social",
                            "旅行" to "travel",
                            "烟酒" to "smoke_alcohol",
                            "数码" to "digital",
                            "医疗" to "medical",
                            "书籍" to "books",
                            "学习" to "study",
                            "宠物" to "pets",
                            "猫粮" to "cat_food",
                            "猫砂" to "cat_litter",
                            "礼金" to "gift_money",
                            "礼物" to "gift_box",
                            "办公" to "office",
                            "维修" to "repair",
                            "彩票" to "lottery",
                            "亲友" to "relatives",
                        )
                        requiredExpense.forEach { (name, icon) ->
                            db.execSQL(
                                """
                                INSERT INTO categories (type, name, icon_code, sort_order, enabled, is_default)
                                SELECT 0, '$name', '$icon',
                                    COALESCE((SELECT MAX(sort_order) + 1 FROM categories WHERE type = 0), 0),
                                    1, 0
                                WHERE NOT EXISTS (
                                    SELECT 1 FROM categories WHERE type = 0 AND name = '$name'
                                )
                                """.trimIndent(),
                            )
                        }

                        // Upgrade existing categories' icon_code when they still use legacy generic codes.
                        val legacyIconCodes = "'food','transport','shopping','housing','fun','medical','education','gift','other'"
                        requiredExpense.forEach { (name, icon) ->
                            db.execSQL(
                                "UPDATE categories SET icon_code = '$icon' " +
                                    "WHERE type = 0 AND name = '$name' AND icon_code IN ($legacyIconCodes)",
                            )
                        }
                        db.execSQL(
                            "UPDATE categories SET icon_code = 'gift_money' " +
                                "WHERE type = 1 AND name = '礼金' AND icon_code = 'gift'",
                        )
                    }
                },
            )
            .build()
    }

    @Provides
    fun provideBookDao(db: LedgerDatabase): BookDao = db.bookDao()

    @Provides
    fun provideCategoryDao(db: LedgerDatabase): CategoryDao = db.categoryDao()

    @Provides
    fun provideTransactionDao(db: LedgerDatabase): TransactionDao = db.transactionDao()
}
