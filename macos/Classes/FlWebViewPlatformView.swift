import FlutterMacOS
import WebKit

public class FlWebViewPlatformView: NSView, WKUIDelegate {
    var webView: FlWebView?

    var channel: FlutterMethodChannel

    var navigationDelegate: FlWKNavigationDelegate?
    var progressDelegate: FlWKProgressnDelegate?
    var contentSizeDelegate: FlWKContentSizeDelegate?
//    var scrollChangedDelegate: FlWKScrollChangedDelegate?
    var urlChangedDelegate: FlWKUrlChangedDelegate?

    var javaScriptChannels: [[String: Any]] = []

    init(_ channel: FlutterMethodChannel) {
        self.channel = channel
        super.init(frame: CGRect())
        channel.setMethodCallHandler(handle)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "create":
            create(call)
            result(webView != nil)
        case "applyWebSettings":
            applyWebSettings(call.arguments as! [String: Any?])
            result(nil)
        case "loadUrl":
            DispatchQueue.main.async {
                result(self.loadUrl(call.arguments as! [String: Any?]))
            }
        case "loadData":
            DispatchQueue.main.async {
                result(self.loadData(call.arguments as! [String: Any?]))
            }
        case "canGoBack":
            result(webView?.canGoBack)
        case "canGoForward":
            result(webView?.canGoForward)
        case "goBack":
            webView?.goBack()
            result(nil)
        case "goForward":
            webView?.goForward()
            result(nil)
        case "reload":
            webView?.reload()
            result(nil)
        case "currentUrl":
            result(webView?.url?.absoluteString)
        case "evaluateJavascript":
            let jsString = call.arguments as! String
            webView!.evaluateJavaScript(jsString) { value, error in
                print("FlWebview evaluateJavaScript failed , JavaScript string was: '\(jsString)'\n\(String(describing: error))")
                result(value)
            }
        case "addJavascriptChannel":
            addJavaScriptChannel(call, result)
        case "removeJavascriptChannel":
            removeJavaScriptChannel(call, result)
        case "clearCache":
            clearCache(result)
        case "getTitle":
            result(webView?.title)
        case "scrollTo":
            onScrollTo(call, result)
        case "scrollBy":
            onScrollBy(call, result)
        case "getScrollXY":
//            let offsetX = webView?.enclosingScrollView.contentOffset.x
//            let offsetY = webView?.enclosingScrollView.contentOffset.y
//            result([
//                "x": offsetX,
//                "y": offsetY,
//            ])
            break
        case "getWebViewSize":
            let contentSize = webView?.visibleRect.size
            let frame = webView?.frame.size
            result([
                "contentWidth": contentSize?.width,
                "contentHeight": contentSize?.height,
                "width": frame?.width,
                "height": frame?.height,
            ])
        case "getUserAgent":
            result(webView?.customUserAgent)
        case "setUserAgent":
            webView?.customUserAgent = call.arguments as? String
            result(webView?.customUserAgent)
        case "enabledScroll":
//            webView.scrollView.isScrollEnabled = call.arguments as! Bool
            result(true)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    func create(_ call: FlutterMethodCall) {
        let args = call.arguments as! [String: Any?]
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = WKUserContentController()
        if args["deleteWindowSharedWorker"] as! Bool {
            let dropSharedWorkersScript = WKUserScript(source: "delete window.SharedWorker;", injectionTime: .atDocumentStart, forMainFrameOnly: false)
            configuration.userContentController.addUserScript(dropSharedWorkersScript)
        }
        let frame = CGRect(x: 0, y: 0, width: NSNumber(value: args["width"] as! Double
        ).intValue, height: NSNumber(value: args["height"] as! Double
        ).intValue)
        webView = FlWebView(channel, frame, configuration)
        navigationDelegate = FlWKNavigationDelegate(channel)
        webView!.uiDelegate = self
        webView!.navigationDelegate = navigationDelegate
        urlChangedDelegate = FlWKUrlChangedDelegate(webView!)
        applyWebSettings(args)
        webView?.configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        super.autoresizesSubviews = true
        super.autoresizingMask = [.height, .width]

        webView!.autoresizesSubviews = true
        webView!.autoresizingMask = [.height, .width]

        super.layer?.backgroundColor = NSColor.red.cgColor
        super.frame = frame
        super.removeFromSuperview()
        super.addSubview(webView!)
    }

    func applyWebSettings(_ settings: [String: Any?]) {
        settings.forEach { (key: String, value: Any?) in
            switch key {
            case "enabledNavigationDelegate":
                navigationDelegate?.enabledNavigationDelegate = value as! Bool
            case "enabledProgressChanged":
                if value as! Bool {
                    progressDelegate = FlWKProgressnDelegate(webView!)
                } else {
                    progressDelegate?.stopObserving()
                    progressDelegate = nil
                }
            case "enableSizeChanged":
                if value as! Bool {
                    contentSizeDelegate = FlWKContentSizeDelegate(webView!)
                } else {
                    contentSizeDelegate?.stopObserving()
                    contentSizeDelegate = nil
                }
            case "enabledScrollChanged":
//                if value as! Bool {
//                    scrollChangedDelegate = FlWKScrollChangedDelegate(webView, channel)
//                    webView.scrollView.delegate = scrollChangedDelegate
//                } else {
//                    webView.scrollView.delegate = nil
//                    scrollChangedDelegate = nil
//                }
                break
            case "javascriptMode":
                webView?.configuration.defaultWebpagePreferences.allowsContentJavaScript = (value as! NSNumber).intValue == 1
            case "gestureNavigationEnabled":
                webView?.allowsBackForwardNavigationGestures = value as! Bool
            //            case "allowsInlineMediaPlayback":
//                webView?.configuration.allowsAirPlayForMediaPlayback = value as! Bool
            case "allowsAutoMediaPlayback":
                webView?.configuration.mediaTypesRequiringUserActionForPlayback = value as! Bool ? .all : .audio
            default: break
            }
        }
    }

    func addJavaScriptChannel(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        let channel = call.arguments as! [String: Any]
        javaScriptChannels.append(channel)
        registerJavaScriptChannels([channel])
        result(nil)
    }

    func removeJavaScriptChannel(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        webView?.configuration.userContentController.removeAllUserScripts()
        for channel in javaScriptChannels {
            webView?.configuration.userContentController.removeScriptMessageHandler(forName: channel["name"] as! String)
        }
        javaScriptChannels.removeAll { value in
            value["name"] as! String == call.arguments as! String
        }
        registerJavaScriptChannels(javaScriptChannels)
        result(nil)
    }

    func registerJavaScriptChannels(_ channels: [[String: Any]]) {
        for channel in channels {
            let name = channel["name"] as! String
            let source = channel["source"] as? String
            let flChannel = FlWKJavaScriptChannel(
                self.channel,
                name)
            webView?.configuration.userContentController.add(flChannel, name: name)
            webView?.configuration.userContentController.addUserScript(WKUserScript(
                source: source ?? name,
                injectionTime: .atDocumentStart,
                forMainFrameOnly: false))
        }
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
        webView?.scroll(CGPoint(x: CGFloat(x), y: CGFloat(y)))
        result(nil)
    }

    func onScrollBy(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
//        let contentOffset = webView!.preparedContentRect
//        let arguments = call.arguments as! [String: Any]
//        let x = CGFloat(arguments["x"] as! Double) + contentOffset.x
//        let y = CGFloat(arguments["y"] as! Double) + contentOffset.y
//        webView?.scroll(CGPoint(x: CGFloat(x), y: CGFloat(y))
        result(nil)
    }

    func loadData(_ args: [String: Any?]) -> Bool {
        let baseUrl = args["baseURL"] as? String
        let data = args["data"] as! String
        webView?.loadHTMLString(data, baseURL: baseUrl != nil ? URL(string: baseUrl!) : nil)
        return true
    }

    func loadUrl(_ args: [String: Any?]) -> Bool {
        let url = URL(string: args["url"] as! String)
        if url == nil {
            return false
        }
        var request = URLRequest(url: url!)
        let headers = args["headers"] as? [String: String]
        if headers != nil {
            request.allHTTPHeaderFields = headers
        }
        webView?.load(request)
        return true
    }

    public func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if !(navigationAction.targetFrame?.isMainFrame ?? false) {
            webView.load(navigationAction.request)
        }
        return nil
    }

    deinit {
        channel.setMethodCallHandler(nil)
        webView?.removeFromSuperview()
        webView = nil
        navigationDelegate = nil
        progressDelegate?.stopObserving()
        progressDelegate = nil
        contentSizeDelegate?.stopObserving()
        contentSizeDelegate = nil
        urlChangedDelegate = nil
    }
}
