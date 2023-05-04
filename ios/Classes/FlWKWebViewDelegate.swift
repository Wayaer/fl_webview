import Flutter
import WebKit

class FlWKNavigationDelegate: NSObject, WKNavigationDelegate {
    let methodChannel: FlutterMethodChannel
    public var enabledNavigationDelegate = false

    init(_ methodChannel: FlutterMethodChannel) {
        self.methodChannel = methodChannel
        super.init()
    }

    /// 处理网页开始加载
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        methodChannel.invokeMethod("onPageStarted", arguments: [
            "url": webView.url?.absoluteString ?? "",
        ])
    }

    /// 决定网页能否被允许跳转
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if !enabledNavigationDelegate {
            decisionHandler(.allow)
            return
        }

        methodChannel.invokeMethod(
            "onNavigationRequest",
            arguments: [
                "url": navigationAction.request.url?.absoluteString ?? "",
                "isForMainFrame": NSNumber(value: navigationAction.targetFrame?.isMainFrame ?? false),
            ],
            result: { result in
                decisionHandler(result is Bool && (result as! Bool) == false ? .cancel : .allow)
            })
    }

    /// 理网页加载完成
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        methodChannel.invokeMethod("onPageFinished", arguments: [
            "url": webView.url?.absoluteString ?? "",
        ])
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
        methodChannel.invokeMethod(
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
    var channel: FlutterMethodChannel
    let estimatedProgressKeyPath = "estimatedProgress"

    init(_ webView: WKWebView, _ methodChannel: FlutterMethodChannel) {
        channel = methodChannel
        super.init()
        webView.addObserver(
            self,
            forKeyPath: estimatedProgressKeyPath,
            options: .new,
            context: nil)
    }

    func stopObserving(_ webView: WKWebView?) {
        webView?.removeObserver(self, forKeyPath: estimatedProgressKeyPath)
    }

    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == estimatedProgressKeyPath {
            let newValue = change?[NSKeyValueChangeKey.newKey] ?? 0
            let newValueAsInt = Int((newValue as AnyObject).floatValue * 100)
            channel.invokeMethod("onProgress", arguments: [
                "progress": NSNumber(value: newValueAsInt),
            ])
        }
    }
}

class FlWKContentSizeDelegate: NSObject {
    var channel: FlutterMethodChannel
    let contentSizeKeyPath = "contentSize"
    var webView: WKWebView

    var height: CGFloat = 0

    init(_ _webView: WKWebView, _ methodChannel: FlutterMethodChannel) {
        channel = methodChannel
        webView = _webView
        super.init()
        _webView.scrollView.addObserver(
            self,
            forKeyPath: contentSizeKeyPath,
            options: .new,
            context: nil)
    }

    func stopObserving(_ webView: WKWebView?) {
        webView?.scrollView.removeObserver(self, forKeyPath: contentSizeKeyPath)
    }

    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath != contentSizeKeyPath {
            return
        }
        let size = change?[NSKeyValueChangeKey.newKey] as? CGSize
        if size == nil {
            return
        }
        let contentSize = webView.scrollView.contentSize
        if contentSize.height > height {
            height = contentSize.height
            let frame = webView.scrollView.frame
            channel.invokeMethod("onSizeChanged", arguments: [
                "width": frame.width,
                "height": frame.height,
                "contentWidth": contentSize.width,
                "contentHeight": contentSize.height,
            ])
        }
    }
}

class FlWKScrollChangedDelegate: NSObject, UIScrollViewDelegate {
    var channel: FlutterMethodChannel
    var webView: WKWebView

    init(_ _webView: WKWebView, _ methodChannel: FlutterMethodChannel) {
        channel = methodChannel
        webView = _webView
        super.init()
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
        channel.invokeMethod("onScrollChanged", arguments: [
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
