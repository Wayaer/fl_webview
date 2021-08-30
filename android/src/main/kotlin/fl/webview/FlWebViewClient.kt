package fl.webview

import android.graphics.Bitmap
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.webkit.WebResourceError
import android.webkit.WebResourceRequest
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.annotation.RequiresApi
import io.flutter.plugin.common.MethodChannel
import java.util.*

class FlWebViewClient(
    private val methodChannel: MethodChannel,
    private val handler: Handler
) : WebViewClient() {
    var hasNavigationDelegate = false
    var hasContentSizeTracking = false

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
        }
        val message = String.format(
            Locale.getDefault(),
            "Could not find a string for errorCode: %d",
            errorCode
        )
        throw IllegalArgumentException(message)
    }

    override fun shouldOverrideUrlLoading(
        view: WebView?,
        request: WebResourceRequest?
    ): Boolean {
        if (hasNavigationDelegate && view != null && request != null) {
            notifyOnNavigationRequest(
                request.url.toString(),
                request.requestHeaders,
                view,
                request.isForMainFrame
            )
            return request.isForMainFrame
        }
        return false
    }


    override fun onPageStarted(view: WebView?, url: String?, favicon: Bitmap?) {
        super.onPageStarted(view, url, favicon)
        invokeMethod(
            "onPageStarted", mapOf(
                "url" to url
            )
        )
    }


    override fun onPageFinished(view: WebView?, url: String?) {
        super.onPageFinished(view, url)
        invokeMethod(
            "onPageFinished", mapOf(
                "url" to url
            )
        )
        view?.contentHeight?.let { onContentSize(it) }
    }

    @RequiresApi(Build.VERSION_CODES.M)
    override fun onReceivedError(
        view: WebView,
        request: WebResourceRequest,
        error: WebResourceError
    ) {
        super.onReceivedError(view, request, error)
        if (request.isForMainFrame) {
            onWebResourceError(
                error.errorCode,
                error.description.toString(),
                request.url.toString()
            )
        }
    }

    private fun onContentSize(height: Int) {
        if (hasContentSizeTracking) {
            invokeMethod(
                "onContentSize", mapOf(
                    "width" to 0.0,
                    "height" to height.toDouble(),
                )
            )
        }
    }


    private fun onWebResourceError(
        errorCode: Int, description: String, failingUrl: String
    ) {
        invokeMethod(
            "onWebResourceError", mapOf(
                "errorCode" to errorCode,
                "description" to description,
                "errorType" to errorCodeToString(errorCode),
                "failingUrl" to failingUrl,
            )
        )
    }

    private fun invokeMethod(method: String, args: Map<String, Any?>) {
        if (handler.looper == Looper.myLooper()) {
            methodChannel.invokeMethod(method, args)
        } else {
            handler.post {
                methodChannel.invokeMethod(method, args)
            }
        }
    }

    private fun notifyOnNavigationRequest(
        url: String,
        headers: Map<String, String>?,
        webView: WebView,
        isMainFrame: Boolean
    ) {
        val args = HashMap<String, Any>()
        args["url"] = url
        args["isForMainFrame"] = isMainFrame
        if (isMainFrame) {
            handler.post {
                methodChannel.invokeMethod(
                    "navigationRequest",
                    args,
                    OnNavigationRequestResult(url, headers, webView)
                )
            }
        } else {
            invokeMethod("navigationRequest", args)
        }
    }

    private class OnNavigationRequestResult(
        private val url: String,
        private val headers: Map<String, String>?,
        private val webView: WebView
    ) : MethodChannel.Result {
        override fun success(shouldLoad: Any?) {
            val typedShouldLoad = shouldLoad as Boolean?
            if (typedShouldLoad!!) {
                webView.loadUrl(url, headers!!)
            }
        }

        override fun error(errorCode: String, s1: String?, o: Any?) {
            throw IllegalStateException("navigationRequest calls must succeed")
        }

        override fun notImplemented() {
            throw IllegalStateException(
                "navigationRequest must be implemented by the webview method channel"
            )
        }
    }


}