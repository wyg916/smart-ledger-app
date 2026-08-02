package com.offline.ledger.ui.screens

import android.widget.Toast
import androidx.biometric.BiometricManager
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.ArrowBack
import androidx.compose.material.icons.outlined.Lock
import androidx.compose.material.icons.outlined.Security
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.ListItem
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Switch
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
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.offline.ledger.ui.viewmodel.SecurityViewModel

@Composable
@OptIn(ExperimentalMaterial3Api::class)
fun SecurityScreen(
    onBack: () -> Unit,
    onSetupPin: () -> Unit,
    viewModel: SecurityViewModel = hiltViewModel(),
) {
    val state by viewModel.uiState.collectAsState()
    val context = androidx.compose.ui.platform.LocalContext.current

    LaunchedEffect(Unit) {
        viewModel.refreshPinState()
    }

    val biometricAvailable = remember {
        BiometricManager.from(context).canAuthenticate(
            BiometricManager.Authenticators.BIOMETRIC_WEAK or
                BiometricManager.Authenticators.BIOMETRIC_STRONG,
        ) == BiometricManager.BIOMETRIC_SUCCESS
    }

    var confirmClearPin by remember { mutableStateOf(false) }

    if (confirmClearPin) {
        AlertDialog(
            onDismissRequest = { confirmClearPin = false },
            title = { Text("清除 PIN？") },
            text = { Text("清除后将关闭应用锁，并且无法再用旧 PIN 解锁。") },
            confirmButton = {
                TextButton(
                    onClick = {
                        confirmClearPin = false
                        viewModel.clearPinAndDisableLock()
                        Toast.makeText(context, "已清除", Toast.LENGTH_SHORT).show()
                    },
                ) { Text("清除") }
            },
            dismissButton = { TextButton(onClick = { confirmClearPin = false }) { Text("取消") } },
        )
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("数据与安全") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.Outlined.ArrowBack, contentDescription = "返回")
                    }
                },
            )
        },
    ) { inner ->
        Column(
            modifier = Modifier.fillMaxSize().padding(inner).padding(12.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            ListItem(
                leadingContent = { Icon(Icons.Outlined.Lock, contentDescription = null) },
                headlineContent = { Text("应用锁") },
                supportingContent = { Text("开启后进入应用需要解锁，并禁止截屏/录屏。") },
                trailingContent = {
                    Switch(
                        checked = state.lockSettings.enabled,
                        onCheckedChange = { checked ->
                            if (checked && !state.hasPin) {
                                Toast.makeText(context, "请先设置 PIN", Toast.LENGTH_SHORT).show()
                                onSetupPin()
                            } else {
                                viewModel.setLockEnabled(checked)
                            }
                        },
                    )
                },
            )

            ListItem(
                leadingContent = { Icon(Icons.Outlined.Security, contentDescription = null) },
                headlineContent = { Text("PIN") },
                supportingContent = { Text(if (state.hasPin) "已设置" else "未设置") },
                trailingContent = {
                    Button(onClick = onSetupPin) { Text(if (state.hasPin) "修改" else "设置") }
                },
            )

            if (state.hasPin) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Column {
                        Text(text = "指纹/人脸解锁", style = MaterialTheme.typography.titleMedium)
                        Text(
                            text = if (biometricAvailable) "可用" else "本机不支持或未录入",
                            style = MaterialTheme.typography.bodySmall,
                        )
                    }
                    Switch(
                        enabled = state.lockSettings.enabled && biometricAvailable,
                        checked = state.lockSettings.biometricEnabled,
                        onCheckedChange = viewModel::setBiometricEnabled,
                    )
                }

                Text(text = "自动锁定", style = MaterialTheme.typography.titleMedium, modifier = Modifier.padding(top = 8.dp))
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    TimeoutChip("立即", 0, state.lockSettings.timeoutMinutes, viewModel::setTimeoutMinutes)
                    TimeoutChip("1分钟", 1, state.lockSettings.timeoutMinutes, viewModel::setTimeoutMinutes)
                    TimeoutChip("5分钟", 5, state.lockSettings.timeoutMinutes, viewModel::setTimeoutMinutes)
                    TimeoutChip("10分钟", 10, state.lockSettings.timeoutMinutes, viewModel::setTimeoutMinutes)
                }

                Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    Button(
                        modifier = Modifier.weight(1f),
                        onClick = viewModel::lockNow,
                        enabled = state.lockSettings.enabled,
                    ) { Text("立即锁定") }
                    Button(
                        modifier = Modifier.weight(1f),
                        onClick = { confirmClearPin = true },
                    ) { Text("清除PIN") }
                }
            } else {
                Spacer(modifier = Modifier.padding(top = 8.dp))
            }
        }
    }
}

@Composable
private fun TimeoutChip(
    label: String,
    minutes: Int,
    currentMinutes: Int,
    onSelect: (Int) -> Unit,
) {
    FilterChip(
        selected = currentMinutes == minutes,
        onClick = { onSelect(minutes) },
        label = { Text(label) },
    )
}
