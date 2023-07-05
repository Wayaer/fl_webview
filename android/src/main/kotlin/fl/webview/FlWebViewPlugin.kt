package fl.webview

import android.content.Context
import android.os.Handler
import android.os.Looper
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
        cookieChannel = MethodChannel(messenger, "fl.webview.channel")
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
            val channel = MethodChannel(messenger, "fl.webview/$id")
            if (context == null) {
                return FlWebViewPlatformView(applicationContext, channel, params)
            }
            return FlWebViewPlatformView(context, channel, params)
        }

    }

    companion object {
        fun invokeMethod(
            channel: MethodChannel,
            handler: Handler,
            method: String,
            args: Any?,
            onSuccess: ((Any?) -> Unit)? = null
        ) {
            var callback: MethodChannel.Result? = null
            if (onSuccess != null) {
                callback = object : MethodChannel.Result {
                    override fun success(result: Any?) {
                        onSuccess(result)
                    }

                    override fun error(
                        errorCode: String, errorMessage: String?, errorDetails: Any?
                    ) {
                        throw IllegalStateException("$method calls error { errorCode:$errorCode errorMessage:$errorMessage errorDetails:$errorDetails}")
                    }

                    override fun notImplemented() {
                        throw IllegalStateException(
                            "$method must be implemented by the webview method channel"
                        )
                    }
                }
            }
            if (handler.looper == Looper.myLooper()) {
                if (callback == null) {
                    channel.invokeMethod(method, args)
                } else {
                    channel.invokeMethod(method, args, callback)
                }
            } else {
                handler.post {
                    if (callback == null) {
                        channel.invokeMethod(method, args)
                    } else {
                        channel.invokeMethod(method, args, callback)
                    }
                }
            }
        }
    }

}
