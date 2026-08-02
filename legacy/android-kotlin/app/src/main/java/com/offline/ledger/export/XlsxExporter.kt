package com.offline.ledger.export

import java.io.ByteArrayOutputStream
import java.util.zip.ZipEntry
import java.util.zip.ZipOutputStream

data class ExportTransactionRow(
    val dateTime: String,
    val type: String,
    val category: String,
    val amountNumber: String, // numeric string, e.g. 12.34
    val note: String,
)

data class ExportCategorySummaryRow(
    val type: String,
    val category: String,
    val totalNumber: String, // numeric string
    val count: Long,
    val percent: String,
)

data class ExportDailySummaryRow(
    val date: String,
    val expenseNumber: String,
    val incomeNumber: String,
    val netNumber: String,
)

object XlsxExporter {
    fun export(
        details: List<ExportTransactionRow>,
        categorySummary: List<ExportCategorySummaryRow>,
        dailySummary: List<ExportDailySummaryRow>,
    ): ByteArray {
        val out = ByteArrayOutputStream()
        ZipOutputStream(out).use { zip ->
            zipEntry(zip, "[Content_Types].xml", contentTypesXml())
            zipEntry(zip, "_rels/.rels", rootRelsXml())
            zipEntry(zip, "xl/workbook.xml", workbookXml())
            zipEntry(zip, "xl/_rels/workbook.xml.rels", workbookRelsXml())
            zipEntry(zip, "xl/styles.xml", stylesXml())

            zipEntry(zip, "xl/worksheets/sheet1.xml", detailsSheetXml(details))
            zipEntry(zip, "xl/worksheets/sheet2.xml", categorySheetXml(categorySummary))
            zipEntry(zip, "xl/worksheets/sheet3.xml", dailySheetXml(dailySummary))
        }
        return out.toByteArray()
    }

    private fun zipEntry(zip: ZipOutputStream, path: String, text: String) {
        zip.putNextEntry(ZipEntry(path))
        zip.write(text.toByteArray(Charsets.UTF_8))
        zip.closeEntry()
    }

    private fun contentTypesXml(): String = """
        <?xml version="1.0" encoding="UTF-8"?>
        <Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
          <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
          <Default Extension="xml" ContentType="application/xml"/>
          <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
          <Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
          <Override PartName="/xl/worksheets/sheet2.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
          <Override PartName="/xl/worksheets/sheet3.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
          <Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>
        </Types>
    """.trimIndent()

    private fun rootRelsXml(): String = """
        <?xml version="1.0" encoding="UTF-8"?>
        <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
          <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
        </Relationships>
    """.trimIndent()

    private fun workbookXml(): String = """
        <?xml version="1.0" encoding="UTF-8"?>
        <workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"
                  xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
          <sheets>
            <sheet name="明细" sheetId="1" r:id="rId1"/>
            <sheet name="分类汇总" sheetId="2" r:id="rId2"/>
            <sheet name="日汇总" sheetId="3" r:id="rId3"/>
          </sheets>
        </workbook>
    """.trimIndent()

    private fun workbookRelsXml(): String = """
        <?xml version="1.0" encoding="UTF-8"?>
        <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
          <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
          <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet2.xml"/>
          <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet3.xml"/>
          <Relationship Id="rId4" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
        </Relationships>
    """.trimIndent()

    private fun stylesXml(): String = """
        <?xml version="1.0" encoding="UTF-8"?>
        <styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
          <fonts count="2">
            <font>
              <sz val="11"/><color theme="1"/><name val="Calibri"/><family val="2"/>
            </font>
            <font>
              <b/><sz val="11"/><color theme="1"/><name val="Calibri"/><family val="2"/>
            </font>
          </fonts>
          <fills count="2">
            <fill><patternFill patternType="none"/></fill>
            <fill><patternFill patternType="gray125"/></fill>
          </fills>
          <borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>
          <cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>
          <cellXfs count="3">
            <xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>
            <xf numFmtId="0" fontId="1" fillId="0" borderId="0" xfId="0" applyFont="1"/>
            <xf numFmtId="2" fontId="0" fillId="0" borderId="0" xfId="0" applyNumberFormat="1"/>
          </cellXfs>
          <cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>
        </styleSheet>
    """.trimIndent()

