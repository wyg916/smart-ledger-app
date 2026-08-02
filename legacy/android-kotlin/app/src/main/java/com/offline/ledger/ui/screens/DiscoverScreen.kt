package com.offline.ledger.ui.screens

import androidx.compose.foundation.Canvas
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
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.ChevronRight
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
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
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.offline.ledger.ui.viewmodel.DiscoverViewModel
import com.offline.ledger.utils.MoneyUtils
import java.util.Locale

@Composable
@OptIn(ExperimentalMaterial3Api::class)
fun DiscoverScreen(
    onOpenBills: () -> Unit,
    onOpenBudget: () -> Unit,
    onOpenBudgetItem: (String) -> Unit,
    viewModel: DiscoverViewModel = hiltViewModel(),
) {
    val state by viewModel.uiState.collectAsState()
    val ym = state.yearMonth
    val monthLabel = String.format(Locale.getDefault(), "%02d月", ym.monthValue)

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("发现") },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = MaterialTheme.colorScheme.secondary),
            )
        },
    ) { inner ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(inner),
            contentPadding = PaddingValues(12.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            item {
                BillsCard(
                    monthLabel = monthLabel,
                    incomeCent = state.monthIncomeCent,
                    expenseCent = state.monthExpenseCent,
                    balanceCent = state.monthBalanceCent,
                    onClick = onOpenBills,
                )
            }

            item {
                BudgetCard(
                    title = "${monthLabel}总预算",
                    remainingRatio = state.budgetRemainingRatio,
                    budgetSet = state.budgetCent > 0L,
                    remainingCent = state.budgetRemainingCent,
                    budgetCent = state.budgetCent,
                    spentCent = state.monthExpenseCent,
                    onClick = onOpenBudget,
                )
            }

            items(state.budgetItems, key = { it.id }) { item ->
                BudgetCard(
                    title = item.name,
                    remainingRatio = item.remainingRatio,
                    budgetSet = item.budgetCent > 0L,
                    remainingCent = item.remainingCent,
                    budgetCent = item.budgetCent,
                    spentCent = item.spentCent,
                    onClick = { onOpenBudgetItem(item.id) },
                )
            }

            item {
                Box(modifier = Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
                    Text(
                        text = "+ 添加预算项",
                        modifier = Modifier
                            .clickable(onClick = onOpenBudget)
                            .padding(8.dp),
                        color = MaterialTheme.colorScheme.primary,
                        style = MaterialTheme.typography.bodyMedium,
                    )
                }
            }
        }
    }
}

@Composable
private fun BillsCard(
    monthLabel: String,
    incomeCent: Long,
    expenseCent: Long,
    balanceCent: Long,
    onClick: () -> Unit,
) {
    Card(
        modifier = Modifier.fillMaxWidth().clickable(onClick = onClick),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
    ) {
        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text("账单", style = MaterialTheme.typography.titleMedium)
                Icon(Icons.Outlined.ChevronRight, contentDescription = null)
            }

            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                Text(
                    text = monthLabel,
                    style = MaterialTheme.typography.headlineMedium.copy(fontWeight = FontWeight.Bold),
                )
                Box(
                    modifier = Modifier
                        .height(42.dp)
                        .size(1.dp)
                        .background(MaterialTheme.colorScheme.onSurface.copy(alpha = 0.12f)),
                )

                SummaryItem("收入", incomeCent)
                SummaryItem("支出", expenseCent)
                SummaryItem("结余", balanceCent)
            }
        }
    }
}

@Composable
private fun BudgetCard(
    title: String,
    remainingRatio: Float,
    budgetSet: Boolean,
    remainingCent: Long,
    budgetCent: Long,
    spentCent: Long,
    onClick: () -> Unit,
) {
    Card(
        modifier = Modifier.fillMaxWidth().clickable(onClick = onClick),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
    ) {
        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(title, style = MaterialTheme.typography.titleMedium)
                Icon(Icons.Outlined.ChevronRight, contentDescription = null)
            }

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(16.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                BudgetRing(
                    modifier = Modifier.size(84.dp),
                    remainingRatio = remainingRatio,
                    budgetSet = budgetSet,
                )

                Column(
                    modifier = Modifier.weight(1f),
                    verticalArrangement = Arrangement.spacedBy(8.dp),
                ) {
                    val remainingLabel = if (budgetSet) MoneyUtils.formatCents(remainingCent) else "--"
                    val totalLabel = if (budgetSet) MoneyUtils.formatCents(budgetCent) else "未设置"
                    Text("剩余预算：$remainingLabel", style = MaterialTheme.typography.bodyMedium)
                    Text("本月预算：$totalLabel", style = MaterialTheme.typography.bodyMedium)
                    Text("本月支出：${MoneyUtils.formatCents(spentCent)}", style = MaterialTheme.typography.bodyMedium)
                }
            }
        }
    }
}

@Composable
private fun SummaryItem(
    label: String,
    valueCent: Long,
) {
    Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(4.dp)) {
        Text(label, style = MaterialTheme.typography.bodySmall)
        Text(MoneyUtils.formatCents(valueCent), style = MaterialTheme.typography.bodyMedium)
    }
}

@Composable
private fun BudgetRing(
    modifier: Modifier,
    remainingRatio: Float,
    budgetSet: Boolean,
) {
    val primary = MaterialTheme.colorScheme.primary
    val track = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.12f)

    Box(modifier = modifier.clip(RoundedCornerShape(999.dp)), contentAlignment = Alignment.Center) {
        Canvas(modifier = Modifier.fillMaxSize()) {
            val stroke = Stroke(width = 10.dp.toPx(), cap = StrokeCap.Round)
            drawArc(
                color = track,
                startAngle = -90f,
                sweepAngle = 360f,
                useCenter = false,
                style = stroke,
            )
            if (budgetSet) {
                drawArc(
                    color = primary,
                    startAngle = -90f,
                    sweepAngle = 360f * remainingRatio.coerceIn(0f, 1f),
                    useCenter = false,
                    style = stroke,
                )
            }
        }

        val percentText = if (!budgetSet) "--" else String.format(Locale.getDefault(), "%.0f%%", remainingRatio * 100f)
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Text("剩余", style = MaterialTheme.typography.bodySmall, textAlign = TextAlign.Center)
            Text(percentText, style = MaterialTheme.typography.titleMedium, textAlign = TextAlign.Center)
        }
    }
}
