package pet.jolipaw.app.wxapi

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.util.Log
import com.tencent.mm.opensdk.modelbase.BaseReq
import com.tencent.mm.opensdk.modelbase.BaseResp
import com.tencent.mm.opensdk.modelmsg.SendAuth
import com.tencent.mm.opensdk.openapi.IWXAPI
import com.tencent.mm.opensdk.openapi.IWXAPIEventHandler
import com.tencent.mm.opensdk.openapi.WXAPIFactory

class WXEntryActivity : Activity(), IWXAPIEventHandler {
    private lateinit var api: IWXAPI

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d("WXEntry", "onCreate")
        api = WXAPIFactory.createWXAPI(this, "wxcf5ef326f4119c89", false)
        api.handleIntent(intent, this)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        api.handleIntent(intent, this)
    }

    override fun onReq(req: BaseReq) {
        Log.d("WXEntry", "onReq: $req")
        finish()
    }

    override fun onResp(resp: BaseResp) {
        Log.d("WXEntry", "onResp: errCode=${resp.errCode}, errStr=${resp.errStr}, type=${resp.type}")
        if (resp is SendAuth.Resp) {
            Log.d("WXEntry", "SendAuth.Resp: code=${resp.code}")
            // 存入全局静态变量，MainActivity 恢复后读取
            pet.jolipaw.app.MainActivity.pendingWechatCode = resp.code ?: ""
        }
        finish()
    }
}
