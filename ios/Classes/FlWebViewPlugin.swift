import Flutter
import WebKit

public class FlWebViewPlugin: NSObject, FlutterPlugin {
    var cookieChannel: FlutterMethodChannel?

    public static func register(with registrar: FlutterPluginRegistrar) {
        registrar.register(FlWebViewFactory(registrar.messenger()), withId: "fl.webview")
        let cookieChannel = FlutterMethodChannel(name: "fl.webview.channel", binaryMessenger:
            registrar.messenger())
        let instance = FlWebViewPlugin(cookieChannel)
        registrar.addMethodCallDelegate(instance, channel: cookieChannel)
    }

    init(_ _channel: FlutterMethodChannel) {
        cookieChannel = _channel
        super.init()
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "clearCookies":
            clearCookies(result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    public func detachFromEngine(for registrar: FlutterPluginRegistrar) {
        cookieChannel?.setMethodCallHandler(nil)
        cookieChannel = nil
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
}

class FlWebViewFactory: NSObject, FlutterPlatformViewFactory {
    var messenger: FlutterBinaryMessenger

    init(_ _messenger: FlutterBinaryMessenger) {
        messenger = _messenger
        super.init()
    }

    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        FlutterStandardMessageCodec.sharedInstance()
    }

    func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        let channel = FlutterMethodChannel(name: "fl.webview/\(viewId)", binaryMessenger: messenger)
        return FlWebViewPlatformView(frame, viewId, args as! [String: Any], channel)
    }
}

class FlWebView: WKWebView {
    var channel: FlutterMethodChannel

    init(_ channel: FlutterMethodChannel, _ frame: CGRect, _ configuration: WKWebViewConfiguration) {
        self.channel = channel
        super.init(frame: frame, configuration: configuration)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setFrame(frame: CGRect) {
        scrollView.contentInset = .zero
        if #available(iOS 11.0, *) {
            if scrollView.adjustedContentInset == .zero {
                return
            }
            let insetToAdjust = scrollView.adjustedContentInset
            scrollView.translatesAutoresizingMaskIntoConstraints = false
            scrollView.contentInset = UIEdgeInsets(
                top: -insetToAdjust.top,
                left: -insetToAdjust.left,
                bottom: -insetToAdjust.bottom,
                right: -insetToAdjust.right)
        }
    }

}
