package com.wyg916.smartledger

import io.flutter.plugin.common.MethodChannel

object WechatAuthBridge {
    private var result: MethodChannel.Result? = null
    private var expectedState: String? = null

    @Synchronized
    fun begin(state: String, pendingResult: MethodChannel.Result): Boolean {
        if (result != null) return false
        result = pendingResult
        expectedState = state
        return true
    }

    @Synchronized
    fun complete(code: String?, state: String?) {
        val pending = take() ?: return
        if (state.isNullOrBlank() || state != pending.second) {
            pending.first.error("wechat_state_mismatch", "Wechat state mismatch", null)
            return
        }
        if (code.isNullOrBlank()) {
            pending.first.error("wechat_code_missing", "Wechat code is missing", null)
            return
        }
        pending.first.success(mapOf("code" to code, "state" to state))
    }

    @Synchronized
    fun fail(code: String, message: String) {
        take()?.first?.error(code, message, null)
    }

    private fun take(): Pair<MethodChannel.Result, String?>? {
        val pending = result ?: return null
        val state = expectedState
        result = null
        expectedState = null
        return pending to state
    }
}
