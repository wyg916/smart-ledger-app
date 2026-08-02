package com.offline.ledger.ui.screens

import android.widget.Toast
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.ArrowBack
import androidx.compose.material.icons.outlined.Delete
import androidx.compose.material.icons.outlined.Edit
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
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
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.offline.ledger.model.TransactionType
import com.offline.ledger.ui.components.CategoryIcons
import com.offline.ledger.ui.viewmodel.TransactionDetailEvent
import com.offline.ledger.ui.viewmodel.TransactionDetailViewModel
import com.offline.ledger.utils.DateTimeUtils
import com.offline.ledger.utils.MoneyUtils

@Composable
@OptIn(ExperimentalMaterial3Api::class)
fun TransactionDetailScreen(
    onBack: () -> Unit,
    onEdit: (Long) -> Unit,
    viewModel: TransactionDetailViewModel = hiltViewModel(),
) {
    val state by viewModel.uiState.collectAsState()
    val context = androidx.compose.ui.platform.LocalContext.current
    var confirmDelete by remember { mutableStateOf(false) }

    LaunchedEffect(Unit) {
        viewModel.events.collect { event ->
            when (event) {
                TransactionDetailEvent.Deleted -> {
                    Toast.makeText(context, "已删除", Toast.LENGTH_SHORT).show()
                    onBack()
                }

                is TransactionDetailEvent.Error -> Toast.makeText(context, event.message, Toast.LENGTH_SHORT).show()
            }
        }
    }

    if (confirmDelete) {
        AlertDialog(
            onDismissRequest = { confirmDelete = false },
            title = { Text("确认删除？") },
            text = { Text("删除后将从明细与统计中移除。") },
            confirmButton = {
                TextButton(
                    onClick = {
                        confirmDelete = false
                        viewModel.delete()
                    },
                ) { Text("删除") }
            },
            dismissButton = { TextButton(onClick = { confirmDelete = false }) { Text("取消") } },
        )
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("明细") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.Outlined.ArrowBack, contentDescription = "返回")
                    }
                },
                actions = {
                    val id = state.txId
                    if (id != null && state.exists) {
                        IconButton(onClick = { onEdit(id) }) {
                            Icon(Icons.Outlined.Edit, contentDescription = "修改")
                        }
                        IconButton(onClick = { confirmDelete = true }) {
                            Icon(Icons.Outlined.Delete, contentDescription = "删除")
                        }
                    }
                },
            )
        },
    ) { inner ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(inner)
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            when {
                state.loading -> {
                    Text("加载中…", style = MaterialTheme.typography.bodyMedium)
                }

                !state.exists -> {
                    Text("记录不存在", style = MaterialTheme.typography.titleMedium)
                    Button(onClick = onBack) { Text("返回") }
                }

                else -> {
                    val sign = if (state.type == TransactionType.Expense) "-" else "+"
                    Text(
                        text = "$sign${MoneyUtils.formatCents(state.amountCent)}",
                        style = MaterialTheme.typography.displaySmall.copy(fontWeight = FontWeight.Bold),
                    )

                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(CategoryIcons.forCode(state.iconCode), contentDescription = null)
                        Spacer(modifier = Modifier.padding(horizontal = 8.dp))
                        Text(state.categoryName, style = MaterialTheme.typography.titleMedium)
                    }

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Text(
                            text = if (state.type == TransactionType.Expense) "支出" else "收入",
                            style = MaterialTheme.typography.bodyMedium,
                        )
                        Text(
                            text = DateTimeUtils.formatDateTime(state.occurredAt),
                            style = MaterialTheme.typography.bodyMedium,
                        )
                    }

                    if (state.note.isBlank()) {
                        Text("备注：无", style = MaterialTheme.typography.bodyMedium)
                    } else {
                        Text("备注：${state.note}", style = MaterialTheme.typography.bodyMedium)
                    }

                    Spacer(modifier = Modifier.height(12.dp))
                    Text("长按列表记录可修改/删除。", style = MaterialTheme.typography.bodySmall)
                }
            }
        }
    }
}

