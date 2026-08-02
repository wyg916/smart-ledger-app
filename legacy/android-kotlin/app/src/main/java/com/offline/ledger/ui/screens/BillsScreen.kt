package com.offline.ledger.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.ArrowBack
import androidx.compose.material.icons.outlined.ChevronLeft
import androidx.compose.material.icons.outlined.ChevronRight
import androidx.compose.material.icons.outlined.KeyboardArrowRight
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.offline.ledger.ui.viewmodel.BillsMonthRowUi
import com.offline.ledger.ui.viewmodel.BillsViewModel
import com.offline.ledger.utils.MoneyUtils

@Composable
@OptIn(ExperimentalMaterial3Api::class)
fun BillsScreen(
    onBack: () -> Unit,
    viewModel: BillsViewModel = hiltViewModel(),
) {
    val state by viewModel.uiState.collectAsState()

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("账单") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.Outlined.ArrowBack, contentDescription = "返回")
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
            item("year") {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    IconButton(onClick = viewModel::prevYear) {
                        Icon(Icons.Outlined.ChevronLeft, contentDescription = "上一年")
                    }
                    Text(
                        text = "${state.year}年",
                        style = MaterialTheme.typography.titleLarge,
                    )
                    IconButton(onClick = viewModel::nextYear) {
                        Icon(Icons.Outlined.ChevronRight, contentDescription = "下一年")
                    }
                }
            }

            item("summary") {
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(16.dp),
                    colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.primary),
                ) {
                    Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        Text("年结余", style = MaterialTheme.typography.bodyMedium)
                        Text(
                            MoneyUtils.formatCents(state.yearBalanceCent),
                            style = MaterialTheme.typography.displaySmall.copy(fontWeight = FontWeight.Bold),
                        )
                        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                            Text("年收入 ${MoneyUtils.formatCents(state.yearIncomeCent)}", style = MaterialTheme.typography.bodyMedium)
                            Text("年支出 ${MoneyUtils.formatCents(state.yearExpenseCent)}", style = MaterialTheme.typography.bodyMedium)
                        }
                    }
                }
            }

            item("header") {
                Row(
                    modifier = Modifier.fillMaxWidth().padding(horizontal = 4.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                ) {
                    Text("月份", style = MaterialTheme.typography.bodySmall)
                    Text("月收入", style = MaterialTheme.typography.bodySmall)
                    Text("月支出", style = MaterialTheme.typography.bodySmall)
                    Text("月结余", style = MaterialTheme.typography.bodySmall)
                }
                Spacer(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(1.dp)
                        .background(MaterialTheme.colorScheme.onSurface.copy(alpha = 0.08f)),
                )
            }

            items(state.months, key = { it.month }) { row ->
                MonthRow(row)
            }
        }
    }
}

@Composable
private fun MonthRow(row: BillsMonthRowUi) {
    Row(
        modifier = Modifier.fillMaxWidth().padding(vertical = 6.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.SpaceBetween,
    ) {
        Text("${row.month}月", style = MaterialTheme.typography.bodyMedium)
        Text(MoneyUtils.formatCents(row.incomeCent), style = MaterialTheme.typography.bodyMedium)
        Text(MoneyUtils.formatCents(row.expenseCent), style = MaterialTheme.typography.bodyMedium)
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(MoneyUtils.formatCents(row.balanceCent), style = MaterialTheme.typography.bodyMedium)
            Spacer(modifier = Modifier.width(4.dp))
            Icon(Icons.Outlined.KeyboardArrowRight, contentDescription = null)
        }
    }
}

