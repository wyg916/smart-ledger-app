package com.offline.ledger.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Build
import androidx.compose.material.icons.outlined.Category
import androidx.compose.material.icons.outlined.Security
import androidx.compose.material3.Button
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp

@Composable
fun MineScreen(
    onOpenSecurity: () -> Unit,
    onOpenCategories: () -> Unit,
    onOpenTools: () -> Unit,
) {
    Column(
        modifier = Modifier.fillMaxSize().padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp, Alignment.CenterVertically),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text(text = "我的", style = MaterialTheme.typography.titleLarge)
        Button(modifier = Modifier.fillMaxWidth(), onClick = onOpenCategories) {
            Icon(Icons.Outlined.Category, contentDescription = null)
            Text(text = "类别设置", modifier = Modifier.padding(start = 8.dp))
        }
        Button(modifier = Modifier.fillMaxWidth(), onClick = onOpenSecurity) {
            Icon(Icons.Outlined.Security, contentDescription = null)
            Text(text = "数据与安全", modifier = Modifier.padding(start = 8.dp))
        }
        Button(modifier = Modifier.fillMaxWidth(), onClick = onOpenTools) {
            Icon(Icons.Outlined.Build, contentDescription = null)
            Text(text = "工具（导出/备份）", modifier = Modifier.padding(start = 8.dp))
        }
    }
}
