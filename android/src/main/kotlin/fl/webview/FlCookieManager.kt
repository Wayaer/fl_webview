package fl.webview

import android.os.Build
import android.webkit.CookieManager
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler

internal class FlCookieManager(messenger: BinaryMessenger?) :
    MethodCallHandler {
    private val methodChannel: MethodChannel =
        MethodChannel(messenger, "fl_web_view/cookie_manager")

    override fun onMethodCall(
        methodCall: MethodCall,
        result: MethodChannel.Result
    ) {
        when (methodCall.method) {
            "clearCookies" -> {
                val cookieManager = CookieManager.getInstance()
                val hasCookies = cookieManager.hasCookies()
                cookieManager.removeAllCookies { result.success(hasCookies) }
            }
            else -> result.notImplemented()
        }
    }

    fun dispose() {
        methodChannel.setMethodCallHandler(null)
    }

    init {
        methodChannel.setMethodCallHandler(this)
    }
}