package pet.jolipaw.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.wifi.WifiManager
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * JoliPaw App 原生入口 Activity
 *
 * 提供 Flutter Platform Channel 原生层实现，当前功能：
 * - WiFi 扫描：通过 `com.flttercat/wifi` MethodChannel 提供 `scanWifi` 方法
 *
 * ## 通信协议
 *
 * - Channel: `com.flttercat/wifi`
 * - 方法: `scanWifi`
 * - 返回: `List<Map<String, Any>>` — 每个 Map 包含 ssid, rssi, capabilities
 *
 * ## 所需权限
 *
 * - `ACCESS_WIFI_STATE` — 读取 WiFi 状态
 * - `CHANGE_WIFI_STATE` — 触发 WiFi 扫描
 *
 * 以上权限已在 AndroidManifest.xml 中声明。
 */
class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.flttercat/wifi"
    private val WECHAT_CHANNEL = "com.flttercat/wechat"

    companion object {
        var pendingWechatCode: String? = null
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "scanWifi" -> scanWifi(result)
                    else -> result.notImplemented()
                }
            }
    }

    override fun onResume() {
        super.onResume()
        val code = pendingWechatCode
        if (!code.isNullOrEmpty()) {
            pendingWechatCode = null
            Log.d("MainActivity", "onResume sending code=$code")
            flutterEngine?.dartExecutor?.binaryMessenger?.let {
                MethodChannel(it, WECHAT_CHANNEL).invokeMethod("onWechatAuthCode", code)
            }
        }
    }

    /**
     * 扫描周围 WiFi 网络
     *
     * 实现流程：
     * 1. 获取 WifiManager 并检查 WiFi 是否开启
     * 2. 注册 BroadcastReceiver 监听 `SCAN_RESULTS_AVAILABLE_ACTION`
     * 3. 调用 `WifiManager.startScan()` 触发扫描
     * 4. 收到广播后解析扫描结果，按信号强度降序排列，按 SSID 去重
     * 5. 通过 MethodChannel.Result 返回给 Flutter 层
     *
     * ## 错误处理
     *
     * - `WIFI_OFF` — WiFi 未开启或 WifiManager 不可用
     * - `SCAN_ERROR` — 扫描失败或结果解析异常
     *
     * ## 降级策略
     *
     * 如果 `startScan()` 返回 false（如扫描被系统限制），
     * 直接返回缓存的扫描结果（`wifiManager.scanResults`）。
     */
    private fun scanWifi(result: MethodChannel.Result) {
        val wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as? WifiManager

        // 检查 WifiManager 可用性和 WiFi 是否开启
        if (wifiManager == null || !wifiManager.isWifiEnabled) {
            result.error("WIFI_OFF", "WiFi 未开启", null)
            return
        }

        // 注册 BroadcastReceiver 监听扫描结果广播
        val receiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context, intent: Intent) {
                unregisterReceiver(this)
                try {
                    val scanResults = wifiManager.scanResults
                    val list = scanResults.mapNotNull { r ->
                        val ssid = r.SSID?.trim('"') ?: return@mapNotNull null
                        if (ssid.isEmpty()) return@mapNotNull null
                        mapOf(
                            "ssid" to ssid,
                            "rssi" to r.level,
                            "capabilities" to (r.capabilities ?: "")
                        )
                    }
                        .sortedByDescending { it["rssi"] as Int }
                        .distinctBy { it["ssid"] }
                    result.success(list)
                } catch (e: Exception) {
                    result.error("SCAN_ERROR", e.message, null)
                }
            }
        }

        registerReceiver(receiver, IntentFilter(WifiManager.SCAN_RESULTS_AVAILABLE_ACTION))

        @Suppress("DEPRECATION")
        val started = wifiManager.startScan()
        if (!started) {
            unregisterReceiver(receiver)
            try {
                val scanResults = wifiManager.scanResults
                val list = scanResults.mapNotNull { r ->
                    val ssid = r.SSID?.trim('"') ?: return@mapNotNull null
                    if (ssid.isEmpty()) return@mapNotNull null
                    mapOf(
                        "ssid" to ssid,
                        "rssi" to r.level,
                        "capabilities" to (r.capabilities ?: "")
                    )
                }
                    .sortedByDescending { it["rssi"] as Int }
                    .distinctBy { it["ssid"] }
                result.success(list)
            } catch (e: Exception) {
                result.error("SCAN_ERROR", e.message, null)
            }
        }
    }
}
