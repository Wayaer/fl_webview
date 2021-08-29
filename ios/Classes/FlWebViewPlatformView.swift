import Flutter
import WebKit

public class FlWebViewPlatformView: NSObject, FlutterPlatformView, WKUIDelegate {
    var webView: FlWebView?

    var channel: FlutterMethodChannel

    var navigationDelegate: FlWKNavigationDelegate?
    var progressionDelegate: FlWKProgressionDelegate?

    var javaScriptChannelNames: Set<AnyHashable> = []

    init(_ _frame: CGRect, _ viewId: Int64, _ args: [String: Any?], _ messenger: FlutterBinaryMessenger) {
        channel = FlutterMethodChannel(name: "fl_web_view_\(String(viewId))", binaryMessenger: messenger)
        super.init()
        channel.setMethodCallHandler(handle)
        let userContentController = WKUserContentController()
        let _javaScriptChannelNames = args["javascriptChannelNames"]

        if _javaScriptChannelNames is [AnyHashable] {
            javaScriptChannelNames.formUnion(Set(_javaScriptChannelNames as! [AnyHashable]))
            registerJavaScriptChannels(javaScriptChannelNames, controller: userContentController)
        }

        let settings = args["settings"]

        let configuration = WKWebViewConfiguration()
        applyConfigurationSettings(settings as! [String: Any?], configuration)
        configuration.userContentController = userContentController
        updateAutoMediaPlaybackPolicy(args["autoMediaPlaybackPolicy"] as! NSNumber, configuration)

        webView = FlWebView(frame: _frame, configuration: configuration)

        navigationDelegate = FlWKNavigationDelegate(channel)
        webView!.uiDelegate = self
        webView!.navigationDelegate = navigationDelegate

        if #available(iOS 11.0, *) {
            webView!.scrollView.contentInsetAdjustmentBehavior = .never
            if #available(iOS 13.0, *) {
                webView!.scrollView.automaticallyAdjustsScrollIndicatorInsets = false
            }
        }

        _ = applySettings(settings as! [String: Any])
        _ = loadRequest(args["initialUrl"] as! String?, [:])
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "updateSettings":
            onUpdateSettings(call, result)
            break
        case "loadUrl":
            onLoadUrl(call, result)
        case "canGoBack":
            result(webView!.canGoBack)
        case "canGoForward":
            result(webView!.canGoForward)
            break
        case "goBack":
            webView!.goBack()
            result(nil)
        case "goForward":
            webView!.goForward()
            result(nil)
        case "reload":
            webView!.reload()
            result(nil)
        case "currentUrl":
            result(webView!.url?.absoluteString)
        case "evaluateJavascript":
            onEvaluateJavaScript(call, result)
            break
        case "addJavascriptChannels":
            onAddJavaScriptChannels(call, result)
            break
        case "removeJavascriptChannels":
            onRemoveJavaScriptChannels(call, result)
            break
        case "clearCache":
            clearCache(result)
            break
        case "getTitle":
            result(webView!.title)
            break
        case "scrollTo":
            onScrollTo(call, result)
            break
        case "scrollBy":
            onScrollBy(call, result)
        case "getScrollX":
            let offsetX = Int(webView!.scrollView.contentOffset.x)
            result(NSNumber(value: offsetX))
            break
        case "getScrollY":
            let offsetY = Int(webView!.scrollView.contentOffset.y)
            result(NSNumber(value: offsetY))
            break
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    func registerJavaScriptChannels(
        _ channelNames: Set<AnyHashable>?, controller userContentController: WKUserContentController?) {
        for channelName in channelNames ?? [] {
            guard let channelName = channelName as? String else {
                continue
            }
            let channel = FlWKJavaScriptChannel(
                channel,
                channelName)
            userContentController?.add(channel, name: channelName)
            let wrapperSource = "window.\(channelName) = webkit.messageHandlers.\(channelName);"
            let wrapperScript = WKUserScript(
                source: wrapperSource,
                injectionTime: .atDocumentStart,
                forMainFrameOnly: false)
            userContentController?.addUserScript(wrapperScript)
        }
    }

    func onUpdateSettings(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        let error = applySettings(call.arguments as! [String: Any?])
        if error == nil {
            result(nil)
            return
        }
        result(FlutterError(code: "updateSettings_failed", message: error, details: nil))
    }

    func onLoadUrl(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        let args = call.arguments as! [String: Any?]
        if !loadRequest(args["url"] as! String?, [:]) {
            result(
                FlutterError(
                    code: "loadUrl_failed",
                    message: "Failed parsing the URL",
                    details: "Request was: '\(call.arguments ?? "")'"))
        } else {
            result(nil)
        }
    }

    func onEvaluateJavaScript(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        let jsString = call.arguments as! String
        webView!.evaluateJavaScript(jsString) { _, error in
            if let error = error {
                result(
                    FlutterError(
                        code: "evaluateJavaScript_failed",
                        message: "Failed evaluating JavaScript",
                        details: "JavaScript string was: '\(jsString)'\n\(error)"))
            }
        }
    }

    func onAddJavaScriptChannels(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        let channelNames = call.arguments as! [String]
        var channelNamesSet: Set<AnyHashable> = []
        channelNames.forEach { channelName in
            _ = channelNamesSet.insert(channelName)
            _ = javaScriptChannelNames.insert(channelName)
        }

        registerJavaScriptChannels(
            channelNamesSet,
            controller: webView!.configuration.userContentController)
        result(nil)
    }

    func onRemoveJavaScriptChannels(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        webView!.configuration.userContentController.removeAllUserScripts()
        for channelName in javaScriptChannelNames {
            webView!.configuration.userContentController.removeScriptMessageHandler(forName: channelName as! String)
        }

        let channelNamesToRemove = call.arguments as! [String: Any?]
        channelNamesToRemove.forEach { (key: String, _: Any?) in
            javaScriptChannelNames.remove(key)
        }
        registerJavaScriptChannels(
            javaScriptChannelNames,
            controller: webView!.configuration.userContentController)
        result(nil)
    }

    func clearCache(_ result: @escaping FlutterResult) {
        let cacheDataTypes = WKWebsiteDataStore.allWebsiteDataTypes()
        let dataStore = WKWebsiteDataStore.default()
        let dateFrom = Date(timeIntervalSince1970: 0)
        dataStore.removeData(
            ofTypes: cacheDataTypes,
            modifiedSince: dateFrom) {
            result(nil)
        }
    }

    func onScrollTo(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        let arguments = call.arguments as! [String: Any]
        let x = arguments["x"] as! Double
        let y = arguments["y"] as! Double
        webView!.scrollView.contentOffset = CGPoint(x: CGFloat(x), y: CGFloat(y))
        result(nil)
    }

    func onScrollBy(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        let contentOffset = webView!.scrollView.contentOffset

        let arguments = call.arguments as! [String: Any]
        let x = CGFloat(arguments["x"] as! Double) + contentOffset.x
        let y = CGFloat(arguments["y"] as! Double) + contentOffset.y
        webView!.scrollView.contentOffset = CGPoint(x: CGFloat(x), y: CGFloat(y))
        result(nil)
    }

    func applySettings(_ settings: [String: Any?]) -> String? {
        var unknownKeys: [String] = []
        settings.forEach { (key: String, value: Any?) in
            switch key {
            case "jsMode":
                updateJsMode(value as! NSNumber?)
            case "hasNavigationDelegate":
                navigationDelegate!.hasDartNavigationDelegate = value as! Bool
            case "hasProgressTracking":
                progressionDelegate = FlWKProgressionDelegate(webView!, channel)
            case "debuggingEnabled":
                // no-op debugging is always enabled on iOS.
                break
            case "gestureNavigationEnabled":
                webView!.allowsBackForwardNavigationGestures = value as! Bool
            case "userAgent":
                webView!.customUserAgent = value as! String?
            default:
                unknownKeys.append(key)
            }
        }
        if unknownKeys.isEmpty {
            return nil
        }
        return "fl_webview: unknown setting keys:\(unknownKeys.joined(separator: ","))"
    }

    func applyConfigurationSettings(_ settings: [String: Any?], _ configuration: WKWebViewConfiguration) {
        settings.forEach { (key: String, value: Any?) in
            switch key {
            case "allowsInlineMediaPlayback":
                let allowsInlineMediaPlayback = value as? NSNumber
                configuration.allowsInlineMediaPlayback = allowsInlineMediaPlayback?.boolValue ?? false
            default:
                break
            }
        }
    }

    func updateJsMode(_ mode: NSNumber?) {
        let preferences = webView!.configuration.preferences
        switch mode?.intValue ?? 0 {
        case 0 /* disabled */:
            preferences.javaScriptEnabled = false
        case 1 /* unrestricted */:
            preferences.javaScriptEnabled = true
        default:
            print("fl_webview: unknown JavaScript mode: \(mode ?? 0)")
        }
    }

    func updateAutoMediaPlaybackPolicy(_ policy: NSNumber, _ configuration: WKWebViewConfiguration) {
        switch policy.intValue {
        case 0:
            configuration.mediaTypesRequiringUserActionForPlayback = .all
            break
        case 1:
            configuration.mediaTypesRequiringUserActionForPlayback = .audio
            break
        default:
            print("fl_webview: unknown auto media playback policy: \(policy)")
        }
    }

    func loadRequest(_ url: String?, _ headers: [String: String]?) -> Bool {
        if url != nil {
            let nsUrl = URL(string: url!)
            if nsUrl == nil {
                return false
            }
            var request = URLRequest(url: nsUrl!)
            if headers != nil {
                request.allHTTPHeaderFields = headers
            }
            webView!.load(request)
        }
        return false
    }

    func registerJavaScriptChannels(
        _ channelNames: Set<AnyHashable>,
        _ userContentController: WKUserContentController?
    ) {
        for channelName in channelNames {
            guard let channelName = channelName as? String else {
                continue
            }
            let channel = FlWKJavaScriptChannel(channel, channelName)
            userContentController?.add(channel, name: channelName)
            let wrapperSource = "window.\(channelName) = webkit.messageHandlers.\(channelName);"
            let wrapperScript = WKUserScript(
                source: wrapperSource,
                injectionTime: .atDocumentStart,
                forMainFrameOnly: false)
            userContentController?.addUserScript(wrapperScript)
        }
    }

    public func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if !(navigationAction.targetFrame?.isMainFrame ?? false) {
            webView.load(navigationAction.request)
        }

        return nil
    }

    public func view() -> UIView {
        webView!
    }
}
