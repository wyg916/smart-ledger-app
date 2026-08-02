package com.offline.ledger.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.clickable
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.ChevronLeft
import androidx.compose.material.icons.outlined.ChevronRight
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.ListItem
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.offline.ledger.model.TransactionType
import com.offline.ledger.ui.components.CategoryIcons
import com.offline.ledger.ui.viewmodel.DetailsDayGroupUi
import com.offline.ledger.ui.viewmodel.DetailsViewModel
import com.offline.ledger.utils.MoneyUtils
import java.time.format.DateTimeFormatter
import java.util.Locale

@Composable
@OptIn(ExperimentalMaterial3Api::class, ExperimentalFoundationApi::class)
fun DetailsScreen(
    onAdd: () -> Unit,
    onOpen: (Long) -> Unit,
    onEdit: (Long) -> Unit,
) {
    val viewModel: DetailsViewModel = hiltViewModel()
    val state = viewModel.uiState.collectAsState().value

    var pendingDeleteId: Long? by remember { mutableStateOf(null) }
    var showCategoryDialog by remember { mutableStateOf(false) }
    var actionsForTxId: Long? by remember { mutableStateOf(null) }

    if (actionsForTxId != null) {
        val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
        ModalBottomSheet(
            onDismissRequest = { actionsForTxId = null },
            sheetState = sheetState,
        ) {
            val id = actionsForTxId ?: return@ModalBottomSheet
            ListItem(
                headlineContent = { Text("查看明细") },
                modifier = Modifier.clickable {
                    actionsForTxId = null
                    onOpen(id)
                },
            )
            ListItem(
                headlineContent = { Text("修改") },
                modifier = Modifier.clickable {
                    actionsForTxId = null
                    onEdit(id)
                },
            )
            ListItem(
                headlineContent = { Text("删除") },
                modifier = Modifier.clickable {
                    actionsForTxId = null
                    pendingDeleteId = id
                },
            )
            Spacer(modifier = Modifier.height(24.dp))
        }
    }

    if (pendingDeleteId != null) {
        AlertDialog(
            onDismissRequest = { pendingDeleteId = null },
            confirmButton = {
                androidx.compose.material3.TextButton(
                    onClick = {
                        val id = pendingDeleteId
                        if (id != null) viewModel.deleteTransaction(id)
                        pendingDeleteId = null
                    },
                ) { Text("删除") }
            },
            dismissButton = {
                androidx.compose.material3.TextButton(onClick = { pendingDeleteId = null }) { Text("取消") }
            },
            title = { Text("确认删除？") },
            text = { Text("删除后将从明细与统计中移除。") },
        )
    }

    if (showCategoryDialog) {
        val candidates = state.allCategories.filter { state.filterType == null || it.type == state.filterType }
        AlertDialog(
            onDismissRequest = { showCategoryDialog = false },
            title = { Text("选择分类") },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                    TextButton(
                        onClick = {
                            viewModel.setCategoryId(null)
                            showCategoryDialog = false
                        },
                    ) { Text("全部分类") }
                    androidx.compose.foundation.lazy.LazyColumn(
                        modifier = Modifier.fillMaxWidth().height(320.dp),
                    ) {
                        items(candidates, key = { it.id }) { cat ->
                            TextButton(
                                modifier = Modifier.fillMaxWidth(),
                                onClick = {
                                    viewModel.setCategoryId(cat.id)
                                    showCategoryDialog = false
                                },
                            ) { Text(cat.name) }
                        }
                    }
                }
            },
            confirmButton = { TextButton(onClick = { showCategoryDialog = false }) { Text("关闭") } },
        )
    }

    Column(modifier = Modifier.fillMaxSize().padding(12.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            IconButton(onClick = viewModel::prevMonth) {
                Icon(Icons.Outlined.ChevronLeft, contentDescription = "上月")
            }
            Text(
                text = "${state.yearMonth.year}-${state.yearMonth.monthValue.toString().padStart(2, '0')}",
                style = MaterialTheme.typography.titleLarge,
            )
            IconButton(onClick = viewModel::nextMonth) {
                Icon(Icons.Outlined.ChevronRight, contentDescription = "下月")
            }
        }

        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(12.dp),
            verticalAlignment = Alignment.Top,
        ) {
            FilterChip(
                selected = state.filterType == null,
                onClick = { viewModel.setFilterType(null) },
                label = { Text("全部") },
            )

            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                FilterChip(
                    selected = state.filterType == TransactionType.Expense,
                    onClick = { viewModel.setFilterType(TransactionType.Expense) },
                    label = { Text("支出") },
                )
                Text(
                    text = MoneyUtils.formatCents(state.expenseTotalCent),
                    style = MaterialTheme.typography.bodySmall,
                )
            }

            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                FilterChip(
                    selected = state.filterType == TransactionType.Income,
                    onClick = { viewModel.setFilterType(TransactionType.Income) },
                    label = { Text("收入") },
                )
                Text(
                    text = MoneyUtils.formatCents(state.incomeTotalCent),
                    style = MaterialTheme.typography.bodySmall,
                )
            }
        }

        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            val selectedCategoryName = state.filterCategoryId?.let { id ->
                state.allCategories.firstOrNull { it.id == id }?.name
            } ?: "全部分类"
            FilterChip(
                selected = state.filterCategoryId != null,
                onClick = { showCategoryDialog = true },
                label = { Text(selectedCategoryName) },
            )
            FilterChip(
                selected = state.filterCategoryId == null,
                onClick = { viewModel.setCategoryId(null) },
                label = { Text("清除分类") },
            )
        }

        OutlinedTextField(
            modifier = Modifier.fillMaxWidth(),
            value = state.filterKeyword,
            onValueChange = viewModel::setKeyword,
            singleLine = true,
            label = { Text("搜索备注") },
        )

        LazyColumn(
            modifier = Modifier.fillMaxSize(),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            state.dayGroups.forEach { group ->
                item(key = "header-${group.day}") {
                    DayHeader(group)
                }
                items(group.items, key = { it.id }) { item ->
                    ListItem(
                        modifier = Modifier.combinedClickable(
                            onClick = { onOpen(item.id) },
                            onLongClick = { actionsForTxId = item.id },
                        ),
                        leadingContent = { Icon(CategoryIcons.forCode(item.iconCode), contentDescription = null) },
                        headlineContent = { Text(item.categoryName) },
                        supportingContent = {
                            val dt = java.time.Instant.ofEpochMilli(item.occurredAt)
                                .atZone(java.time.ZoneId.systemDefault())
                                .toLocalTime()
                                .format(DateTimeFormatter.ofPattern("HH:mm", Locale.getDefault()))
                            val note = item.note.takeIf { it.isNotBlank() }
                            Text(if (note == null) dt else "$dt · $note")
                        },
                        trailingContent = {
                            val sign = if (item.type == TransactionType.Expense) "-" else "+"
                            Text(
                                text = "$sign${MoneyUtils.formatCents(item.amountCent)}",
                                style = MaterialTheme.typography.titleMedium,
                            )
                        },
                    )
                }
            }
            if (state.dayGroups.isEmpty()) {
                item("empty") {
                    Column(
                        modifier = Modifier.fillMaxWidth().padding(top = 48.dp),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(8.dp),
                    ) {
                        Text("本月暂无记录", style = MaterialTheme.typography.titleMedium)
                        Text("点击中间 + 记一笔", style = MaterialTheme.typography.bodyMedium)
                        Button(onClick = onAdd) { Text("记一笔") }
                    }
                }
            }
        }
    }
}

@Composable
private fun DayHeader(group: DetailsDayGroupUi) {
    val label = group.day.format(DateTimeFormatter.ofPattern("MM-dd E", Locale.getDefault()))
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Text(text = label, style = MaterialTheme.typography.titleMedium)
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            if (group.expenseTotalCent > 0) {
                Text(text = "支出 ${MoneyUtils.formatCents(group.expenseTotalCent)}", style = MaterialTheme.typography.bodyMedium)
            }
            if (group.incomeTotalCent > 0) {
                Text(text = "收入 ${MoneyUtils.formatCents(group.incomeTotalCent)}", style = MaterialTheme.typography.bodyMedium)
            }
        }
    }
    Spacer(modifier = Modifier.height(4.dp))
}
