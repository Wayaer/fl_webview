package fl.webview

import android.os.Handler
import android.os.Looper
import android.os.Message
import android.webkit.GeolocationPermissions
import android.webkit.WebChromeClient
import android.webkit.WebResourceRequest
import android.webkit.WebView
import android.webkit.WebViewClient
import io.flutter.plugin.common.MethodChannel

class FlWebChromeClient(
    private val methodChannel: MethodChannel,
    private val handler: Handler,
    private val webView: WebView,
    private val flWebViewClient: FlWebViewClient
) : WebChromeClient() {
    var hasProgressTracking = false
    var hasContentSizeTracking = false
    var useProgressGetContentSize = false

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

    override fun onProgressChanged(view: WebView?, progress: Int) {
        super.onProgressChanged(view, progress)
        if (hasProgressTracking) {
            invokeMethod(
                "onProgress", mapOf(
                    "progress" to progress
                )
            )
        }
        if (useProgressGetContentSize && hasContentSizeTracking && progress > 10) {
            view?.let {
                invokeMethod(
                    "onSizeChanged", mapOf(
                        "width" to it.width.toDouble(),
                        "height" to it.height.toDouble(),
                        "contentHeight" to it.height.toDouble(),
                        "contentWidth" to it.width.toDouble(),
                    )
                )
            }
        }
    }

    private fun invokeMethod(method: String, args: Any?) {
        if (handler.looper == Looper.myLooper()) {
            methodChannel.invokeMethod(method, args)
        } else {
            handler.post {
                methodChannel.invokeMethod(method, args)
            }
        }
    }


    override fun onCloseWindow(window: WebView?) {
        super.onCloseWindow(window)
    }

    override fun onGeolocationPermissionsShowPrompt(
        origin: String?, callback: GeolocationPermissions.Callback?
    ) {
        callback?.invoke(origin, true, false);
    }

}
