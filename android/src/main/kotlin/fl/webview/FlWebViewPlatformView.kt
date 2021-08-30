package fl.webview

import android.annotation.SuppressLint
import android.content.Context
import android.hardware.display.DisplayManager
import android.os.Handler
import android.os.Looper
import android.view.View
import android.webkit.JavascriptInterface
import android.webkit.WebSettings
import android.webkit.WebStorage
import android.webkit.WebView
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView


class FlWebViewPlatformView(
    context: Context,
    private val methodChannel: MethodChannel,
    params: Map<String, Any?>,
) : PlatformView, MethodChannel.MethodCallHandler {
    private val webView: WebView

    private var flWebViewClient: FlWebViewClient? = null
    private val handler: Handler = Handler(context.mainLooper)
    private val javascriptChannelNames = "javascriptChannelNames"


    init {
        val displayListenerProxy = DisplayListenerProxy()
        val displayManager =
            context.getSystemService(Context.DISPLAY_SERVICE) as DisplayManager
        displayListenerProxy.onPreWebViewInitialization(displayManager)

        /// 初始化webView
        webView = WebView(context)

        webView.apply {
            settings.apply {
                loadsImagesAutomatically = true
                domStorageEnabled = true
                javaScriptCanOpenWindowsAutomatically = true
                layoutAlgorithm = WebSettings.LayoutAlgorithm.TEXT_AUTOSIZING
                mixedContentMode = WebSettings.MIXED_CONTENT_ALWAYS_ALLOW
                setSupportMultipleWindows(true)
                allowFileAccess = true
                setSupportZoom(true)
                setGeolocationEnabled(true)
                useWideViewPort = true
                blockNetworkImage = false
                builtInZoomControls = false
                loadWithOverviewMode = true
                displayZoomControls = true
                allowContentAccess = true
                mediaPlaybackRequiresUserGesture = false
                databaseEnabled = true
            }
        }

        /// 初始化 MethodCallHandler
        methodChannel.setMethodCallHandler(this)

        displayListenerProxy.onPostWebViewInitialization(displayManager)

        /// 初始化相关参数
        applySettings(params["settings"] as Map<String, Any>)

        if (params.containsKey(javascriptChannelNames)) {
            val names = params[javascriptChannelNames] as List<String>?
            names?.let { registerJavaScriptChannelNames(it) }
        }

        if (params.containsKey("userAgent")) {
            webView.settings.userAgentString = params["userAgent"] as String?
        }

        if (params.containsKey("initialUrl")) {
            val url = params["initialUrl"] as String?
            webView.loadUrl(url!!)
        }
    }


    override fun getView(): View {
        return webView
    }

    override fun onMethodCall(
        methodCall: MethodCall,
        result: MethodChannel.Result
    ) {
        when (methodCall.method) {
            "loadUrl" -> loadUrl(methodCall, result)
            "updateSettings" -> {
                applySettings(methodCall.arguments as Map<String, Any>)
                result.success(null)
            }
            "canGoBack" -> result.success(webView.canGoBack())
            "canGoForward" -> result.success(webView.canGoForward())
            "goBack" -> {
                if (webView.canGoBack()) {
                    webView.goBack()
                }
                result.success(null)
            }
            "goForward" -> {
                if (webView.canGoForward()) {
                    webView.goForward()
                }
                result.success(null)
            }
            "reload" -> {
                webView.reload()
                result.success(null)
            }
            "currentUrl" -> result.success(webView.url)
            "evaluateJavascript" -> evaluateJavaScript(methodCall, result)
            "addJavascriptChannels" -> addJavaScriptChannels(methodCall, result)
            "removeJavascriptChannels" -> removeJavaScriptChannels(
                methodCall,
                result
            )
            "clearCache" -> clearCache(result)
            "getTitle" -> result.success(webView.title)
            "scrollTo" -> scrollTo(methodCall, result)
            "scrollBy" -> scrollBy(methodCall, result)
            "getScrollX" -> result.success(webView.scrollX)
            "getScrollY" -> result.success(webView.scrollY)
            else -> result.notImplemented()
        }
    }

    private fun loadUrl(methodCall: MethodCall, result: MethodChannel.Result) {
        val request = methodCall.arguments as Map<String, Any>
        val url = request["url"] as String?
        var headers = request["headers"] as Map<String?, String?>?
        if (headers == null) {
            headers = emptyMap<String?, String>()
        }
        webView.loadUrl(url!!, headers)
        result.success(null)
    }


    private fun evaluateJavaScript(
        methodCall: MethodCall,
        result: MethodChannel.Result
    ) {
        val jsString = methodCall.arguments as String
        webView.evaluateJavascript(jsString) { value -> result.success(value) }
    }

    private fun addJavaScriptChannels(
        methodCall: MethodCall,
        result: MethodChannel.Result
    ) {
        val channelNames = methodCall.arguments as List<String>
        registerJavaScriptChannelNames(channelNames)
        result.success(null)
    }

    private fun removeJavaScriptChannels(
        methodCall: MethodCall,
        result: MethodChannel.Result
    ) {
        val channelNames = methodCall.arguments as List<String>
        for (channelName in channelNames) {
            webView.removeJavascriptInterface(channelName)
        }
        result.success(null)
    }

    private fun clearCache(result: MethodChannel.Result) {
        webView.clearCache(true)
        WebStorage.getInstance().deleteAllData()
        result.success(null)
    }


    private fun scrollTo(methodCall: MethodCall, result: MethodChannel.Result) {
        val request = methodCall.arguments<Map<String, Any>>()
        val x = request["x"] as Int
        val y = request["y"] as Int
        webView.scrollTo(x, y)
        result.success(null)
    }

    private fun scrollBy(methodCall: MethodCall, result: MethodChannel.Result) {
        val request = methodCall.arguments<Map<String, Any>>()
        val x = request["x"] as Int
        val y = request["y"] as Int
        webView.scrollBy(x, y)
        result.success(null)
    }


    private fun applySettings(settings: Map<String, Any>) {
        settings.forEach { entry ->
            val key = entry.key
            val value = entry.value
            when (key) {
                "jsMode" -> {
                    val mode = settings[key] as Int?
                    mode?.let { updateJsMode(it) }
                }
                "hasNavigationDelegate" -> {
                    if (value as Boolean) {
                        getFlWebViewClient()
                        flWebViewClient?.hasContentSizeTracking = value
                    }
                }
                "debuggingEnabled" ->
                    WebView.setWebContentsDebuggingEnabled(value as Boolean)
                "hasProgressTracking" -> {
                    if (value as Boolean) {
                        getFlWebViewClient()
                        val flWebChromeClient =
                            flWebViewClient?.let {
                                FlWebChromeClient(
                                    methodChannel,
                                    handler,
                                    webView,
                                    it
                                )
                            }
                        flWebChromeClient?.hasProgressTracking = true
                        webView.webChromeClient = flWebChromeClient
                    }
                }
                "hasContentSizeTracking" -> {
                    if (value as Boolean) {
                        getFlWebViewClient()
                        flWebViewClient?.hasContentSizeTracking = true
                    }
                }
                "gestureNavigationEnabled" -> {

                }
                "autoMediaPlaybackPolicy" -> {
                    val requireUserGesture = value != 1
                    webView.settings.mediaPlaybackRequiresUserGesture =
                        requireUserGesture
                }
                "userAgent" -> webView.settings.userAgentString = value as
                        String?
                "allowsInlineMediaPlayback" -> {
                }
                else -> throw IllegalArgumentException("Unknown WebView setting: $key")
            }
        }
    }

    private fun getFlWebViewClient() {
        if (flWebViewClient == null) {
            flWebViewClient =
                FlWebViewClient(methodChannel, handler)
        }
        flWebViewClient?.let {
            webView.webViewClient = it
        }
    }

    @SuppressLint("SetJavaScriptEnabled")
    private fun updateJsMode(mode: Int) {
        when (mode) {
            0 -> webView.settings.javaScriptEnabled = false
            1 -> webView.settings.javaScriptEnabled = true
            else -> throw IllegalArgumentException("Trying to set unknown JavaScript mode: $mode")
        }
    }


    @SuppressLint("AddJavascriptInterface")
    private fun registerJavaScriptChannelNames(channelNames: List<String>) {
        for (channelName in channelNames) {
            webView.addJavascriptInterface(
                JavaScriptChannel(methodChannel, channelName, handler),
                channelName
            )
        }
    }


    override fun dispose() {
        methodChannel.setMethodCallHandler(null)
        webView.destroy()
    }


    internal class JavaScriptChannel(
        private val methodChannel: MethodChannel,
        private val javaScriptChannelName: String,
        private val handler: Handler
    ) {
        @JavascriptInterface
        fun postMessage(message: String) {
            val postMessageRunnable = Runnable {
                methodChannel.invokeMethod(
                    "javascriptChannelMessage",
                    mapOf(
                        "channel" to javaScriptChannelName,
                        "message" to message
                    )
                )
            }
            if (handler.looper == Looper.myLooper()) {
                postMessageRunnable.run()
            } else {
                handler.post(postMessageRunnable)
            }
        }
    }
}