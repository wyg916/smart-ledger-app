package com.offline.ledger.ui.screens

import android.widget.Toast
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.CalendarToday
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material.icons.outlined.Delete
import androidx.compose.material.icons.outlined.KeyboardBackspace
import androidx.compose.material.icons.outlined.Settings
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.DatePicker
import androidx.compose.material3.DatePickerDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FilledTonalButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
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
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.offline.ledger.data.db.entity.CategoryEntity
import com.offline.ledger.model.TransactionType
import com.offline.ledger.ui.components.CategoryIcons
import com.offline.ledger.ui.viewmodel.AddTransactionEvent
import com.offline.ledger.ui.viewmodel.AddTransactionViewModel
import com.offline.ledger.utils.DateTimeUtils
import java.time.ZoneOffset
import java.time.format.DateTimeFormatter
import java.util.Locale

@Composable
@OptIn(ExperimentalMaterial3Api::class)
fun AddTransactionScreen(
    onClose: () -> Unit,
    onOpenCategories: () -> Unit,
    viewModel: AddTransactionViewModel = hiltViewModel(),
) {
    val state by viewModel.uiState.collectAsState()
    val context = androidx.compose.ui.platform.LocalContext.current
    var showDatePicker by remember { mutableStateOf(false) }
    var showDeleteConfirm by remember { mutableStateOf(false) }
    var showKeypad by remember { mutableStateOf(false) }

    LaunchedEffect(state.editingId) {
        if (state.editingId != null) showKeypad = true
    }

    LaunchedEffect(Unit) {
        viewModel.events.collect { event ->
            when (event) {
                AddTransactionEvent.Saved -> {
                    val editing = viewModel.uiState.value.editingId != null
                    Toast.makeText(context, if (editing) "已保存" else "已记录", Toast.LENGTH_SHORT).show()
                    if (editing) onClose()
                }

                AddTransactionEvent.Deleted -> {
                    Toast.makeText(context, "已删除", Toast.LENGTH_SHORT).show()
                    onClose()
                }

                is AddTransactionEvent.Error -> Toast.makeText(context, event.message, Toast.LENGTH_SHORT).show()
            }
        }
    }

    if (showDeleteConfirm) {
        AlertDialog(
            onDismissRequest = { showDeleteConfirm = false },
            title = { Text("确认删除？") },
            text = { Text("删除后将从明细与统计中移除。") },
            confirmButton = {
                TextButton(
                    onClick = {
                        showDeleteConfirm = false
                        viewModel.deleteEditing()
                    },
                ) { Text("删除") }
            },
            dismissButton = { TextButton(onClick = { showDeleteConfirm = false }) { Text("取消") } },
        )
    }

    if (showDatePicker) {
        val initialUtcMillis =
            DateTimeUtils.localDateFromMillis(state.occurredAt)
                .atStartOfDay(ZoneOffset.UTC)
                .toInstant()
                .toEpochMilli()
        val datePickerState = androidx.compose.material3.rememberDatePickerState(
            initialSelectedDateMillis = initialUtcMillis,
        )
        DatePickerDialog(
            onDismissRequest = { showDatePicker = false },
            confirmButton = {
                TextButton(
                    onClick = {
                        val selectedUtc = datePickerState.selectedDateMillis
                        if (selectedUtc != null) {
                            val date = DateTimeUtils.localDateFromUtcMillis(selectedUtc)
                            val time = DateTimeUtils.localDateTimeFromMillis(state.occurredAt).toLocalTime()
                            viewModel.setOccurredAt(DateTimeUtils.millisFromLocalDateTime(date, time))
                        }
                        showDatePicker = false
                    },
                ) { Text("确定") }
            },
            dismissButton = { TextButton(onClick = { showDatePicker = false }) { Text("取消") } },
        ) {
            DatePicker(state = datePickerState)
        }
    }

    val today = DateTimeUtils.localDateFromMillis(System.currentTimeMillis())
    val selectedDate = DateTimeUtils.localDateFromMillis(state.occurredAt)
    val dateLabel = if (selectedDate == today) {
        "今天"
    } else {
        selectedDate.format(DateTimeFormatter.ofPattern("MM-dd", Locale.getDefault()))
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
                        FilterChip(
                            selected = state.type == TransactionType.Expense,
                            onClick = { viewModel.setType(TransactionType.Expense) },
                            label = { Text("支出") },
                        )
                        FilterChip(
                            selected = state.type == TransactionType.Income,
                            onClick = { viewModel.setType(TransactionType.Income) },
                            label = { Text("收入") },
                        )
                    }
                },
                navigationIcon = {
                    IconButton(onClick = onClose) {
                        Icon(Icons.Outlined.Close, contentDescription = "取消")
                    }
                },
                actions = {
                    IconButton(onClick = onOpenCategories) {
                        Icon(Icons.Outlined.Settings, contentDescription = "类别设置")
                    }
                    if (state.editingId != null) {
                        IconButton(onClick = { showDeleteConfirm = true }) {
                            Icon(Icons.Outlined.Delete, contentDescription = "删除")
                        }
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = MaterialTheme.colorScheme.secondary),
            )
        },
        bottomBar = {
            AnimatedVisibility(
                visible = showKeypad,
                enter = slideInVertically { it },
                exit = slideOutVertically { it },
            ) {
                KeypadPanel(
                    amountText = state.amountInput.ifBlank { "0.00" },
                    dateLabel = dateLabel,
                    onPickDate = { showDatePicker = true },
                    note = state.note,
                    onNoteChange = viewModel::setNote,
                    onDigit = viewModel::pressDigit,
                    onDot = viewModel::pressDot,
                    onBackspace = viewModel::backspace,
                    onClear = viewModel::clearAmount,
                    onSubmit = viewModel::submit,
                    submitEnabled = state.canSubmit,
                )
            }

            AnimatedVisibility(
                visible = !showKeypad,
                enter = slideInVertically { it },
                exit = slideOutVertically { it },
            ) {
                HintBar(
                    onClick = { showKeypad = true },
                )
            }
        },
    ) { inner ->
        if (state.categories.isEmpty()) {
            Box(
                modifier = Modifier.fillMaxSize().padding(inner).padding(16.dp),
                contentAlignment = Alignment.Center,
            ) {
                Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text("暂无分类", style = MaterialTheme.typography.titleMedium)
                    Button(onClick = onOpenCategories) { Text("去添加分类") }
                }
            }
            return@Scaffold
        }

        LazyVerticalGrid(
            columns = GridCells.Fixed(4),
            modifier = Modifier
                .fillMaxSize()
                .padding(inner)
                .padding(horizontal = 12.dp),
            contentPadding = PaddingValues(top = 12.dp, bottom = 12.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
            horizontalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            items(state.categories, key = { it.id }) { cat ->
                CategoryGridItem(
                    category = cat,
                    selected = cat.id == state.selectedCategoryId,
                    onClick = {
                        viewModel.selectCategory(cat.id)
                        showKeypad = true
                    },
                )
            }
        }
    }
}

