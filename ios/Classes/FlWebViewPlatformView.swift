import Flutter
import WebKit

public class FlWebViewPlatformView: NSObject, FlutterPlatformView, WKUIDelegate {
    var webView: FlWebView?

    var channel: FlutterMethodChannel

    var navigationDelegate: FlWKNavigationDelegate?
    var progressionDelegate: FlWKProgressionDelegate?
    var contentSizeDelegate: FlWKContentSizeDelegate?
    var scrollChangedDelegate: FlWKScrollChangedDelegate?

    var javaScriptChannelNames: [String] = []

    init(_ _frame: CGRect, _ viewId: Int64, _ args: [String: Any?], _ messenger: FlutterBinaryMessenger) {
        channel = FlutterMethodChannel(name: "fl.webview/\(viewId)", binaryMessenger: messenger)
        super.init()
        channel.setMethodCallHandler(handle)

//        let _javaScriptChannelNames = args["javascriptChannelNames"]
//        if _javaScriptChannelNames is [AnyHashable] {
//            javaScriptChannelNames.formUnion(Set(_javaScriptChannelNames as! [AnyHashable]))
//            registerJavaScriptChannels(javaScriptChannelNames, controller: userContentController)
//        }

//        let settings = args["settings"]
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = WKUserContentController()
        if args["deleteWindowSharedWorker"] as! Bool {
            let dropSharedWorkersScript = WKUserScript(source: "delete window.SharedWorker;", injectionTime: WKUserScriptInjectionTime.atDocumentStart, forMainFrameOnly: false)
            configuration.userContentController.addUserScript(dropSharedWorkersScript)
        }
        webView = FlWebView(frame: _frame, configuration: configuration)
        webView!.uiDelegate = self

//        navigationDelegate = FlWKNavigationDelegate(channel)
//        webView!.navigationDelegate = navigationDelegate

//        _ = applySettings(settings as! [String: Any])

        if #available(iOS 11.0, *) {
            webView!.scrollView.contentInsetAdjustmentBehavior = .never
            if #available(iOS 13.0, *) {
                webView!.scrollView.automaticallyAdjustsScrollIndicatorInsets = false
            }
        }
