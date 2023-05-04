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
    params: Map<*, *>,
) : PlatformView, MethodChannel.MethodCallHandler {
    private val webView: FlWebView

    private var flWebViewClient: FlWebViewClient? = null
    private var flWebChromeClient: FlWebChromeClient? = null
    private val handler: Handler = Handler(context.mainLooper)

    init {
        val displayListenerProxy = DisplayListenerProxy()
        val displayManager = context.getSystemService(Context.DISPLAY_SERVICE) as DisplayManager
        displayListenerProxy.onPreWebViewInitialization(displayManager)
        webView = FlWebView(context, methodChannel, handler)
        webView.apply {
            settings.apply {
                loadsImagesAutomatically = true
                domStorageEnabled = true
                databaseEnabled = true
                cacheMode = WebSettings.LOAD_DEFAULT
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
            }
        }
        /// 初始化 MethodCallHandler
        methodChannel.setMethodCallHandler(this)
        displayListenerProxy.onPostWebViewInitialization(displayManager)
        /// 初始化相关参数
//        applySettings(params["settings"] as HashMap<*, *>)

//        if (params.containsKey(javascriptChannelNames)) {
//            val names = params[javascriptChannelNames] as List<*>?
//            names?.let { registerJavaScriptChannelNames(it) }
//        }
//
//        val userAgent = params["userAgent"] as String?
//        if (userAgent != null) {
//            webView.settings.userAgentString = webView.settings.userAgentString + userAgent
//        }
//
//        val urlData = params["initialUrl"] as Map<*, *>?
//        if (urlData != null) loadUrl(urlData)
//        val htmlData = params["initialHtml"] as Map<*, *>?
//        if (htmlData != null) loadHtml(htmlData)
    }


    override fun getView(): View {
        return webView
    }

    @SuppressLint("ClickableViewAccessibility")
    override fun onMethodCall(
        call: MethodCall, result: MethodChannel.Result
    ) {
        when (call.method) {
            "loadUrl" -> {
                loadUrl(call.arguments as Map<*, *>)
                result.success(null)
            }

            "setWebSettings" -> {
                setWebSettings(call.arguments as Map<*, *>)
                result.success(null)
            }

            "isScroll" -> {
                webView.isScroll = call.arguments as Boolean
                result.success(true)
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
            "evaluateJavascript" -> {
                webView.evaluateJavascript(call.arguments as String) { value -> result.success(value) }
            }

            "addJavascriptChannel" -> {
                registerJavaScriptChannelName(call.arguments as String)
                result.success(null)
            }

            "removeJavascriptChannel" -> {
                webView.removeJavascriptInterface(call.arguments as String)
                result.success(null)
            }

            "clearCache" -> clearCache(result)
            "getTitle" -> result.success(webView.title)
            "scrollTo" -> scrollTo(call, result)
            "scrollBy" -> scrollBy(call, result)
            "getScrollX" -> result.success(webView.scrollX)
            "getScrollY" -> result.success(webView.scrollY)
            else -> result.notImplemented()
        }
    }

    private fun loadUrl(args: Map<*, *>) {
        val url = args["url"] as String
        var headers = args["headers"] as Map<String, String>?
        if (headers == null) headers = emptyMap()
        webView.loadUrl(url, headers)
    }

    private fun loadHtml(args: Map<*, *>) {
        val html = args["html"] as String
        val mimeType = args["mimeType"] as String
        val encoding = args["encoding"] as String
        webView.loadData(html, mimeType, encoding)
    }


    private fun clearCache(result: MethodChannel.Result) {
        webView.clearCache(true)
        WebStorage.getInstance().deleteAllData()
        result.success(null)
    }


    private fun scrollTo(methodCall: MethodCall, result: MethodChannel.Result) {
        val request = methodCall.arguments<Map<String, Any>>()
        val x = request?.get("x") as Int
        val y = request["y"] as Int
        webView.scrollTo(x, y)
        result.success(null)
    }

    private fun scrollBy(methodCall: MethodCall, result: MethodChannel.Result) {
        val request = methodCall.arguments<Map<String, Any>>()
        val x = request?.get("x") as Int
        val y = request["y"] as Int
        webView.scrollBy(x, y)
        result.success(null)
    }


    private fun setWebSettings(settings: Map<*, *>) {
        settings.forEach { entry ->
            val key = entry.key
            val value = entry.value
            when (key) {
                "javascriptMode" -> {
                    val mode = settings[key] as Int?
                    mode?.let { webView.settings.javaScriptEnabled = it == 1 }
                }

                "hasNavigationDelegate" -> {
                    if (value as Boolean) {
                        getFlWebViewClient()
                        flWebViewClient?.hasNavigationDelegate = value
                    }
                }

                "debuggingEnabled" -> WebView.setWebContentsDebuggingEnabled(value as Boolean)
                "hasProgressTracking" -> {
                    if (value as Boolean) {
                        getFlWebChromeClient()
                        flWebChromeClient?.hasProgressTracking = true
                    }
                }

                "hasContentSizeTracking" -> {
                    webView.hasContentSizeTracking = value as Boolean
                    if (value) {
                        getFlWebChromeClient()
                        flWebChromeClient?.hasContentSizeTracking = true
                        flWebViewClient?.hasContentSizeTracking = true
                    }
                }

                "useProgressGetContentSize" -> {
                    webView.useProgressGetContentSize = value as Boolean
                    getFlWebChromeClient()
                    flWebChromeClient?.useProgressGetContentSize = value
                    flWebViewClient?.useFinishedGetContentSize = value
                }

                "hasScrollChangedTracking" -> {
                    webView.hasScrollChangedTracking = value as Boolean
                }

                "gestureNavigationEnabled" -> {
                }

                "autoMediaPlaybackPolicy" -> {
                    val requireUserGesture = value != 1
                    webView.settings.mediaPlaybackRequiresUserGesture = requireUserGesture
                }

                "userAgent" -> {
                    val userAgent = value as String?
                    if (userAgent != null) {
                        webView.settings.userAgentString =
                            webView.settings.userAgentString + userAgent
                    }
                }

                "allowsInlineMediaPlayback" -> {
                }

                else -> throw IllegalArgumentException("Unknown WebView setting: $key")
            }
        }
    }


    private fun getFlWebChromeClient() {
        getFlWebViewClient()
        if (flWebChromeClient == null) {
            flWebChromeClient = FlWebChromeClient(
                methodChannel, handler, webView, flWebViewClient!!
            )
        }
        flWebChromeClient?.let {
            webView.webChromeClient = it
        }
    }

    private fun getFlWebViewClient() {
        if (flWebViewClient == null) {
            flWebViewClient = FlWebViewClient(methodChannel, handler)
        }
        flWebViewClient?.let {
            webView.webViewClient = it
        }
    }


    @SuppressLint("AddJavascriptInterface")
    private fun registerJavaScriptChannelName(channelName: String) {
        webView.addJavascriptInterface(
            JavaScriptChannel(methodChannel, channelName, handler), channelName
        )
    }


    override fun dispose() {
        methodChannel.setMethodCallHandler(null)
        webView.destroy()
    }


    internal class JavaScriptChannel(
        private val methodChannel: MethodChannel,
        private val name: String,
        private val handler: Handler
    ) {
        @JavascriptInterface
        fun postMessage(message: String) {
            val postMessageRunnable = Runnable {
                methodChannel.invokeMethod(
                    "onJavascriptChannelMessage", mapOf(
                        "channel" to name, "message" to message
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

    @SuppressLint("ViewConstructor")
    internal class FlWebView(
        context: Context,
        private val methodChannel: MethodChannel,
        private val currentHandler: Handler,
    ) : WebView(context) {
        var isScroll = true
        var hasScrollChangedTracking = false
        var hasContentSizeTracking = false
        var useProgressGetContentSize = false

        override fun onSizeChanged(width: Int, height: Int, oldWidth: Int, oldHeight: Int) {
            super.onSizeChanged(width, height, oldWidth, oldHeight)
            if (hasContentSizeTracking && !useProgressGetContentSize) {
                invokeMethod(
                    "onSizeChanged", mapOf(
                        "width" to width.toDouble(),
                        "height" to height.toDouble(),
                        "contentHeight" to contentHeight.toDouble(),
                        "contentWidth" to width.toDouble(),
                    )
                )
            }
        }

        override fun onScrollChanged(
            left: Int, top: Int, oldl: Int, oldt: Int
        ) {
            if (hasScrollChangedTracking) {
                val scale = resources.displayMetrics.density
                val position = when {
                    scrollY == 0 -> 0
                    (contentHeight * scale - height - scrollY) <= 5 -> 2
                    else -> 1
                }
                val map = mapOf(
                    "x" to (left / scale).toDouble(),
                    "y" to (top / scale).toDouble(),
                    "width" to width.toDouble(),
                    "height" to height.toDouble(),
                    "contentWidth" to width.toDouble(),
                    "contentHeight" to contentHeight.toDouble(),
                    "position" to position
                )
                invokeMethod("onScrollChanged", map)
            }
        }


        private fun invokeMethod(method: String, args: Any?) {
            if (currentHandler.looper == Looper.myLooper()) {
                methodChannel.invokeMethod(method, args)
            } else {
                currentHandler.post {
                    methodChannel.invokeMethod(method, args)
                }
            }
        }


        override fun overScrollBy(
            deltaX: Int,
            deltaY: Int,
            scrollX: Int,
            scrollY: Int,
            scrollRangeX: Int,
            scrollRangeY: Int,
            maxOverScrollX: Int,
            maxOverScrollY: Int,
            isTouchEvent: Boolean
        ): Boolean {
            if (isScroll) {
                return super.overScrollBy(
                    deltaX,
                    deltaY,
                    scrollX,
                    scrollY,
                    scrollRangeX,
                    scrollRangeY,
                    maxOverScrollX,
                    maxOverScrollY,
                    isTouchEvent
                )
            }
            return false
        }
    }
}