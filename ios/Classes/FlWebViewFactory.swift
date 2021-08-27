import Flutter
import Foundation
import WebKit

class FlWebViewFactory: NSObject, FlutterTexture, WKUIDelegate {
    var _textureId: Int64?
    
    var _latestPixelBuffer: CVPixelBuffer?
    
    var _registry: FlutterTextureRegistry
    var _webview: WKWebView?
    
    init(_ registry: FlutterTextureRegistry) {
        _registry = registry
        super.init()
    }

    func initial(_ call: FlutterMethodCall) {
        let args = call.arguments as! [String: Any?]
        
        let url = args["url"] as! String
        
        _webview = WKWebView()

        _ = _registry.register(self)

        _webview!.load(URLRequest(url: URL(string: url)!))
    }
    
    
  
    func copyPixelBuffer() -> Unmanaged<CVPixelBuffer>? {
        if _latestPixelBuffer == nil {
            return nil
        }
        return Unmanaged<CVPixelBuffer>.passRetained(_latestPixelBuffer);
    }
}