//        let urlData = args["initialUrl"] as? [String: Any?]
//        if urlData != nil {
//            _ = loadUrl(urlData!)
//        }
//        let htmlData = args["initialHtml"] as? [String: Any?]
//        if htmlData != nil {
//            _ = loadHtml(htmlData!)
//        }
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "updateSettings":
            onUpdateSettings(call, result)
        case "loadUrl":
            let args = call.arguments as! [String: Any?]
            if !loadUrl(args) {
                result(
                    FlutterError(
                        code: "loadUrl_failed",
                        message: "Failed parsing the URL",
                        details: "Request was: '\(call.arguments ?? "")'"))
            } else {
                result(nil)
            }
        case "canGoBack":
            result(webView!.canGoBack)
        case "canGoForward":
            result(webView!.canGoForward)
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
            evaluateJavaScript(call, result)
        case "addJavascriptChannel":
            addJavaScriptChannel(call, result)
        case "removeJavascriptChannel":
            removeJavaScriptChannel(call, result)
        case "clearCache":
            clearCache(result)
        case "getTitle":
            result(webView!.title)
        case "scrollTo":
            onScrollTo(call, result)
        case "scrollBy":
            onScrollBy(call, result)
        case "getScrollX":
            let offsetX = Int(webView!.scrollView.contentOffset.x)
            result(NSNumber(value: offsetX))
        case "getScrollY":
            let offsetY = Int(webView!.scrollView.contentOffset.y)
            result(NSNumber(value: offsetY))
        case "scrollEnabled":
            webView?.scrollView.isScrollEnabled = call.arguments as! Bool
            result(true)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    func registerJavaScriptChannels(_ channelNames: [String]) {
        for channelName in channelNames {
            let channel = FlWKJavaScriptChannel(
                channel,
                channelName)
            webView?.configuration.userContentController.add(channel, name: channelName)
            let wrapperScript = WKUserScript(
                source: channelName,
                injectionTime: .atDocumentStart,
                forMainFrameOnly: false)
            webView?.configuration.userContentController.addUserScript(wrapperScript)
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

    func evaluateJavaScript(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        let jsString = call.arguments as! String
        webView!.evaluateJavaScript(jsString) { value, error in
            if let error = error {
                result(
                    FlutterError(
                        code: "evaluateJavaScript_failed",
                        message: "Failed evaluating JavaScript",
                        details: "JavaScript string was: '\(jsString)'\n\(error)"))
            } else {
                result(value)
            }
        }
    }

    func addJavaScriptChannel(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        let channelName = call.arguments as! String
        javaScriptChannelNames.append(channelName)
        registerJavaScriptChannels(javaScriptChannelNames)
        result(nil)
    }

    func removeJavaScriptChannel(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        webView!.configuration.userContentController.removeAllUserScripts()
        for channelName in javaScriptChannelNames {
            webView!.configuration.userContentController.removeScriptMessageHandler(forName: channelName)
        }
        javaScriptChannelNames.removeAll { value in
            value == call.arguments as! String
        }
        registerJavaScriptChannels(javaScriptChannelNames)
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
            case "javascriptMode":
                webView!.configuration.preferences.javaScriptEnabled = (value as? NSNumber)?.intValue == 1
            case "hasNavigationDelegate":
                navigationDelegate!.enabledNavigationDelegate = value as! Bool
            case "hasProgressTracking":
                if value as! Bool {
                    progressionDelegate = FlWKProgressionDelegate(webView!, channel)
                } else {
                    progressionDelegate?.stopObserving(webView)
                    progressionDelegate = nil
                }
            case "hasContentSizeTracking":
                if value as! Bool {
                    if contentSizeDelegate == nil {
                        contentSizeDelegate = FlWKContentSizeDelegate(webView!, channel)
                    }
                } else {
                    contentSizeDelegate?.stopObserving(webView)
                }
            case "useProgressGetContentSize":
                break
            case "hasScrollChangedTracking":
                if value as! Bool {
                    if scrollChangedDelegate == nil {
                        scrollChangedDelegate = FlWKScrollChangedDelegate(webView!, channel)
                        webView!.scrollView.delegate = scrollChangedDelegate
                    }
                } else {
                    webView!.scrollView.delegate = nil
                    scrollChangedDelegate = nil
                }
            case "debuggingEnabled":
                break
            case "gestureNavigationEnabled":
                webView!.allowsBackForwardNavigationGestures = value as! Bool
            case "userAgent":
                let userAgent = value as? String
                if userAgent != nil {
                    webView!.setUserAgent(userAgent: userAgent!)
                }
            case "allowsInlineMediaPlayback":
                let allowsInlineMediaPlayback = value as? NSNumber
                webView?.configuration.allowsInlineMediaPlayback = allowsInlineMediaPlayback?.boolValue ?? false
            case "autoMediaPlaybackPolicy":
                let policy = value as! Int
                switch policy {
                case 0:
                    webView?.configuration.mediaTypesRequiringUserActionForPlayback = .all
                case 1:
                    webView?.configuration.mediaTypesRequiringUserActionForPlayback = .audio
                default:
                    print("fl_webview: unknown auto media playback policy: \(String(describing: value))")
                }
            default:
                unknownKeys.append(key)
            }
        }
        if unknownKeys.isEmpty {
            return nil
        }
        return "fl_webview: unknown setting keys:\(unknownKeys.joined(separator: ","))"
    }

    func loadHtml(_ args: [String: Any?]) -> Bool {
        let baseUrl = args["baseURL"] as? String
        let html = args["html"] as? String
        if html != nil {
            webView!.loadHTMLString(html!, baseURL: baseUrl != nil ? URL(string: baseUrl!) : nil)
        }
        return true
    }

    func loadUrl(_ args: [String: Any?]) -> Bool {
        let url = args["url"] as! String
        let nsUrl = URL(string: url)
        if nsUrl == nil {
            return false
        }
        var request = URLRequest(url: nsUrl!)
        let headers = args["headers"] as? [String: String]
        if headers != nil {
            request.allHTTPHeaderFields = headers
        }
        webView!.load(request)
        return true
    }

    func registerJavaScriptChannels(
        _ channelNames: Set<AnyHashable>,
        _ userContentController: WKUserContentController?)
    {
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

    deinit {
        progressionDelegate?.stopObserving(webView!)
        contentSizeDelegate?.stopObserving(webView!)
//        scrollChangedDelegate?.stopObserving(webView!)
    }
}
