package com.offline.ledger.export

import java.util.zip.ZipInputStream
import org.junit.Assert.assertTrue
import org.junit.Test

class XlsxExporterTest {
    @Test
    fun export_containsExpectedEntries() {
        val bytes = XlsxExporter.export(
            details = listOf(
                ExportTransactionRow(
                    dateTime = "2026-02-09 12:00",
                    type = "支出",
                    category = "餐饮",
                    amountNumber = "12.34",
                    note = "a&b <test>",
                ),
            ),
            categorySummary = listOf(
                ExportCategorySummaryRow(
                    type = "支出",
                    category = "餐饮",
                    totalNumber = "12.34",
                    count = 1,
                    percent = "100.00%",
                ),
            ),
            dailySummary = listOf(
                ExportDailySummaryRow(
                    date = "2026-02-09",
                    expenseNumber = "12.34",
                    incomeNumber = "0.00",
                    netNumber = "-12.34",
                ),
            ),
        )

        val entries = mutableSetOf<String>()
        ZipInputStream(bytes.inputStream()).use { zis ->
            while (true) {
                val e = zis.nextEntry ?: break
                entries += e.name
            }
        }

        assertTrue(entries.contains("[Content_Types].xml"))
        assertTrue(entries.contains("_rels/.rels"))
        assertTrue(entries.contains("xl/workbook.xml"))
        assertTrue(entries.contains("xl/styles.xml"))
        assertTrue(entries.contains("xl/worksheets/sheet1.xml"))
        assertTrue(entries.contains("xl/worksheets/sheet2.xml"))
        assertTrue(entries.contains("xl/worksheets/sheet3.xml"))
    }
}

