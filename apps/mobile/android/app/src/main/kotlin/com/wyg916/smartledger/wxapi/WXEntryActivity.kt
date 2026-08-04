package com.wyg916.smartledger.wxapi

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import com.tencent.mm.opensdk.constants.ConstantsAPI
import com.tencent.mm.opensdk.modelbase.BaseReq
import com.tencent.mm.opensdk.modelbase.BaseResp
import com.tencent.mm.opensdk.modelmsg.SendAuth
import com.tencent.mm.opensdk.openapi.IWXAPIEventHandler
import com.tencent.mm.opensdk.openapi.WXAPIFactory
import com.wyg916.smartledger.BuildConfig
import com.wyg916.smartledger.WechatAuthBridge

class WXEntryActivity : Activity(), IWXAPIEventHandler {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent) {
        if (BuildConfig.WECHAT_APP_ID.isBlank()) {
            WechatAuthBridge.fail("wechat_not_configured", "Wechat AppID is not configured")
            finish()
            return
        }
        val api = WXAPIFactory.createWXAPI(this, BuildConfig.WECHAT_APP_ID, false)
        if (!api.handleIntent(intent, this)) {
            WechatAuthBridge.fail("wechat_invalid_callback", "Invalid Wechat callback")
            finish()
        }
    }

    override fun onReq(req: BaseReq) = Unit

    override fun onResp(resp: BaseResp) {
        if (resp.type != ConstantsAPI.COMMAND_SENDAUTH || resp !is SendAuth.Resp) {
            finish()
            return
        }
        when (resp.errCode) {
            BaseResp.ErrCode.ERR_OK -> WechatAuthBridge.complete(resp.code, resp.state)
            BaseResp.ErrCode.ERR_USER_CANCEL ->
                WechatAuthBridge.fail("wechat_cancelled", "Wechat authorization cancelled")
            else -> WechatAuthBridge.fail("wechat_failed", "Wechat authorization failed")
        }
        finish()
    }
}
