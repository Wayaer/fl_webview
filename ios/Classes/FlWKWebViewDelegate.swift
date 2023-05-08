import Flutter
import WebKit

class FlWKNavigationDelegate: NSObject, WKNavigationDelegate {
    let channel: FlutterMethodChannel
    public var enabledNavigationDelegate = false

    init(_ channel: FlutterMethodChannel) {
        self.channel = channel
        super.init()
    }

    /// 处理网页开始加载
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        channel.invokeMethod("onPageStarted", arguments: webView.url?.absoluteString)
    }

    /// 决定网页能否被允许跳转
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if enabledNavigationDelegate {
            channel.invokeMethod(
                "onNavigationRequest",
                arguments: [
                    "url": navigationAction.request.url?.absoluteString ?? "",
                    "isForMainFrame": NSNumber(value: navigationAction.targetFrame?.isMainFrame ?? false),
                ],
                result: { result in
                    decisionHandler(result as! Bool ? .allow : .cancel)
                })

        } else {
            decisionHandler(.allow)
        }
    }

    /// 理网页加载完成
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        channel.invokeMethod("onPageFinished", arguments: webView.url?.absoluteString)
    }

    func errorCode(_ code: Int?) -> Any? {
        switch code {
        case WKError.Code.unknown.rawValue:
            return "unknown"
        case WKError.Code.webContentProcessTerminated.rawValue:
            return "webContentProcessTerminated"
        case WKError.Code.webViewInvalidated.rawValue:
            return "webViewInvalidated"
        case WKError.Code.javaScriptExceptionOccurred.rawValue:
            return "javaScriptExceptionOccurred"
        case WKError.Code.javaScriptResultTypeIsUnsupported.rawValue:
            return "javaScriptResultTypeIsUnsupported"
        default:
            return nil
        }
    }

    func onWebResourceError(_ error: Error?) {
        channel.invokeMethod(
            "onWebResourceError",
            arguments: [
                "errorCode": NSNumber(value: (error as NSError?)?.code ?? 0),
                "domain": (error as NSError?)?.domain ?? "",
                "description": description,
                "errorType": errorCode((error as NSError?)?.code),
            ])
    }

    /// 处理网页返回内容时发生的失败
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        onWebResourceError(error)
    }

    /// 处理网页加载失败
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        onWebResourceError(error)
    }

    /// 处理网页进程终止
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        let error = NSError(domain: WKErrorDomain, code: WKError.Code.webContentProcessTerminated.rawValue, userInfo: nil)
        onWebResourceError(error)
    }
}

class FlWKProgressionDelegate: NSObject {
    let progressKeyPath = "estimatedProgress"
    var webView: FlWebView

    init(_ webView: FlWebView) {
        self.webView = webView
        super.init()
        webView.addObserver(
            self,
            forKeyPath: progressKeyPath,
            options: .new,
            context: nil)
    }

    func stopObserving() {
        webView.removeObserver(self, forKeyPath: progressKeyPath)
    }

    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        let value = change?[NSKeyValueChangeKey.newKey]
        if keyPath != progressKeyPath || value == nil {
            return
        }
        let newValue = Int((value as AnyObject).floatValue * 100)
        webView.channel.invokeMethod("onProgress", arguments: newValue)
    }
}

class FlWKContentSizeDelegate: NSObject {
    let contentSizeKeyPath = "contentSize"
    var webView: FlWebView

    var height: CGFloat = 0

    init(_ webView: FlWebView) {
        self.webView = webView
        super.init()
        webView.scrollView.addObserver(
            self,
            forKeyPath: contentSizeKeyPath,
            options: .new,
            context: nil)
    }

    func stopObserving() {
        webView.scrollView.removeObserver(self, forKeyPath: contentSizeKeyPath)
    }

    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath != contentSizeKeyPath || change?[NSKeyValueChangeKey.newKey] == nil {
            return
        }
        let contentSize = webView.scrollView.contentSize
        if contentSize.height > height {
            height = contentSize.height
            let frame = webView.scrollView.frame
            webView.channel.invokeMethod("onSizeChanged", arguments: [
                "width": frame.width,
                "height": frame.height,
                "contentWidth": contentSize.width,
                "contentHeight": contentSize.height,
            ])
        }
    }
}

class FlWKUrlChangedDelegate: NSObject {
    let urlPath = "URL"
    var webView: FlWebView

    init(_ webView: FlWebView) {
        self.webView = webView
        super.init()
        webView.addObserver(
            self,
            forKeyPath: urlPath,
            options: .new,
            context: nil)
    }

    func stopObserving() {
        webView.removeObserver(self, forKeyPath: urlPath)
    }

    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        let url = change?[NSKeyValueChangeKey.newKey]
        if keyPath == urlPath, url is URL {
            webView.channel.invokeMethod("onUrlChanged", arguments: (url as! URL).absoluteString)
        }
    }
}

class FlWKScrollChangedDelegate: NSObject, UIScrollViewDelegate {
    var webView: FlWebView

    init(_ webView: FlWebView) {
        self.webView = webView
        super.init()
        webView.scrollView.delegate = self
        webView.scrollView.bounces = false
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let contentSize = scrollView.contentSize
        let frame = scrollView.frame
        let offset = scrollView.contentOffset
        var position = 0
        if offset.y < 1 {
            position = 0
        } else if (contentSize.height - offset.y - frame.height) <= 5 {
            position = 2
        } else {
            position = 1
        }
        webView.channel.invokeMethod("onScrollChanged", arguments: [
            "x": offset.x,
            "y": offset.y,
            "contentWidth": contentSize.width,
            "contentHeight": contentSize.height,
            "width": frame.width,
            "height": frame.height,
            "position": position,
        ])
    }
}

class FlWKJavaScriptChannel: NSObject, WKScriptMessageHandler {
    let channel: FlutterMethodChannel
    let javaScriptChannelName: String

    init(_ channel: FlutterMethodChannel, _ javaScriptChannelName: String) {
        self.channel = channel
        self.javaScriptChannelName = javaScriptChannelName
        super.init()
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        channel.invokeMethod("onJavascriptChannelMessage", arguments: [
            "channel": javaScriptChannelName,
            "message": "\(message.body)",
        ])
    }
}
