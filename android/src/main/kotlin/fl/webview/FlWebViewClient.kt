package fl.webview

import android.graphics.Bitmap
import android.os.Build
import android.os.Handler
import android.webkit.WebResourceError
import android.webkit.WebResourceRequest
import android.webkit.WebView
import android.webkit.WebViewClient
import io.flutter.plugin.common.MethodChannel

class FlWebViewClient(
    private val channel: MethodChannel, private val handler: Handler
) : WebViewClient() {

    var enabledNavigationDelegate = false

    private fun errorCodeToString(errorCode: Int): String {
        when (errorCode) {
            ERROR_AUTHENTICATION -> return "authentication"
            ERROR_BAD_URL -> return "badUrl"
            ERROR_CONNECT -> return "connect"
            ERROR_FAILED_SSL_HANDSHAKE -> return "failedSslHandshake"
            ERROR_FILE -> return "file"
            ERROR_FILE_NOT_FOUND -> return "fileNotFound"
            ERROR_HOST_LOOKUP -> return "hostLookup"
            ERROR_IO -> return "io"
            ERROR_PROXY_AUTHENTICATION -> return "proxyAuthentication"
            ERROR_REDIRECT_LOOP -> return "redirectLoop"
            ERROR_TIMEOUT -> return "timeout"
            ERROR_TOO_MANY_REQUESTS -> return "tooManyRequests"
            ERROR_UNKNOWN -> return "unknown"
            ERROR_UNSAFE_RESOURCE -> return "unsafeResource"
            ERROR_UNSUPPORTED_AUTH_SCHEME -> return "unsupportedAuthScheme"
            ERROR_UNSUPPORTED_SCHEME -> return "unsupportedScheme"
            else -> return "unknown"
        }
    }

    override fun shouldOverrideUrlLoading(view: WebView?, request: WebResourceRequest?): Boolean {
        return navigationRequestResult(enabledNavigationDelegate, view, request)
    }

    fun navigationRequestResult(
        enabledNavigationDelegate: Boolean, webView: WebView?, request: WebResourceRequest?
    ): Boolean {
        if (webView != null && request != null && enabledNavigationDelegate) {
            val url = request.url.toString()
            var headers = request.requestHeaders
            if (headers == null) headers = emptyMap()
            val isForMainFrame = request.isForMainFrame
            val args = mapOf(
                "url" to url, "isForMainFrame" to isForMainFrame
            )
            if (isForMainFrame) {
                handler.post {
                    FlWebViewPlugin.invokeMethod(
                        channel, handler, "onNavigationRequest", args
                    ) { result ->
                        if (result is Boolean && result) {
                            webView.loadUrl(url, headers)
                        }
                    }
                }
            } else {
                FlWebViewPlugin.invokeMethod(
                    channel, handler, "onNavigationRequest", args
                )
            }
            return isForMainFrame
        }
        return false
    }


    override fun onPageStarted(view: WebView?, url: String?, favicon: Bitmap?) {
        super.onPageStarted(view, url, favicon)
        FlWebViewPlugin.invokeMethod(
            channel, handler, "onPageStarted", url
        )
    }


    override fun onPageFinished(view: WebView?, url: String?) {
        super.onPageFinished(view, url)
        FlWebViewPlugin.invokeMethod(
            channel, handler, "onPageFinished", url
        )
    }


    override fun onReceivedError(
        view: WebView?, request: WebResourceRequest?, error: WebResourceError?
    ) {
        super.onReceivedError(view, request, error)
        if (request?.isForMainFrame == true) {
            if (error != null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                onWebResourceError(
                    error.errorCode, error.description.toString(), request.url.toString()
                )
            }
        }
    }


    private fun onWebResourceError(
        errorCode: Int, description: String, failingUrl: String
    ) {
        FlWebViewPlugin.invokeMethod(
            channel, handler, "onWebResourceError", mapOf(
                "errorCode" to errorCode,
                "description" to description,
                "errorType" to errorCodeToString(errorCode),
                "failingUrl" to failingUrl,
            )
        )
    }

    override fun doUpdateVisitedHistory(view: WebView?, url: String?, isReload: Boolean) {
        super.doUpdateVisitedHistory(view, url, isReload)
        FlWebViewPlugin.invokeMethod(
            channel, handler, "onUrlChanged", url
        )
    }


}