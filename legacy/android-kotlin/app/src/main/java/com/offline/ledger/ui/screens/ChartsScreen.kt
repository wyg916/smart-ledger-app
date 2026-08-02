package com.offline.ledger.ui.screens

import android.graphics.Paint
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
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
import androidx.compose.material3.FilterChip
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.drawIntoCanvas
import androidx.compose.ui.graphics.nativeCanvas
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.offline.ledger.data.db.model.CategorySummaryRow
import com.offline.ledger.model.TransactionType
import com.offline.ledger.ui.components.CategoryIcons
import com.offline.ledger.ui.viewmodel.ChartsRange
import com.offline.ledger.ui.viewmodel.ChartsViewModel
import com.offline.ledger.utils.MoneyUtils
import java.time.LocalDate
import java.time.YearMonth
import java.time.format.DateTimeFormatter
import java.util.Locale
import kotlin.math.max

private data class TrendPoint(
    val label: String,
    val valueCent: Long,
)

@Composable
fun ChartsScreen() {
    val viewModel: ChartsViewModel = hiltViewModel()
    val state = viewModel.uiState.collectAsState().value

    val today = remember { LocalDate.now() }
    val points = remember(state.range, state.type, state.daily) {
        buildTrendPoints(
            range = state.range,
            type = state.type,
            dailyRows = state.daily,
            today = today,
        )
    }

    val xLabelEvery = when (points.size) {
        in 0..8 -> 1
        in 9..16 -> 2
        in 17..32 -> 5
        else -> max(1, points.size / 6)
    }
    val valueLabelEvery = when (points.size) {
        in 0..12 -> 1
        in 13..32 -> 7
        else -> max(1, points.size / 8)
    }

    LazyColumn(
        modifier = Modifier.fillMaxSize().padding(12.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        item {
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
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
        }

        item {
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                FilterChip(
                    selected = state.range == ChartsRange.Week,
                    onClick = { viewModel.setRange(ChartsRange.Week) },
                    label = { Text("周") },
                )
                FilterChip(
                    selected = state.range == ChartsRange.Month,
                    onClick = { viewModel.setRange(ChartsRange.Month) },
                    label = { Text("月") },
                )
                FilterChip(
                    selected = state.range == ChartsRange.Year,
                    onClick = { viewModel.setRange(ChartsRange.Year) },
                    label = { Text("年") },
                )
            }
        }

        item {
            Text(
                text = "总额：${MoneyUtils.formatCents(state.totalCent)}",
                style = MaterialTheme.typography.headlineSmall,
            )
        }

        item {
            Text(text = "趋势", style = MaterialTheme.typography.titleMedium)
            TrendLineChart(
                points = points,
                xLabelEvery = xLabelEvery,
                valueLabelEvery = valueLabelEvery,
                modifier = Modifier.fillMaxWidth().height(220.dp),
            )
        }

        item {
            Text(text = "分类排行 Top10", style = MaterialTheme.typography.titleMedium)
        }

        if (state.categories.isEmpty()) {
            item {
                Text("暂无数据", style = MaterialTheme.typography.bodyMedium)
            }
        } else {
            items(state.categories, key = { it.categoryId }) { row ->
                CategoryBarRow(
                    row = row,
                    maxCent = state.categories.firstOrNull()?.totalCent ?: 0L,
                    totalCent = state.totalCent,
                )
            }
            item { Spacer(modifier = Modifier.height(12.dp)) }
        }
    }
}

private fun buildTrendPoints(
    range: ChartsRange,
    type: Int,
    dailyRows: List<com.offline.ledger.data.db.model.DailySummaryRow>,
    today: LocalDate,
): List<TrendPoint> {
    val dayMap: Map<LocalDate, Long> = dailyRows.associate { row ->
        val d = LocalDate.parse(row.day)
        val v = if (type == TransactionType.Expense) row.expenseCent else row.incomeCent
        d to v
    }

    return when (range) {
        ChartsRange.Week -> {
            val fmt = DateTimeFormatter.ofPattern("MM-dd", Locale.getDefault())
            (0..6).map { offset ->
                val d = today.minusDays((6 - offset).toLong())
                TrendPoint(label = d.format(fmt), valueCent = dayMap[d] ?: 0L)
            }
        }

        ChartsRange.Month -> {
            val ym = YearMonth.from(today)
            (1..ym.lengthOfMonth()).map { day ->
                val d = ym.atDay(day)
                TrendPoint(label = day.toString(), valueCent = dayMap[d] ?: 0L)
            }
        }

        ChartsRange.Year -> {
            val byMonth = dailyRows.groupBy { YearMonth.from(LocalDate.parse(it.day)) }
                .mapValues { (_, rows) ->
                    rows.sumOf { r -> if (type == TransactionType.Expense) r.expenseCent else r.incomeCent }
                }
            (1..12).map { month ->
                val ym = YearMonth.of(today.year, month)
                TrendPoint(label = "${month}月", valueCent = byMonth[ym] ?: 0L)
            }
        }
    }
}

