import Flutter
import WebKit

class FlWKJavaScriptChannel: NSObject, WKScriptMessageHandler {
    var channel: FlutterMethodChannel
    let javaScriptChannelName: String

    init(_ methodChannel: FlutterMethodChannel, _ _javaScriptChannelName: String) {
        channel = methodChannel
        javaScriptChannelName = _javaScriptChannelName
        super.init()
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        channel.invokeMethod("javascriptChannelMessage", arguments: [
            "javaScriptChannelName": javaScriptChannelName,
            "message": message.body,
        ])
    }
}
