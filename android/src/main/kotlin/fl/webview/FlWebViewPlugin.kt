package fl.webview

import android.content.Context
import android.webkit.CookieManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class FlWebViewPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {

    private lateinit var cookieChannel: MethodChannel

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        val messenger = binding.binaryMessenger
        binding.platformViewRegistry.registerViewFactory(
            "fl.webview", FlWebViewFactory(messenger, binding.applicationContext)
        )
        cookieChannel = MethodChannel(messenger, "fl.webview/cookie_manager")
        cookieChannel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        cookieChannel.setMethodCallHandler(null)
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

    inner class FlWebViewFactory(
        private val messenger: BinaryMessenger, private val applicationContext: Context
    ) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
        override fun create(context: Context?, id: Int, args: Any?): PlatformView {
            val params = args as Map<*, *>
            val methodChannel = MethodChannel(
                messenger, "fl.webview/$id"
            )
            if (context == null) {
                return FlWebViewPlatformView(applicationContext, methodChannel, params)
            }
            return FlWebViewPlatformView(context, methodChannel, params)
        }

    }
}