@Composable
private fun TrendLineChart(
    points: List<TrendPoint>,
    xLabelEvery: Int,
    valueLabelEvery: Int,
    modifier: Modifier = Modifier,
) {
    val primary = MaterialTheme.colorScheme.primary
    val axisColor = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.35f)
    val gridColor = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.12f)
    val labelColor = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.65f)

    val textPaint = remember(labelColor) {
        Paint().apply {
            isAntiAlias = true
            color = labelColor.toArgb()
            textSize = 11f * android.content.res.Resources.getSystem().displayMetrics.scaledDensity
        }
    }

    val valuePaint = remember(primary) {
        Paint().apply {
            isAntiAlias = true
            color = primary.toArgb()
            textSize = 10f * android.content.res.Resources.getSystem().displayMetrics.scaledDensity
        }
    }

    Canvas(modifier = modifier) {
        if (points.isEmpty()) return@Canvas

        val leftPad = 56.dp.toPx()
        val rightPad = 12.dp.toPx()
        val topPad = 12.dp.toPx()
        val bottomPad = 28.dp.toPx()

        val chartW = size.width - leftPad - rightPad
        val chartH = size.height - topPad - bottomPad
        if (chartW <= 0f || chartH <= 0f) return@Canvas

        val x0 = leftPad
        val y0 = topPad + chartH

        val maxVal = points.maxOf { it.valueCent }.coerceAtLeast(0L)
        val yMax = if (maxVal == 0L) 1L else maxVal

        // Axes
        drawLine(color = axisColor, start = Offset(x0, topPad), end = Offset(x0, y0), strokeWidth = 1.dp.toPx())
        drawLine(color = axisColor, start = Offset(x0, y0), end = Offset(x0 + chartW, y0), strokeWidth = 1.dp.toPx())

        // Y ticks + grid
        val ticks = 4
        for (i in 0..ticks) {
            val t = i / ticks.toFloat()
            val y = topPad + chartH * t
            drawLine(
                color = gridColor,
                start = Offset(x0, y),
                end = Offset(x0 + chartW, y),
                strokeWidth = 1.dp.toPx(),
            )

            val v = (yMax * (ticks - i) / ticks.toLong())
            val label = MoneyUtils.formatCents(v)
            drawIntoCanvas { c ->
                val w = textPaint.measureText(label)
                c.nativeCanvas.drawText(label, x0 - 6.dp.toPx() - w, y + 4.dp.toPx(), textPaint)
            }
        }

        val stepX = if (points.size <= 1) 0f else chartW / (points.size - 1)
        fun pointToOffset(index: Int): Offset {
            val x = x0 + stepX * index
            val v = points[index].valueCent
            val ratio = v.toFloat() / yMax.toFloat()
            val y = y0 - ratio * chartH
            return Offset(x, y)
        }

        val path = Path()
        points.indices.forEach { i ->
            val p = pointToOffset(i)
            if (i == 0) path.moveTo(p.x, p.y) else path.lineTo(p.x, p.y)
        }
        drawPath(
            path = path,
            color = primary,
            style = Stroke(width = 3.dp.toPx(), cap = StrokeCap.Round),
        )

        // Points + value labels
        points.indices.forEach { i ->
            val p = pointToOffset(i)
            drawCircle(color = primary, radius = 4.dp.toPx(), center = p)

            val shouldLabel = valueLabelEvery > 0 && (i % valueLabelEvery == 0 || i == points.lastIndex)
            if (shouldLabel) {
                val label = MoneyUtils.formatCents(points[i].valueCent)
                drawIntoCanvas { c ->
                    val w = valuePaint.measureText(label)
                    c.nativeCanvas.drawText(label, p.x - w / 2, p.y - 8.dp.toPx(), valuePaint)
                }
            }
        }

        // X labels
        points.indices.forEach { i ->
            val show = xLabelEvery > 0 && (i % xLabelEvery == 0 || i == points.lastIndex)
            if (!show) return@forEach
            val p = pointToOffset(i)
            val label = points[i].label
            drawIntoCanvas { c ->
                val w = textPaint.measureText(label)
                c.nativeCanvas.drawText(label, p.x - w / 2, y0 + 20.dp.toPx(), textPaint)
            }
        }
    }
}

@Composable
private fun CategoryBarRow(
    row: CategorySummaryRow,
    maxCent: Long,
    totalCent: Long,
) {
    val primary = MaterialTheme.colorScheme.primary
    val track = MaterialTheme.colorScheme.surfaceVariant

    val frac = if (maxCent <= 0L) 0f else (row.totalCent.toFloat() / maxCent.toFloat()).coerceIn(0f, 1f)
    val percent = if (totalCent <= 0L) 0.0 else (row.totalCent.toDouble() / totalCent.toDouble() * 100.0)

    Row(
        modifier = Modifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        androidx.compose.material3.Icon(
            imageVector = CategoryIcons.forCode(row.iconCode),
            contentDescription = null,
        )

        Text(
            text = row.categoryName,
            modifier = Modifier.weight(0.35f),
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
        )

        Row(
            modifier = Modifier.weight(0.45f),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            androidx.compose.foundation.layout.Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(12.dp)
                    .background(track, shape = MaterialTheme.shapes.small),
            ) {
                androidx.compose.foundation.layout.Box(
                    modifier = Modifier
                        .fillMaxWidth(frac)
                        .height(12.dp)
                        .background(primary, shape = MaterialTheme.shapes.small),
                )
            }
        }

        Column(
            modifier = Modifier.weight(0.20f),
            horizontalAlignment = Alignment.End,
        ) {
            Text(
                text = MoneyUtils.formatCents(row.totalCent),
                style = MaterialTheme.typography.bodyMedium,
                maxLines = 1,
            )
            Text(
                text = String.format(Locale.getDefault(), "%.1f%%", percent),
                style = MaterialTheme.typography.bodySmall,
                maxLines = 1,
            )
        }
    }
}
