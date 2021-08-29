package fl.webview

import android.content.Context
import android.webkit.CookieManager
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class FlWebViewPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {

    private lateinit var cookieChannel: MethodChannel

    override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        val messenger = binding.binaryMessenger
        binding.platformViewRegistry.registerViewFactory(
                "fl_web_view",
                FlWebViewFactory(messenger)
        )
        cookieChannel = MethodChannel(messenger, "fl_web_view/cookie_manager")
        cookieChannel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        cookieChannel.setMethodCallHandler(null)
    }


    private inner class FlWebViewFactory(
            private val messenger: BinaryMessenger
    ) :
            PlatformViewFactory(StandardMessageCodec.INSTANCE) {
        override fun create(
                context: Context,
                id: Int,
                args: Any
        ): PlatformView {
            val params = args as Map<String, Any?>
            val methodChannel = MethodChannel(
                    messenger,
                    "fl_web_view_$id"
            )
            return FlWebViewPlatformView(
                    context, methodChannel, params
            )
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "clearCookies" -> {
                val cookieManager = CookieManager.getInstance()
                val hasCookies = cookieManager.hasCookies()
                cookieManager.removeAllCookies { result.success(hasCookies) }
            }
            else -> result.notImplemented()
        }
    }
}
