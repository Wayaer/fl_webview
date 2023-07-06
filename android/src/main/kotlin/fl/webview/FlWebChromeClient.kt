package fl.webview

import android.net.Uri
import android.os.Handler
import android.os.Message
import android.webkit.GeolocationPermissions
import android.webkit.PermissionRequest
import android.webkit.ValueCallback
import android.webkit.WebChromeClient
import android.webkit.WebResourceRequest
import android.webkit.WebView
import android.webkit.WebViewClient
import io.flutter.plugin.common.MethodChannel
import java.io.File

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
            FlWebViewPlugin.invokeMethod(channel, handler, "onProgress", progress)
        }
    }


    override fun onGeolocationPermissionsShowPrompt(
        origin: String?, callback: GeolocationPermissions.Callback?
    ) {
        FlWebViewPlugin.invokeMethod(
            channel, handler, "onGeolocationPermissionsShowPrompt", origin
        ) { result ->
            if (result is Boolean) {
                callback?.invoke(origin, result, false);
            } else {
                super.onGeolocationPermissionsShowPrompt(origin, callback)
            }
        }
    }


    override fun onShowFileChooser(
        webView: WebView?,
        filePathCallback: ValueCallback<Array<Uri>>?,
        fileChooserParams: FileChooserParams?
    ): Boolean {
        val params = mapOf(
            "title" to fileChooserParams?.title,
            "mode" to fileChooserParams?.mode,
            "acceptTypes" to fileChooserParams?.acceptTypes?.toList(),
            "filenameHint" to fileChooserParams?.filenameHint,
            "isCaptureEnabled" to fileChooserParams?.isCaptureEnabled,
        )
        FlWebViewPlugin.invokeMethod(
            channel, handler, "onShowFileChooser", params
        ) { result ->
            val list = (result as ArrayList<*>).map { v -> Uri.fromFile(File(v as String)) }
            filePathCallback?.onReceiveValue(list.toTypedArray())
        }
        return true
    }

    override fun onPermissionRequest(request: PermissionRequest?) {
        FlWebViewPlugin.invokeMethod(
            channel, handler, "onPermissionRequest", request?.resources?.toList()
        ) { result ->
            if (result is Boolean && result) {
                request?.grant(request.resources)
            } else {
                request?.deny()
            }
        }
        super.onPermissionRequest(request)
    }


    override fun onPermissionRequestCanceled(request: PermissionRequest?) {
        super.onPermissionRequestCanceled(request)
        FlWebViewPlugin.invokeMethod(
            channel, handler, "onPermissionRequestCanceled", request?.resources?.toList()
        )
    }

}
