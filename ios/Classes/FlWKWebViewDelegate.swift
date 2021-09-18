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

class FlWKContentOffsetDelegate: NSObject {
    var channel: FlutterMethodChannel
    let contentOffsetKeyPath = "contentOffset"

    init(_ webView: WKWebView, _ methodChannel: FlutterMethodChannel) {
        channel = methodChannel
        super.init()
        webView.scrollView.addObserver(
            self,
            forKeyPath: contentOffsetKeyPath,
            options: .new,
            context: nil)
    }

    func stopObserving(_ webView: WKWebView?) {
        webView?.scrollView.removeObserver(self, forKeyPath: contentOffsetKeyPath)
    }

    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == contentOffsetKeyPath {
            let offset = change?[NSKeyValueChangeKey.newKey] as? CGPoint
            if offset == nil {
                return
            }
            channel.invokeMethod("onScrollChanged", arguments: [
                "x": offset!.x,
                "y": offset!.y,
            ])
        }
    }
}

class FlWKScrollChangedDelegate: NSObject, UIScrollViewDelegate, UIGestureRecognizerDelegate {
    var channel: FlutterMethodChannel
    var webView: WKWebView

    init(_ _webView: WKWebView, _ methodChannel: FlutterMethodChannel) {
        channel = methodChannel
        webView = _webView
        super.init()

        let pan = UIPanGestureRecognizer(target: self, action: Selector(("pan:")))
        pan.delegate = self
        pan.cancelsTouchesInView = false
        webView.addGestureRecognizer(pan)
        webView.scrollView.bounces = false
    }

    func pan(_ pan: UIPanGestureRecognizer?) {
        print("pan手势触发")
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

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        print("shouldRecognizeSimultaneouslyWith")
//        var locationPoint = gestureRecognizer.location(in: gestureRecognizer.view)
//        print(locationPoint)
        return true
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        print("otherGestureRecognizer")
        return true
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive event: UIEvent) -> Bool {
        return true
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return true
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive press: UIPress) -> Bool {
        return true
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
}
