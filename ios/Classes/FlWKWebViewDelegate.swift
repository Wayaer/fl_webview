import Flutter
import WebKit

class FlWKNavigationDelegate: NSObject, WKNavigationDelegate {
    var methodChannel: FlutterMethodChannel
    public var hasDartNavigationDelegate = false

    init(_ _methodChannel: FlutterMethodChannel) {
        methodChannel = _methodChannel
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
        if !hasDartNavigationDelegate {
            decisionHandler(.allow)
            return
        }
        let arguments = [
            "url": navigationAction.request.url?.absoluteString ?? "",
            "isForMainFrame": NSNumber(value: navigationAction.targetFrame?.isMainFrame ?? false),
        ] as [String: Any]

        methodChannel.invokeMethod(
            "navigationRequest",
            arguments: arguments,
            result: { result in
                if result is FlutterError {
                    decisionHandler(.allow)
                    return
                }
                if result as! NSObject == FlutterMethodNotImplemented {
                    decisionHandler(.allow)
                    return
                }
                if !(result is NSNumber) {
                    decisionHandler(.allow)
                    return
                }
                let typedResult = result as! Bool
                decisionHandler(
                    typedResult
                        ? .allow
                        : .cancel)
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
        let contentProcessTerminatedError = NSError(domain: WKErrorDomain, code: WKError.Code.webContentProcessTerminated.rawValue, userInfo: nil)
        onWebResourceError(contentProcessTerminatedError)
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

    var height: CGFloat = 10

    init(_ webView: WKWebView, _ methodChannel: FlutterMethodChannel) {
        channel = methodChannel
        super.init()
        webView.scrollView.addObserver(
            self,
            forKeyPath: contentSizeKeyPath,
            options: .new,
            context: nil)
    }

    func stopObserving(_ webView: WKWebView?) {
        webView?.scrollView.removeObserver(self, forKeyPath: contentSizeKeyPath)
    }

    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == contentSizeKeyPath {
            let size = change?[NSKeyValueChangeKey.newKey] as? CGSize
            if size == nil {
                return
            }
            if height < size!.height {
                height = size!.height
                channel.invokeMethod("onContentSize", arguments: [
                    "width": size!.width,
                    "height": size!.height,
                ])
            }
        }
    }
}