@Composable
private fun HintBar(
    onClick: () -> Unit,
) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .background(MaterialTheme.colorScheme.surface)
            .clickable(onClick = onClick)
            .padding(horizontal = 16.dp, vertical = 14.dp),
        contentAlignment = Alignment.CenterStart,
    ) {
        Text("点击一个类别开始记账", style = MaterialTheme.typography.bodyMedium)
    }
}

@Composable
private fun CategoryGridItem(
    category: CategoryEntity,
    selected: Boolean,
    onClick: () -> Unit,
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        val bg = if (selected) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.surfaceVariant
        Box(
            modifier = Modifier
                .size(56.dp)
                .background(bg, CircleShape),
            contentAlignment = Alignment.Center,
        ) {
            Icon(
                imageVector = CategoryIcons.forCode(category.iconCode),
                contentDescription = category.name,
            )
        }
        Text(
            text = category.name,
            style = MaterialTheme.typography.bodySmall,
            textAlign = TextAlign.Center,
        )
    }
}

@Composable
private fun KeypadPanel(
    amountText: String,
    dateLabel: String,
    onPickDate: () -> Unit,
    note: String,
    onNoteChange: (String) -> Unit,
    onDigit: (Int) -> Unit,
    onDot: () -> Unit,
    onBackspace: () -> Unit,
    onClear: () -> Unit,
    onSubmit: () -> Unit,
    submitEnabled: Boolean,
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .background(MaterialTheme.colorScheme.surface)
            .padding(12.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            FilledTonalButton(onClick = onPickDate) {
                Icon(Icons.Outlined.CalendarToday, contentDescription = null)
                Spacer(modifier = Modifier.padding(horizontal = 4.dp))
                Text(dateLabel)
            }
            Spacer(modifier = Modifier.weight(1f))
            Text(
                text = amountText,
                style = MaterialTheme.typography.headlineLarge.copy(fontWeight = FontWeight.Bold),
                textAlign = TextAlign.End,
            )
        }

        OutlinedTextField(
            modifier = Modifier.fillMaxWidth(),
            value = note,
            onValueChange = onNoteChange,
            singleLine = true,
            placeholder = { Text("备注：点击填写备注") },
        )

        AmountKeypad(
            onDigit = onDigit,
            onDot = onDot,
            onBackspace = onBackspace,
            onClear = onClear,
            onSubmit = onSubmit,
            submitEnabled = submitEnabled,
        )
    }
}

@Composable
private fun AmountKeypad(
    onDigit: (Int) -> Unit,
    onDot: () -> Unit,
    onBackspace: () -> Unit,
    onClear: () -> Unit,
    onSubmit: () -> Unit,
    submitEnabled: Boolean,
) {
    Column(
        modifier = Modifier.fillMaxWidth(),
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        val rows = listOf(
            listOf("7", "8", "9"),
            listOf("4", "5", "6"),
            listOf("1", "2", "3"),
            listOf(".", "0", "⌫"),
        )
        rows.forEach { row ->
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                row.forEach { key ->
                    FilledTonalButton(
                        modifier = Modifier.weight(1f).height(52.dp),
                        onClick = {
                            when (key) {
                                "." -> onDot()
                                "⌫" -> onBackspace()
                                else -> onDigit(key.toInt())
                            }
                        },
                    ) {
                        if (key == "⌫") {
                            Icon(Icons.Outlined.KeyboardBackspace, contentDescription = "删除")
                        } else {
                            Text(key, style = MaterialTheme.typography.titleMedium)
                        }
                    }
                }
            }
        }

        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            FilledTonalButton(
                modifier = Modifier.weight(1f).height(52.dp),
                onClick = onClear,
            ) {
                Text("清空")
            }
            Button(
                modifier = Modifier.weight(1f).height(52.dp),
                enabled = submitEnabled,
                onClick = onSubmit,
            ) {
                Text("完成")
            }
        }
    }
}
