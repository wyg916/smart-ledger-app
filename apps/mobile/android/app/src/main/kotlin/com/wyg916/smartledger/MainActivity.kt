package com.wyg916.smartledger

import android.os.Bundle
import android.view.WindowManager
import com.tencent.mm.opensdk.modelmsg.SendAuth
import com.tencent.mm.opensdk.openapi.IWXAPI
import com.tencent.mm.opensdk.openapi.WXAPIFactory
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var wechatApi: IWXAPI? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE,
        )
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            AUTH_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "authorizePhone" -> result.error(
                    "phone_not_configured",
                    "Tencent phone auth native SDK is not configured",
                    null,
                )
                "isWechatInstalled" -> {
                    val api = wechat()
                    if (api == null) {
                        result.error("wechat_not_configured", "Wechat AppID is not configured", null)
                    } else {
                        result.success(api.isWXAppInstalled)
                    }
                }
                "authorizeWechat" -> {
                    val state = call.argument<String>("state")
                    if (state.isNullOrBlank()) {
                        result.error("wechat_state_missing", "Wechat state is required", null)
                    } else {
                        authorizeWechat(state, result)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun wechat(): IWXAPI? {
        if (BuildConfig.WECHAT_APP_ID.isBlank()) return null
        if (wechatApi == null) {
            wechatApi = WXAPIFactory.createWXAPI(this, BuildConfig.WECHAT_APP_ID, true).also {
                it.registerApp(BuildConfig.WECHAT_APP_ID)
            }
        }
        return wechatApi
    }

    private fun authorizeWechat(state: String, result: MethodChannel.Result) {
        val api = wechat()
        if (api == null) {
            result.error("wechat_not_configured", "Wechat AppID is not configured", null)
            return
        }
        if (!api.isWXAppInstalled) {
            result.error("wechat_not_installed", "Wechat is not installed", null)
            return
        }
        if (!WechatAuthBridge.begin(state, result)) {
            result.error("wechat_auth_in_progress", "Wechat authorization is already in progress", null)
            return
        }
        val request = SendAuth.Req().apply {
            scope = "snsapi_userinfo"
            this.state = state
        }
        if (!api.sendReq(request)) {
            WechatAuthBridge.fail("wechat_launch_failed", "Unable to launch Wechat")
        }
    }

    private companion object {
        const val AUTH_CHANNEL = "com.wyg916.smartledger/auth"
    }
}
