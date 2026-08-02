package com.offline.ledger.data.prefs

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.intPreferencesKey
import androidx.datastore.preferences.core.longPreferencesKey
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.json.Json

private val Context.settingsDataStore: DataStore<Preferences> by preferencesDataStore(name = "settings")

data class LockSettings(
    val enabled: Boolean,
    val timeoutMinutes: Int,
    val biometricEnabled: Boolean,
)

@Singleton
class SettingsRepository @Inject constructor(
    @ApplicationContext private val context: Context,
) {
    private object Keys {
        val appLockEnabled = booleanPreferencesKey("app_lock_enabled")
        val appLockTimeoutMinutes = intPreferencesKey("app_lock_timeout_minutes")
        val appLockBiometricEnabled = booleanPreferencesKey("app_lock_biometric_enabled")
        val autoBackupEnabled = booleanPreferencesKey("auto_backup_enabled")
        val monthlyBudgetCent = longPreferencesKey("monthly_budget_cent")
        val budgetItemsJson = stringPreferencesKey("budget_items_json")
    }

    private val json = Json { ignoreUnknownKeys = true }

    val lockSettingsFlow: Flow<LockSettings> = context.settingsDataStore.data
        .map { prefs ->
            LockSettings(
                enabled = prefs[Keys.appLockEnabled] ?: false,
                timeoutMinutes = (prefs[Keys.appLockTimeoutMinutes] ?: 1).coerceAtLeast(0),
                biometricEnabled = prefs[Keys.appLockBiometricEnabled] ?: true,
            )
        }
        .distinctUntilChanged()

    suspend fun setAppLockEnabled(enabled: Boolean) {
        context.settingsDataStore.edit { it[Keys.appLockEnabled] = enabled }
    }

    suspend fun setAppLockTimeoutMinutes(minutes: Int) {
        context.settingsDataStore.edit { it[Keys.appLockTimeoutMinutes] = minutes.coerceAtLeast(0) }
    }

    suspend fun setAppLockBiometricEnabled(enabled: Boolean) {
        context.settingsDataStore.edit { it[Keys.appLockBiometricEnabled] = enabled }
    }

    val autoBackupEnabledFlow: Flow<Boolean> = context.settingsDataStore.data
        .map { prefs -> prefs[Keys.autoBackupEnabled] ?: false }
        .distinctUntilChanged()

    suspend fun setAutoBackupEnabled(enabled: Boolean) {
        context.settingsDataStore.edit { it[Keys.autoBackupEnabled] = enabled }
    }

    val monthlyBudgetCentFlow: Flow<Long> = context.settingsDataStore.data
        .map { prefs -> (prefs[Keys.monthlyBudgetCent] ?: 0L).coerceAtLeast(0L) }
        .distinctUntilChanged()

    suspend fun setMonthlyBudgetCent(amountCent: Long) {
        context.settingsDataStore.edit { it[Keys.monthlyBudgetCent] = amountCent.coerceAtLeast(0L) }
    }

    val budgetItemsFlow: Flow<List<BudgetItem>> = context.settingsDataStore.data
        .map { prefs ->
            val raw = prefs[Keys.budgetItemsJson] ?: return@map emptyList()
            runCatching { json.decodeFromString(ListSerializer(BudgetItem.serializer()), raw) }
                .getOrElse { emptyList() }
        }
        .distinctUntilChanged()

    suspend fun getBudgetItems(): List<BudgetItem> = budgetItemsFlow.first()

    suspend fun setBudgetItems(items: List<BudgetItem>) {
        val raw = json.encodeToString(ListSerializer(BudgetItem.serializer()), items)
        context.settingsDataStore.edit { it[Keys.budgetItemsJson] = raw }
    }

    suspend fun upsertBudgetItem(item: BudgetItem) {
        val current = getBudgetItems().toMutableList()
        val index = current.indexOfFirst { it.id == item.id }
        if (index >= 0) {
            current[index] = item
        } else {
            current.add(item)
        }
        setBudgetItems(current)
    }

    suspend fun deleteBudgetItem(id: String) {
        val current = getBudgetItems()
        setBudgetItems(current.filterNot { it.id == id })
    }
}
