package fl.webview

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.Canvas
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
    private val channel: MethodChannel,
    params: Map<*, *>,
) : PlatformView, MethodChannel.MethodCallHandler {
    private val webView: FlWebView
    private var flWebViewClient: FlWebViewClient
    private var flWebChromeClient: FlWebChromeClient
    private val handler: Handler = Handler(context.mainLooper)

    init {
        val displayListenerProxy = DisplayListenerProxy()
        val displayManager = context.getSystemService(Context.DISPLAY_SERVICE) as DisplayManager
        displayListenerProxy.onPreWebViewInitialization(displayManager)
        flWebViewClient = FlWebViewClient(channel, handler)
        webView = FlWebView(context, channel, handler)
        flWebChromeClient = FlWebChromeClient(channel, handler, flWebViewClient)
        applyWebSettings(params)
        webView.apply {
            webViewClient = flWebViewClient
            webChromeClient = flWebChromeClient
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
        channel.setMethodCallHandler(this)
        displayListenerProxy.onPostWebViewInitialization(displayManager)
    }


    override fun getView(): View {
        return webView
    }

    @SuppressLint("ClickableViewAccessibility")
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "loadUrl" -> {
                val args = call.arguments as Map<*, *>
                webView.loadUrl(args["url"] as String, args["headers"] as HashMap<String, String>)
                result.success(true)
            }

            "loadData" -> {
                val args = call.arguments as Map<*, *>
                webView.loadDataWithBaseURL(
                    args["baseURL"] as String?,
                    args["data"] as String,
                    args["mimeType"] as String?,
                    args["encoding"] as String?,
                    args["historyUrl"] as String?
                )
                result.success(true)
            }

            "applyWebSettings" -> {
                applyWebSettings(call.arguments as Map<*, *>)
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
            "getScrollXY" -> result.success(mapOf("x" to webView.scrollX, "y" to webView.scrollY))
            "getWebViewSize" -> result.success(
                mapOf(
                    "width" to webView.width.toDouble(),
                    "height" to webView.height.toDouble(),
                    "contentHeight" to webView.contentHeight.toDouble(),
                    "contentWidth" to webView.width.toDouble(),
                )
            )

            "getUserAgent" -> result.success(webView.settings.userAgentString)
            "setUserAgent" -> {
                webView.settings.userAgentString = call.arguments as String
                result.success(webView.settings.userAgentString)
            }

            "enabledScroll" -> {
                webView.enabledScroll = call.arguments as Boolean
                result.success(true)
            }

            "dispose" -> {
                webView.destroy();
                channel.setMethodCallHandler(null)
            }

            else -> result.notImplemented()
        }
    }

    private fun applyWebSettings(settings: Map<*, *>) {
        settings.forEach { entry ->
            val key = entry.key
            val value = entry.value
            when (key) {
                "enabledNavigationDelegate" -> {
                    flWebViewClient.enabledNavigationDelegate = value as Boolean
                    flWebChromeClient.enabledNavigationDelegate = value
                }

                "enabledProgressChanged" -> flWebChromeClient.enabledProgressChanged =
                    value as Boolean

                "enableSizeChanged" -> webView.enableSizeChanged = value as Boolean
                "enabledScrollChanged" -> webView.enabledScrollChanged = value as Boolean
                "javascriptMode" -> {
                    val mode = settings[key] as Int?
                    mode?.let { webView.settings.javaScriptEnabled = it == 1 }
                }

                "allowsAutoMediaPlayback" -> webView.settings.mediaPlaybackRequiresUserGesture =
                    !(value as Boolean)

                "enabledZoom" -> webView.settings.setSupportZoom(value as Boolean)
                "enabledDebugging" -> WebView.setWebContentsDebuggingEnabled(value as Boolean)
            }
        }
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


    @SuppressLint("AddJavascriptInterface")
    private fun registerJavaScriptChannelName(channelName: String) {
        webView.addJavascriptInterface(
            JavaScriptChannel(channel, channelName, handler), channelName
        )
    }


    override fun dispose() {
        channel.setMethodCallHandler(null)
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
        private val channel: MethodChannel,
        private val handler: Handler,
    ) : WebView(context) {
        var enabledScroll = true
        var enabledScrollChanged = false
        var enableSizeChanged = false


        override fun onScrollChanged(
            left: Int, top: Int, oldl: Int, oldt: Int
        ) {
            if (enabledScrollChanged) {
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
            if (handler.looper == Looper.myLooper()) {
                channel.invokeMethod(method, args)
            } else {
                handler.post {
                    channel.invokeMethod(method, args)
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
            if (enabledScroll) {
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

        private var lastContentHeight: Int = 0
        override fun onDraw(canvas: Canvas?) {
            super.onDraw(canvas)
            if (enableSizeChanged) {
                if (lastContentHeight == contentHeight || contentHeight < lastContentHeight) return
                lastContentHeight = contentHeight
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
    }
}