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
    private val channel: MethodChannel,
    private val handler: Handler,
    private val flWebViewClient: FlWebViewClient
) : WebChromeClient() {

    var enabledProgressChanged = false
    var enabledNavigationDelegate = false

    override fun onCreateWindow(
        webView: WebView, isDialog: Boolean, isUserGesture: Boolean, resultMsg: Message
    ): Boolean {
        val newWebView = WebView(webView.context)
        newWebView.webViewClient = object : WebViewClient() {
            override fun shouldOverrideUrlLoading(
                view: WebView?, request: WebResourceRequest
            ): Boolean {
                return flWebViewClient.navigationRequestResult(
                    enabledNavigationDelegate, webView, request
                )
            }
        }

        val transport = resultMsg.obj as WebView.WebViewTransport
        transport.webView = newWebView
        resultMsg.sendToTarget()
        return true
    }

    private var lastProgress: Int = 0

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
