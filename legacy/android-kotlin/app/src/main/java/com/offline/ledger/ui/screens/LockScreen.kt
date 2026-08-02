package com.offline.ledger.ui.screens

import android.widget.Toast
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
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
import androidx.compose.material.icons.outlined.Fingerprint
import androidx.compose.material.icons.outlined.KeyboardBackspace
import androidx.compose.material3.Button
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilledTonalButton
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
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
import androidx.core.content.ContextCompat
import androidx.fragment.app.FragmentActivity
import androidx.hilt.navigation.compose.hiltViewModel
import com.offline.ledger.ui.viewmodel.LockViewModel

@Composable
fun LockScreen(viewModel: LockViewModel = hiltViewModel()) {
    val state by viewModel.uiState.collectAsState()
    val context = androidx.compose.ui.platform.LocalContext.current

    val biometricAllowedBySetting = state.lockSettings.biometricEnabled
    val biometricAvailable = remember {
        val bm = BiometricManager.from(context)
        bm.canAuthenticate(
            BiometricManager.Authenticators.BIOMETRIC_WEAK or
                BiometricManager.Authenticators.BIOMETRIC_STRONG,
        ) == BiometricManager.BIOMETRIC_SUCCESS
    }

    var biometricTried by remember { mutableStateOf(false) }

    LaunchedEffect(biometricAllowedBySetting, biometricAvailable, state.locked, state.hasPin) {
        if (state.locked && state.hasPin && biometricAllowedBySetting && biometricAvailable && !biometricTried) {
            biometricTried = true
            promptBiometric(
                activity = context as? FragmentActivity,
                onSuccess = { viewModel.unlockFromBiometric() },
                onError = { msg -> Toast.makeText(context, msg, Toast.LENGTH_SHORT).show() },
            )
        }
    }

    Column(
        modifier = Modifier.fillMaxSize().padding(24.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp, Alignment.CenterVertically),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Text(text = "应用锁", style = MaterialTheme.typography.headlineMedium)
        Text(text = "请输入 6 位 PIN 解锁", style = MaterialTheme.typography.bodyLarge)

        PinDots(length = state.pinInput.length)

        if (state.error != null) {
            Text(text = state.error ?: "", color = MaterialTheme.colorScheme.error)
        } else {
            Spacer(modifier = Modifier.height(20.dp))
        }

        PinKeypad(
            onDigit = viewModel::pressDigit,
            onBackspace = viewModel::backspace,
        )

        if (state.hasPin && biometricAllowedBySetting && biometricAvailable) {
            FilledTonalButton(
                modifier = Modifier.fillMaxWidth(),
                onClick = {
                    promptBiometric(
                        activity = context as? FragmentActivity,
                        onSuccess = { viewModel.unlockFromBiometric() },
                        onError = { msg -> Toast.makeText(context, msg, Toast.LENGTH_SHORT).show() },
                    )
                },
            ) {
                Icon(Icons.Outlined.Fingerprint, contentDescription = null)
                Text(text = "使用指纹/人脸", modifier = Modifier.padding(start = 8.dp))
            }
        }
    }
}

@Composable
private fun PinDots(length: Int) {
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
private fun PinKeypad(
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

private fun promptBiometric(
    activity: FragmentActivity?,
    onSuccess: () -> Unit,
    onError: (String) -> Unit,
) {
    if (activity == null) {
        onError("当前页面无法使用生物识别")
        return
    }

    val executor = ContextCompat.getMainExecutor(activity)
    val prompt = BiometricPrompt(
        activity,
        executor,
        object : BiometricPrompt.AuthenticationCallback() {
            override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) {
                onSuccess()
            }

            override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                onError(errString.toString())
            }
        },
    )

    val promptInfo = BiometricPrompt.PromptInfo.Builder()
        .setTitle("解锁记账统计")
        .setSubtitle("使用指纹或人脸解锁")
        .setNegativeButtonText("使用PIN")
        .build()

    prompt.authenticate(promptInfo)
}
