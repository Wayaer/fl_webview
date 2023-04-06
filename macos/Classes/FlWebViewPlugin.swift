import FlutterMacOS
import WebKit

public class FlWebViewPlugin: NSObject, FlutterPlugin {
    public var flChannel: FlutterMethodChannel
    var webView: WebViewTools?
    public var registrar: FlutterPluginRegistrar

    public static func register(with registrar: FlutterPluginRegistrar) {
        let flChannel = FlutterMethodChannel(name: "fl.webview.channel", binaryMessenger:
            registrar.messenger)
        let instance = FlWebViewPlugin(flChannel, registrar)
        registrar.addMethodCallDelegate(instance, channel: flChannel)
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
        case "openWebView":
            if webView == nil {
                webView = WebViewTools(flChannel, registrar)
            }
            webView!.openWebview(call, result)

        case "closeWebView":
            webView?.closeWebView()
            result(webView != nil)
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
}