    private fun detailsSheetXml(rows: List<ExportTransactionRow>): String {
        val header = listOf("日期时间", "类型", "分类", "金额", "备注")
        val sheetRows = buildString {
            append(rowXml(1, header.map { cellStr(it, style = 1) }))
            rows.forEachIndexed { index, r ->
                append(
                    rowXml(
                        index + 2,
                        listOf(
                            cellStr(r.dateTime),
                            cellStr(r.type),
                            cellStr(r.category),
                            cellNum(r.amountNumber, style = 2),
                            cellStr(r.note),
                        ),
                    ),
                )
            }
        }
        return sheetTemplate(sheetRows)
    }

    private fun categorySheetXml(rows: List<ExportCategorySummaryRow>): String {
        val header = listOf("类型", "分类", "金额合计", "笔数", "占比")
        val sheetRows = buildString {
            append(rowXml(1, header.map { cellStr(it, style = 1) }))
            rows.forEachIndexed { index, r ->
                append(
                    rowXml(
                        index + 2,
                        listOf(
                            cellStr(r.type),
                            cellStr(r.category),
                            cellNum(r.totalNumber, style = 2),
                            cellNum(r.count.toString()),
                            cellStr(r.percent),
                        ),
                    ),
                )
            }
        }
        return sheetTemplate(sheetRows)
    }

    private fun dailySheetXml(rows: List<ExportDailySummaryRow>): String {
        val header = listOf("日期", "支出", "收入", "净额")
        val sheetRows = buildString {
            append(rowXml(1, header.map { cellStr(it, style = 1) }))
            rows.forEachIndexed { index, r ->
                append(
                    rowXml(
                        index + 2,
                        listOf(
                            cellStr(r.date),
                            cellNum(r.expenseNumber, style = 2),
                            cellNum(r.incomeNumber, style = 2),
                            cellNum(r.netNumber, style = 2),
                        ),
                    ),
                )
            }
        }
        return sheetTemplate(sheetRows)
    }

    private fun sheetTemplate(sheetRowsXml: String): String = """
        <?xml version="1.0" encoding="UTF-8"?>
        <worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
          <sheetViews>
            <sheetView workbookViewId="0">
              <pane ySplit="1" topLeftCell="A2" activePane="bottomLeft" state="frozen"/>
            </sheetView>
          </sheetViews>
          <sheetData>
            $sheetRowsXml
          </sheetData>
        </worksheet>
    """.trimIndent()

    private fun rowXml(rowIndex: Int, cells: List<String>): String {
        val cellsXml = cells.mapIndexed { colIdx, cell ->
            val cellRef = cellRef(colIdx + 1, rowIndex)
            cell.replace("{{ref}}", cellRef)
        }.joinToString("")
        return """<row r="$rowIndex">$cellsXml</row>"""
    }

    private fun cellStr(value: String, style: Int = 0): String {
        val v = xmlEscape(value)
        val styleAttr = if (style == 0) "" else """ s="$style""""
        return """<c r="{{ref}}" t="inlineStr"$styleAttr><is><t>$v</t></is></c>"""
    }

    private fun cellNum(value: String, style: Int = 0): String {
        val styleAttr = if (style == 0) "" else """ s="$style""""
        val sanitized = value.trim().ifEmpty { "0" }
        return """<c r="{{ref}}"$styleAttr><v>$sanitized</v></c>"""
    }

    private fun cellRef(col: Int, row: Int): String = "${colLetters(col)}$row"

    private fun colLetters(col: Int): String {
        var n = col
        val sb = StringBuilder()
        while (n > 0) {
            val rem = (n - 1) % 26
            sb.append(('A'.code + rem).toChar())
            n = (n - 1) / 26
        }
        return sb.reverse().toString()
    }

    private fun xmlEscape(raw: String): String {
        return raw
            .replace("&", "&amp;")
            .replace("<", "&lt;")
            .replace(">", "&gt;")
            .replace("\"", "&quot;")
            .replace("'", "&apos;")
    }
}

