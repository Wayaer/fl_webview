import Flutter
import WebKit

class FlWKJavaScriptChannel: NSObject, WKScriptMessageHandler {
    let channel: FlutterMethodChannel
    let javaScriptChannelName: String

    init(_ channel: FlutterMethodChannel, _ javaScriptChannelName: String) {
        self.channel = channel
        self.javaScriptChannelName = javaScriptChannelName
        super.init()
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        channel.invokeMethod("javascriptChannelMessage", arguments: [
            "channel": javaScriptChannelName,
            "message": "\(message.body)",
        ])
    }
}
