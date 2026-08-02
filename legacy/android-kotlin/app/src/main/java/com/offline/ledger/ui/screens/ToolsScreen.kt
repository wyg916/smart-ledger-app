package com.offline.ledger.ui.screens

import android.content.Intent
import android.net.Uri
import android.widget.Toast
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.ArrowBack
import androidx.compose.material.icons.outlined.Backup
import androidx.compose.material.icons.outlined.Download
import androidx.compose.material.icons.outlined.Restore
import androidx.compose.material.icons.outlined.Share
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.ListItem
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
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
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.offline.ledger.ui.viewmodel.ExportRange
import com.offline.ledger.ui.viewmodel.ExportType
import com.offline.ledger.ui.viewmodel.ToolsEvent
import com.offline.ledger.ui.viewmodel.ToolsViewModel
import com.offline.ledger.utils.AppRestart
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

@Composable
@OptIn(ExperimentalMaterial3Api::class)
fun ToolsScreen(
    onBack: () -> Unit,
) {
    val viewModel: ToolsViewModel = hiltViewModel()
    val state = viewModel.uiState.collectAsState().value
    val context = LocalContext.current

    var showBackupPasswordDialog by remember { mutableStateOf(false) }
    var backupOldPwd by remember { mutableStateOf("") }
    var backupPwd1 by remember { mutableStateOf("") }
    var backupPwd2 by remember { mutableStateOf("") }
    var showResetBackupPasswordConfirm by remember { mutableStateOf(false) }

    var restoreUri by remember { mutableStateOf<Uri?>(null) }
    var showRestoreDialog by remember { mutableStateOf(false) }
    var restorePassword by remember { mutableStateOf("") }

    val createXlsxLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.CreateDocument(
            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        ),
    ) { uri ->
        if (uri != null) viewModel.exportExcel(uri)
    }

    val openBackupLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.OpenDocument(),
    ) { uri ->
        if (uri != null) {
            restoreUri = uri
            restorePassword = ""
            showRestoreDialog = true
        }
    }

    LaunchedEffect(Unit) {
        viewModel.events.collect { event ->
            when (event) {
                is ToolsEvent.Toast -> Toast.makeText(context, event.message, Toast.LENGTH_SHORT).show()
                ToolsEvent.ExportOk -> Toast.makeText(context, "导出成功", Toast.LENGTH_SHORT).show()
                ToolsEvent.BackupOk -> Toast.makeText(context, "备份已生成", Toast.LENGTH_SHORT).show()
                ToolsEvent.BackupPasswordSetOk -> {
                    showBackupPasswordDialog = false
                    showResetBackupPasswordConfirm = false
                    backupOldPwd = ""
                    backupPwd1 = ""
                    backupPwd2 = ""
                }
                ToolsEvent.RestoreOk -> {
                    Toast.makeText(context, "恢复成功，正在重启…", Toast.LENGTH_SHORT).show()
                    AppRestart.restart(context)
                }
            }
        }
    }

    if (showBackupPasswordDialog) {
        val changing = state.backupPasswordConfigured
        AlertDialog(
            onDismissRequest = { showBackupPasswordDialog = false },
            title = { Text(if (changing) "修改备份密码" else "设置备份密码") },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text("密码用于加密备份文件，请牢记（换机/重装恢复需要）。")
                    if (changing) {
                        Text("修改时需要先验证旧密码。", style = MaterialTheme.typography.bodySmall)
                        OutlinedTextField(
                            value = backupOldPwd,
                            onValueChange = { backupOldPwd = it },
                            label = { Text("旧密码") },
                            visualTransformation = PasswordVisualTransformation(),
                            singleLine = true,
                        )
                    }
                    OutlinedTextField(
                        value = backupPwd1,
                        onValueChange = { backupPwd1 = it },
                        label = { Text(if (changing) "新密码" else "密码") },
                        visualTransformation = PasswordVisualTransformation(),
                        singleLine = true,
                    )
                    OutlinedTextField(
                        value = backupPwd2,
                        onValueChange = { backupPwd2 = it },
                        label = { Text(if (changing) "确认新密码" else "确认密码") },
                        visualTransformation = PasswordVisualTransformation(),
                        singleLine = true,
                    )
                    if (changing) {
                        TextButton(
                            modifier = Modifier.align(Alignment.End),
                            enabled = !state.busy,
                            onClick = { showResetBackupPasswordConfirm = true },
                        ) { Text("忘记密码") }
                    }
                }
            },
            confirmButton = {
                TextButton(
                    enabled = !state.busy,
                    onClick = {
                        if (changing && backupOldPwd.isBlank()) {
                            Toast.makeText(context, "请输入旧密码", Toast.LENGTH_SHORT).show()
                            return@TextButton
                        }
                        if (backupPwd1.isBlank()) {
                            Toast.makeText(context, "密码不能为空", Toast.LENGTH_SHORT).show()
                            return@TextButton
                        }
                        if (backupPwd1 != backupPwd2) {
                            Toast.makeText(context, "两次输入不一致", Toast.LENGTH_SHORT).show()
                            return@TextButton
                        }
                        viewModel.setBackupPassword(
                            newPassword = backupPwd1,
                            oldPassword = if (changing) backupOldPwd else null,
                        )
                    },
                ) { Text("确定") }
            },
            dismissButton = {
                TextButton(enabled = !state.busy, onClick = { showBackupPasswordDialog = false }) { Text("取消") }
            },
        )
    }

    if (showResetBackupPasswordConfirm) {
        AlertDialog(
            onDismissRequest = { showResetBackupPasswordConfirm = false },
            title = { Text("忘记备份密码？") },
            text = {
                Text("清除后将无法验证旧密码；历史备份文件仍需要原密码才能恢复。确定清除吗？")
            },
            confirmButton = {
                TextButton(
                    enabled = !state.busy,
                    onClick = { viewModel.resetBackupPassword() },
                ) { Text("清除") }
            },
            dismissButton = {
                TextButton(enabled = !state.busy, onClick = { showResetBackupPasswordConfirm = false }) { Text("取消") }
            },
        )
    }

    if (showRestoreDialog) {
        AlertDialog(
            onDismissRequest = { showRestoreDialog = false },
            title = { Text("输入备份密码") },
            text = {
                OutlinedTextField(
                    value = restorePassword,
                    onValueChange = { restorePassword = it },
                    label = { Text("备份密码") },
                    visualTransformation = PasswordVisualTransformation(),
                    singleLine = true,
                )
            },
            confirmButton = {
                TextButton(
                    onClick = {
                        val uri = restoreUri
                        showRestoreDialog = false
                        if (uri != null) viewModel.restoreFromUri(uri, restorePassword)
                    },
                ) { Text("恢复") }
            },
            dismissButton = {
                TextButton(onClick = { showRestoreDialog = false }) { Text("取消") }
            },
        )
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("工具") },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.Outlined.ArrowBack, contentDescription = "返回")
                    }
                },
            )
        },
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
                .verticalScroll(rememberScrollState())
                .padding(12.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            Text("导出 Excel", style = MaterialTheme.typography.titleLarge)

            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                FilterChip(
                    selected = state.exportRange == ExportRange.ThisMonth,
                    onClick = { viewModel.setExportRange(ExportRange.ThisMonth) },
                    label = { Text("本月") },
                )
                FilterChip(
                    selected = state.exportRange == ExportRange.LastMonth,
                    onClick = { viewModel.setExportRange(ExportRange.LastMonth) },
                    label = { Text("上月") },
                )
            }

            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                FilterChip(
                    selected = state.exportType == ExportType.All,
                    onClick = { viewModel.setExportType(ExportType.All) },
                    label = { Text("全部") },
                )
                FilterChip(
                    selected = state.exportType == ExportType.Expense,
                    onClick = { viewModel.setExportType(ExportType.Expense) },
                    label = { Text("仅支出") },
                )
                FilterChip(
                    selected = state.exportType == ExportType.Income,
                    onClick = { viewModel.setExportType(ExportType.Income) },
                    label = { Text("仅收入") },
                )
            }

            Button(
                modifier = Modifier.fillMaxWidth(),
                enabled = !state.busy,
                onClick = {
                    val ts = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.getDefault()).format(Date())
                    createXlsxLauncher.launch("记账统计_$ts.xlsx")
                },
            ) {
                Icon(Icons.Outlined.Download, contentDescription = null)
                Text("导出 .xlsx", modifier = Modifier.padding(start = 8.dp))
            }

            Spacer(modifier = Modifier.padding(top = 8.dp))
            Text("备份与恢复（加密）", style = MaterialTheme.typography.titleLarge)

            ListItem(
                leadingContent = { Icon(Icons.Outlined.Backup, contentDescription = null) },
                headlineContent = { Text("备份密码") },
                supportingContent = { Text(if (state.backupPasswordConfigured) "已设置" else "未设置") },
                trailingContent = {
                    Button(onClick = { showBackupPasswordDialog = true }) {
                        Text(if (state.backupPasswordConfigured) "修改" else "设置")
                    }
                },
            )

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Column {
                    Text("自动备份", style = MaterialTheme.typography.titleMedium)
                    Text("每日一次（可关闭）", style = MaterialTheme.typography.bodySmall)
                }
                Switch(
                    checked = state.autoBackupEnabled,
                    onCheckedChange = { checked ->
                        if (checked && !state.backupPasswordConfigured) {
                            Toast.makeText(context, "请先设置备份密码", Toast.LENGTH_SHORT).show()
                            showBackupPasswordDialog = true
                            return@Switch
                        }
                        viewModel.setAutoBackupEnabled(checked)
                    },
                )
            }

            Button(
                modifier = Modifier.fillMaxWidth(),
                enabled = !state.busy,
                onClick = {
                    if (!state.backupPasswordConfigured) {
                        Toast.makeText(context, "请先设置备份密码", Toast.LENGTH_SHORT).show()
                        showBackupPasswordDialog = true
                    } else {
                        viewModel.createManualBackup()
                    }
                },
            ) { Text("立即备份（仅保留最近 5 次）") }

            Button(
                modifier = Modifier.fillMaxWidth(),
                enabled = !state.busy,
                onClick = { openBackupLauncher.launch(arrayOf("*/*")) },
            ) {
                Icon(Icons.Outlined.Restore, contentDescription = null)
                Text("从文件恢复", modifier = Modifier.padding(start = 8.dp))
            }

            Text("备份列表（最近 5 个）", style = MaterialTheme.typography.titleMedium)
            if (state.backups.isEmpty()) {
                Text("暂无备份", style = MaterialTheme.typography.bodyMedium)
            } else {
                state.backups.forEach { item ->
                    ListItem(
                        headlineContent = { Text(item.displayName) },
                        supportingContent = {
                            Text("${item.sizeBytes / 1024} KB · ${if (item.isAuto) "自动" else "手动"}")
                        },
                        trailingContent = {
                            Row {
                                IconButton(onClick = {
                                    val intent = Intent(Intent.ACTION_SEND).apply {
                                        type = "application/octet-stream"
                                        putExtra(Intent.EXTRA_STREAM, item.uri)
                                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                    }
                                    context.startActivity(Intent.createChooser(intent, "分享备份"))
                                }) {
                                    Icon(Icons.Outlined.Share, contentDescription = "分享")
                                }
                                IconButton(onClick = {
                                    restoreUri = item.uri
                                    restorePassword = ""
                                    showRestoreDialog = true
                                }) {
                                    Icon(Icons.Outlined.Restore, contentDescription = "恢复")
                                }
                            }
                        },
                    )
                }
            }
        }
    }
}
