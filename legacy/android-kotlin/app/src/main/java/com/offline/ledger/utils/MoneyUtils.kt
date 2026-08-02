package com.offline.ledger.utils

import kotlin.math.abs

object MoneyUtils {
    fun formatCents(amountCent: Long): String {
        val sign = if (amountCent < 0) "-" else ""
        val absCent = abs(amountCent)
        val whole = absCent / 100
        val cents = absCent % 100
        return "$sign$whole.${cents.toString().padStart(2, '0')}"
    }

    fun amountInputToCents(input: String): Long? {
        val trimmed = input.trim()
        if (trimmed.isEmpty()) return null
        if (trimmed == ".") return null

        val parts = trimmed.split('.')
        if (parts.size > 2) return null

        val wholeStr = parts[0].ifEmpty { "0" }
        val whole = wholeStr.toLongOrNull() ?: return null
        if (whole < 0) return null

        val fractionStr = parts.getOrNull(1) ?: ""
        if (fractionStr.length > 2) return null

        val fractionPadded = fractionStr.padEnd(2, '0')
        val fraction = if (fractionPadded.isEmpty()) 0 else fractionPadded.toLongOrNull() ?: return null

        return whole * 100 + fraction
    }

    fun sanitizeAmountInput(input: String): String {
        var s = input.trim()
        if (s.isEmpty()) return ""

        if (s.startsWith(".")) s = "0$s"

        val filtered = buildString {
            var dotSeen = false
            s.forEach { ch ->
                when {
                    ch.isDigit() -> append(ch)
                    ch == '.' && !dotSeen -> {
                        dotSeen = true
                        append('.')
                    }
                }
            }
        }

        val parts = filtered.split('.')
        val whole = parts[0].trimStart('0').ifEmpty { "0" }
        val fraction = parts.getOrNull(1)?.take(2) ?: ""

        return if (filtered.contains('.')) "$whole.$fraction" else whole
    }
}
