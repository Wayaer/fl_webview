import Flutter
import UIKit

public class FlWebviewPlugin: NSObject, FlutterPlugin {
    var channel: FlutterMethodChannel?
    var webview: FlWebview?
    var registrar: FlutterPluginRegistrar
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "fl.webview", binaryMessenger:
            registrar.messenger())
        let instance = FlWebviewPlugin(registrar, channel)
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    init(_ _registrar: FlutterPluginRegistrar, _ _channel: FlutterMethodChannel) {
        channel = _channel
        registrar = _registrar
        super.init()
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initial":
            if webview == nil {
                webview = FlWebview(registrar.textures())
                webview!.initial(call)
            }
            result(webview != nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    public func detachFromEngine(for registrar: FlutterPluginRegistrar) {
        channel?.setMethodCallHandler(nil)
        channel = nil
    }
}
