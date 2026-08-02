package com.offline.ledger.ui.screens

import android.widget.Toast
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Add
import androidx.compose.material.icons.outlined.ArrowBack
import androidx.compose.material.icons.outlined.Delete
import androidx.compose.material.icons.outlined.Edit
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.Checkbox
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.ListItem
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.offline.ledger.data.prefs.BudgetItem
import com.offline.ledger.ui.viewmodel.BudgetEvent
import com.offline.ledger.ui.viewmodel.BudgetItemsEvent
import com.offline.ledger.ui.viewmodel.BudgetItemsViewModel
import com.offline.ledger.ui.viewmodel.BudgetViewModel
import com.offline.ledger.utils.MoneyUtils

@Composable
@OptIn(ExperimentalMaterial3Api::class)
fun BudgetScreen(
    onBack: () -> Unit,
    totalViewModel: BudgetViewModel = hiltViewModel(),
    itemsViewModel: BudgetItemsViewModel = hiltViewModel(),
) {
    val totalState by totalViewModel.uiState.collectAsState()
    val itemsState by itemsViewModel.uiState.collectAsState()
    val context = androidx.compose.ui.platform.LocalContext.current

    var showItemDialog by remember { mutableStateOf(false) }
    var editingItem: BudgetItem? by remember { mutableStateOf(null) }
    var itemName by remember { mutableStateOf("") }
    var itemBudgetInput by remember { mutableStateOf("") }
    var selectedCategoryIds by remember { mutableStateOf(setOf<Long>()) }

    var confirmDeleteId: String? by remember { mutableStateOf(null) }

    fun openItemDialog(item: BudgetItem?) {
        editingItem = item
        itemName = item?.name ?: ""
        itemBudgetInput = if (item == null || item.budgetCent == 0L) "" else MoneyUtils.formatCents(item.budgetCent)
        selectedCategoryIds = item?.categoryIds?.toSet() ?: emptySet()
        showItemDialog = true
    }

    LaunchedEffect(Unit) {
        totalViewModel.initIfEmpty()
    }

    LaunchedEffect(Unit) {
        totalViewModel.events.collect { e ->
            when (e) {
                BudgetEvent.Saved -> {
                    Toast.makeText(context, "已保存", Toast.LENGTH_SHORT).show()
                }

                is BudgetEvent.Error -> Toast.makeText(context, e.message, Toast.LENGTH_SHORT).show()
            }
        }
    }

    LaunchedEffect(Unit) {
        itemsViewModel.events.collect { e ->
            when (e) {
                is BudgetItemsEvent.Toast -> Toast.makeText(context, e.message, Toast.LENGTH_SHORT).show()
            }
        }
    }

    LaunchedEffect(itemsState.openItemId, itemsState.items) {
        val openId = itemsState.openItemId ?: return@LaunchedEffect
        val item = itemsState.items.firstOrNull { it.id == openId } ?: return@LaunchedEffect
        itemsViewModel.consumeOpenItem()
        openItemDialog(item)
    }

    if (confirmDeleteId != null) {
        val id = confirmDeleteId!!
        AlertDialog(
            onDismissRequest = { confirmDeleteId = null },
            title = { Text("确认删除？") },
            text = { Text("删除后将移除该预算项。") },
            confirmButton = {
                TextButton(
                    onClick = {
                        confirmDeleteId = null
                        itemsViewModel.deleteItem(id)
                    },
                ) { Text("删除") }
            },
            dismissButton = { TextButton(onClick = { confirmDeleteId = null }) { Text("取消") } },
        )
    }

    if (showItemDialog) {
        val existing = editingItem
        val isPreset = existing?.preset == true
        AlertDialog(
            onDismissRequest = { showItemDialog = false },
            title = { Text(if (existing == null) "新增预算项" else "编辑预算项") },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    OutlinedTextField(
                        modifier = Modifier.fillMaxWidth(),
                        value = itemName,
                        onValueChange = { itemName = it },
                        singleLine = true,
                        enabled = !isPreset,
                        label = { Text("名称") },
                    )

                    OutlinedTextField(
                        modifier = Modifier.fillMaxWidth(),
                        value = itemBudgetInput,
                        onValueChange = { itemBudgetInput = MoneyUtils.sanitizeAmountInput(it) },
                        singleLine = true,
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                        label = { Text("每月预算（元）") },
                        placeholder = { Text("例如：500.00") },
                    )

                    Text("包含分类（用于统计本月支出）", style = MaterialTheme.typography.bodySmall)
                    androidx.compose.foundation.lazy.LazyColumn(
                        modifier = Modifier.fillMaxWidth().height(240.dp),
                        verticalArrangement = Arrangement.spacedBy(2.dp),
                    ) {
                        items(itemsState.expenseCategories, key = { it.id }) { cat ->
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .clickable {
                                        val next = selectedCategoryIds.toMutableSet()
                                        if (next.contains(cat.id)) next.remove(cat.id) else next.add(cat.id)
                                        selectedCategoryIds = next.toSet()
                                    }
                                    .padding(vertical = 6.dp),
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.spacedBy(8.dp),
                            ) {
                                Checkbox(
                                    checked = selectedCategoryIds.contains(cat.id),
                                    onCheckedChange = {
                                        val next = selectedCategoryIds.toMutableSet()
                                        if (it) next.add(cat.id) else next.remove(cat.id)
                                        selectedCategoryIds = next.toSet()
                                    },
                                )
                                Text(cat.name, style = MaterialTheme.typography.bodyMedium)
                            }
                        }
                    }
                }
            },
            confirmButton = {
                TextButton(
                    onClick = {
                        val cents = MoneyUtils.amountInputToCents(MoneyUtils.sanitizeAmountInput(itemBudgetInput)) ?: 0L
                        val ids = selectedCategoryIds.toList().sorted()
                        if (existing == null) {
                            itemsViewModel.addItem(
                                name = itemName,
                                budgetCent = cents,
                                categoryIds = ids,
                            )
                        } else {
                            itemsViewModel.updateItem(
                                id = existing.id,
                                name = if (isPreset) existing.name else itemName,
                                budgetCent = cents,
                                categoryIds = ids,
                                preset = existing.preset,
                            )
                        }
                        showItemDialog = false
                    },
                ) { Text("保存") }
            },
            dismissButton = { TextButton(onClick = { showItemDialog = false }) { Text("取消") } },
        )
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("预算") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.Outlined.ArrowBack, contentDescription = "返回")
                    }
                },
                actions = {
                    IconButton(onClick = { openItemDialog(null) }) {
                        Icon(Icons.Outlined.Add, contentDescription = "添加预算项")
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = MaterialTheme.colorScheme.secondary),
            )
        },
    ) { inner ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(inner)
                .padding(12.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            item("total_header") {
                Text("总预算", style = MaterialTheme.typography.titleMedium)
            }

            item("total_input") {
                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    OutlinedTextField(
                        modifier = Modifier.fillMaxWidth(),
                        value = totalState.input,
                        onValueChange = totalViewModel::setInput,
                        singleLine = true,
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                        placeholder = { Text("例如：4500.00") },
                    )
                    Text(
                        text = "预览：${MoneyUtils.formatCents(totalState.inputCent)}",
                        style = MaterialTheme.typography.bodyMedium,
                    )
                    Button(
                        modifier = Modifier.fillMaxWidth(),
                        onClick = totalViewModel::save,
                        enabled = totalState.canSave,
                    ) { Text("保存总预算") }
                }
            }

            item("items_header") {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Text("预算项", style = MaterialTheme.typography.titleMedium)
                    Text(
                        text = "点击可编辑",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f),
                    )
                }
            }

            items(itemsState.items, key = { it.id }) { item ->
                ListItem(
                    modifier = Modifier.clickable { openItemDialog(item) },
                    headlineContent = { Text(item.name) },
                    supportingContent = {
                        val budgetLabel = if (item.budgetCent > 0L) MoneyUtils.formatCents(item.budgetCent) else "未设置"
                        Text("预算：$budgetLabel · 分类：${item.categoryIds.size}")
                    },
                    trailingContent = {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Icon(Icons.Outlined.Edit, contentDescription = "编辑")
                            if (!item.preset) {
                                IconButton(onClick = { confirmDeleteId = item.id }) {
                                    Icon(Icons.Outlined.Delete, contentDescription = "删除")
                                }
                            }
                        }
                    },
                )
            }

            item("footer_space") {
                Spacer(modifier = Modifier.height(12.dp))
            }
        }
    }
}

