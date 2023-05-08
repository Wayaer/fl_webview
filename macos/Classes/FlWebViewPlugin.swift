import FlutterMacOS
import WebKit

public class FlWebViewPlugin: NSObject, FlutterPlugin {
    public var flChannel: FlutterMethodChannel
    public var registrar: FlutterPluginRegistrar
//    var webViewMap = [Int: FlWebViewController]()

    public static func register(with registrar: FlutterPluginRegistrar) {
        registrar.register(FlWebViewFactory(registrar.messenger), withId: "fl.webview")
        let cookieChannel = FlutterMethodChannel(name: "fl.webview.channel", binaryMessenger:
            registrar.messenger)
        let instance = FlWebViewPlugin(cookieChannel, registrar)
        registrar.addMethodCallDelegate(instance, channel: cookieChannel)
    }

    init(_ channel: FlutterMethodChannel, _ registrar: FlutterPluginRegistrar) {
        flChannel = channel
        self.registrar = registrar
        super.init()
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "clearCookies":
            clearCookies(result)
        case "createWebView":
            let id = millisecond
//            webViewMap[id] = FlWebViewController(id, registrar)
            result(id)
        case "disposeWebView":
//            let id = call.arguments as! Int
//            let isContains = webViewMap.contains { (key: Int, _: FlWebViewController) in
//                key == id
//            }
//            if isContains {
//                webViewMap[id]!.dispose()
//                webViewMap.removeValue(forKey: id)
//            }
            result(true)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    public func detachFromEngine(for registrar: FlutterPluginRegistrar) {
        flChannel.setMethodCallHandler(nil)
    }

    func clearCookies(_ result: @escaping FlutterResult) {
        let websiteDataTypes = Set<String>([WKWebsiteDataTypeCookies])
        let dataStore = WKWebsiteDataStore.default()
        let deleteAndNotify: (([WKWebsiteDataRecord]?) -> Void)? = { cookies in
            let hasCookies = (cookies?.count ?? 0) > 0
            if let cookies = cookies {
                dataStore.removeData(
                    ofTypes: websiteDataTypes,
                    for: cookies) {
                        result(NSNumber(value: hasCookies))
                }
            }
        }
        dataStore.fetchDataRecords(ofTypes: websiteDataTypes, completionHandler: deleteAndNotify!)
    }

    var millisecond: Int {
        let timeInterval: TimeInterval = Date().timeIntervalSince1970
        let millisecond = CLongLong(round(timeInterval * 1000))
        return Int(millisecond)
    }
}

class FlWebViewFactory: NSObject, FlutterPlatformViewFactory {
    var messenger: FlutterBinaryMessenger

    init(_ _messenger: FlutterBinaryMessenger) {
        messenger = _messenger
        super.init()
    }

    func createArgsCodec() -> (FlutterMessageCodec & NSObjectProtocol)? {
        return FlutterStandardMessageCodec.sharedInstance()
    }

    func create(withViewIdentifier viewId: Int64, arguments args: Any?) -> NSView {
        let channel = FlutterMethodChannel(name: "fl.webview/\(viewId)", binaryMessenger: messenger)
        print("FlWebViewFactory = \(viewId)")
        return FlWebViewPlatformView(channel)
    }

    deinit {
        print("FlutterWebViewMacosFactory - dealloc")
    }
}

class FlWebView: WKWebView {
    init(_ frame: CGRect, _ configuration: WKWebViewConfiguration) {
        super.init(frame: frame, configuration: configuration)
    }

    public required init(coder decoder: NSCoder) {
        super.init(coder: decoder)!
    }

//    func setFrame(frame: CGRect) {
//        scrollView.contentInset = .zero
//        if #available(iOS 11.0, *) {
//            if scrollView.adjustedContentInset == .zero {
//                return
//            }
//            let insetToAdjust = scrollView.adjustedContentInset
//            scrollView.translatesAutoresizingMaskIntoConstraints = false
//            scrollView.contentInset = UIEdgeInsets(
//                top: -insetToAdjust.top,
//                left: -insetToAdjust.left,
//                bottom: -insetToAdjust.bottom,
//                right: -insetToAdjust.right)
//        }
//    }

    func setUserAgent(_ userAgent: String) {
        evaluateJavaScript("navigator.userAgent") { info, _ in
            self.customUserAgent = (info as? String ?? "") + userAgent
        }
    }
}
