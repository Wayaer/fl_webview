import FlutterMacOS
import WebKit

public class FlWebViewPlugin: NSObject, FlutterPlugin {
    var channel: FlutterMethodChannel?
    var registrar: FlutterPluginRegistrar
    var flWebView: FlWebView?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "fl.webview", binaryMessenger:
            registrar.messenger)
        let instance = FlWebViewPlugin(channel, registrar)
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    init(_ _channel: FlutterMethodChannel, _ _registrar: FlutterPluginRegistrar) {
        channel = _channel
        registrar = _registrar
        super.init()
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "clearCookies":
            clearCookies(result)
        case "initWebView":
            if flWebView == nil {
                flWebView = FlWebView(result, channel, call, registrar)
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    public func detachFromEngine(for registrar: FlutterPluginRegistrar) {
        channel?.setMethodCallHandler(nil)
        channel = nil
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

// class FlWebViewFactory: NSObject, FlutterTexture {
//    func copyPixelBuffer() -> Unmanaged<CVPixelBuffer>? {
//        return nil
//    }
//
//    var messenger: FlutterBinaryMessenger
//
//    init(_ _messenger: FlutterBinaryMessenger) {
//        messenger = _messenger
//        super.init()
//    }
//
//    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
//        FlutterStandardMessageCodec.sharedInstance()
//    }
//
//    func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
//        FlWebViewPlatformView(frame, viewId, args as! [String: Any], messenger)
//    }
// }

// class FlWebView: WKWebView {
//    func setFrame(frame: CGRect) {
//        scrollView.contentInset = .zero
//        if #available(iOS 11.0, *) {
//            if scrollView.adjustedContentInset == .zero {
//                return
//            }
//            let insetToAdjust = scrollView.adjustedContentInset
//            scrollView.contentInset = UIEdgeInsets(
//                top: -insetToAdjust.top,
//                left: -insetToAdjust.left,
//                bottom: -insetToAdjust.bottom,
//                right: -insetToAdjust.right)
//        }
//    }
// }
