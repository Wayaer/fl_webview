import Cocoa
import FlutterMacOS
import WebKit

class FlWebViewController: NSObject {
    public var channel: FlutterMethodChannel
    public var registrar: FlutterPluginRegistrar

    init(_ id: Int, _ registrar: FlutterPluginRegistrar) {
        channel = FlutterMethodChannel(name: "fl.webview.\(id)", binaryMessenger:
            registrar.messenger)
        self.registrar = registrar
        super.init()
        channel.setMethodCallHandler(handle)
    }

    private lazy var parentViewController: NSViewController? = {
        NSApp.windows.first { w -> Bool in
            w.contentViewController?.view == registrar.view?.superview
        }?
            .contentViewController
    }()

    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        
        
        
    }

    func dispose() {
        channel.setMethodCallHandler(nil)
    }
}
