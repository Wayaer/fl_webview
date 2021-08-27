package fl.webview

import android.content.Context
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class FlWebViewPlugin : FlutterPlugin {
    private var cookieManager: FlCookieManager? = null

    override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        val messenger = binding.binaryMessenger
        binding.platformViewRegistry.registerViewFactory(
            "fl_web_view",
            FlWebViewFactory(messenger)
        )
        cookieManager = FlCookieManager(messenger)
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        if (cookieManager != null) {
            cookieManager!!.dispose()
            cookieManager = null
        }
    }


    class FlWebViewFactory(
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
}
