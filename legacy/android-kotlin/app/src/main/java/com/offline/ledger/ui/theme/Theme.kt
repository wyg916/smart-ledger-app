package com.offline.ledger.ui.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable

private val LightColors = lightColorScheme(
    primary = LedgerYellowDark,
    secondary = LedgerYellow,
)

private val DarkColors = darkColorScheme(
    primary = LedgerYellow,
    secondary = LedgerYellowDark,
)

@Composable
fun LedgerTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = LightColors,
        content = content,
    )
}

