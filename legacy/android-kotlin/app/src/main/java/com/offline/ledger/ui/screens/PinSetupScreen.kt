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
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.ArrowBack
import androidx.compose.material.icons.outlined.KeyboardBackspace
import androidx.compose.material3.FilledTonalButton
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.offline.ledger.ui.viewmodel.PinSetupEvent
import com.offline.ledger.ui.viewmodel.PinSetupViewModel

@Composable
@OptIn(ExperimentalMaterial3Api::class)
fun PinSetupScreen(
    onBack: () -> Unit,
    viewModel: PinSetupViewModel = hiltViewModel(),
) {
    val state by viewModel.uiState.collectAsState()
    val context = androidx.compose.ui.platform.LocalContext.current

    LaunchedEffect(Unit) {
        viewModel.events.collect { event ->
            when (event) {
                PinSetupEvent.Done -> {
                    Toast.makeText(context, "PIN 已设置", Toast.LENGTH_SHORT).show()
                    onBack()
                }

                is PinSetupEvent.Error -> Toast.makeText(context, event.message, Toast.LENGTH_SHORT).show()
            }
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("设置PIN") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.Outlined.ArrowBack, contentDescription = "返回")
                    }
                },
            )
        },
    ) { inner ->
        Column(
            modifier = Modifier.fillMaxSize().padding(inner).padding(24.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp, Alignment.CenterVertically),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Text(text = state.hint, style = MaterialTheme.typography.titleLarge)
            LockPinDots(length = state.pinInput.length)

            if (state.error != null) {
                Text(text = state.error ?: "", color = MaterialTheme.colorScheme.error)
            } else {
                Spacer(modifier = Modifier.height(20.dp))
            }

            PinSetupKeypad(onDigit = viewModel::pressDigit, onBackspace = viewModel::backspace)
        }
    }
}

@Composable
private fun LockPinDots(length: Int) {
    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        repeat(6) { index ->
            val filled = index < length
            val color = if (filled) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.outline
            androidx.compose.foundation.Canvas(modifier = Modifier.size(16.dp)) {
                drawCircle(color = color, radius = 8.dp.toPx())
            }
        }
    }
}

@Composable
private fun PinSetupKeypad(
    onDigit: (Int) -> Unit,
    onBackspace: () -> Unit,
) {
    val rows = listOf(
        listOf(1, 2, 3),
        listOf(4, 5, 6),
        listOf(7, 8, 9),
    )
    Column(modifier = Modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        rows.forEach { row ->
            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                row.forEach { d ->
                    FilledTonalButton(
                        modifier = Modifier.weight(1f).height(48.dp),
                        onClick = { onDigit(d) },
                    ) { Text(d.toString(), style = MaterialTheme.typography.titleMedium) }
                }
            }
        }
        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            Spacer(modifier = Modifier.weight(1f))
            FilledTonalButton(
                modifier = Modifier.weight(1f).height(48.dp),
                onClick = { onDigit(0) },
            ) { Text("0", style = MaterialTheme.typography.titleMedium) }
            FilledTonalButton(
                modifier = Modifier.weight(1f).height(48.dp),
                onClick = onBackspace,
            ) { Icon(Icons.Outlined.KeyboardBackspace, contentDescription = "删除") }
        }
    }
}
