package fl.webview

import android.os.Handler
import android.os.Looper
import android.os.Message
import android.util.Log
import android.webkit.GeolocationPermissions
import android.webkit.WebChromeClient
import android.webkit.WebResourceRequest
import android.webkit.WebView
import android.webkit.WebViewClient
import io.flutter.plugin.common.MethodChannel

class FlWebChromeClient(
    private val channel: MethodChannel,
    private val handler: Handler,
    private val webView: WebView,
    private val flWebViewClient: FlWebViewClient
) : WebChromeClient() {

    var enabledProgressChanged = false


    override fun onCreateWindow(
        view: WebView, isDialog: Boolean, isUserGesture: Boolean, resultMsg: Message
    ): Boolean {
        val webViewClient: WebViewClient = object : WebViewClient() {
            override fun shouldOverrideUrlLoading(
                view: WebView, request: WebResourceRequest
            ): Boolean {
                val url = request.url.toString()
                if (!flWebViewClient.shouldOverrideUrlLoading(webView, request)) {
                    webView.loadUrl(url)
                }
                return true
            }
        }
        val newWebView = WebView(view.context)
        newWebView.webViewClient = webViewClient
        val transport = resultMsg.obj as WebView.WebViewTransport
        transport.webView = newWebView
        resultMsg.sendToTarget()
        return true
    }

    var lastProgress: Int = 0

    override fun onProgressChanged(view: WebView?, progress: Int) {
        super.onProgressChanged(view, progress)
        if (enabledProgressChanged) {
            if (lastProgress == progress || progress < lastProgress) return
            lastProgress = progress
            invokeMethod("onProgress", progress)
        }
    }

    private fun invokeMethod(method: String, args: Any?) {
        if (handler.looper == Looper.myLooper()) {
            channel.invokeMethod(method, args)
        } else {
            handler.post {
                channel.invokeMethod(method, args)
            }
        }
    }


    override fun onGeolocationPermissionsShowPrompt(
        origin: String?, callback: GeolocationPermissions.Callback?
    ) {
        callback?.invoke(origin, true, false);
    }

}
