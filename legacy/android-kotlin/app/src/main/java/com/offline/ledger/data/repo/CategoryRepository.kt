package com.offline.ledger.data.repo

import com.offline.ledger.data.db.dao.CategoryDao
import com.offline.ledger.data.db.entity.CategoryEntity
import kotlinx.coroutines.flow.Flow
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class CategoryRepository @Inject constructor(
    private val categoryDao: CategoryDao,
) {
    fun observeCategories(type: Int): Flow<List<CategoryEntity>> = categoryDao.observeByType(type)

    fun observeAllCategories(): Flow<List<CategoryEntity>> = categoryDao.observeAll()

    suspend fun getAllCategories(): List<CategoryEntity> = categoryDao.getAll()

    suspend fun addCategory(type: Int, name: String, iconCode: String, sortOrder: Int): Long {
        return categoryDao.insert(
            CategoryEntity(
                type = type,
                name = name,
                iconCode = iconCode,
                sortOrder = sortOrder,
                enabled = true,
                isDefault = false,
            ),
        )
    }

    suspend fun updateCategory(category: CategoryEntity) {
        categoryDao.update(category)
    }

    suspend fun deleteCategory(category: CategoryEntity) {
        if (category.isDefault) return
        categoryDao.delete(category)
    }

    suspend fun reorderCategories(categoriesInOrder: List<CategoryEntity>) {
        val updated = categoriesInOrder.mapIndexed { index, c -> c.copy(sortOrder = index) }
        categoryDao.updateAll(updated)
    }
}
