# fl_webview

### 使用 use

```dart

@override
Widget build(BuildContext context) {
  return FlWebView(
      load: LoadUrlRequest('url'),
      progressBar: FlProgressBar(color: Colors.red),
      webSettings: WebSettings(),
      delegate: FlWebViewDelegate(onPageStarted:
          (FlWebViewController controller, String url) {
        log('onPageStarted : $url');
      },
          onPageFinished: (FlWebViewController controller, String url) {
            log('onPageFinished : $url');
          },
          onProgress: (FlWebViewController controller, int progress) {
            log('onProgress ：$progress');
          },
          onSizeChanged:
              (FlWebViewController controller, WebViewSize webViewSize) {
            log('onSizeChanged : ${webViewSize.frameSize} --- ${webViewSize.contentSize}');
          },
          onScrollChanged: (FlWebViewController controller,
              WebViewSize webViewSize,
              Offset offset,
              ScrollPositioned positioned) {
            log('onScrollChanged : ${webViewSize.frameSize} --- ${webViewSize.contentSize} --- $offset --- $positioned');
          },
          onNavigationRequest:
              (FlWebViewController controller, NavigationRequest request) {
            log('onNavigationRequest : url=${request.url} --- isForMainFrame=${request.isForMainFrame}');
            return true;
          },
          onUrlChanged: (FlWebViewController controller, String url) {
            log('onUrlChanged : $url');
          }),
      onWebViewCreated: (FlWebViewController controller) async {
        String userAgentString = 'userAgentString';
        final value = await controller.getNavigatorUserAgent();
        log('navigator.userAgent :  $value');
        userAgentString = '$value = $userAgentString';
        final userAgent = await controller.setUserAgent(userAgentString);
        log('set userAgent:  $userAgent');
        10.seconds.delayed(() {
          controller.getWebViewSize();
        });
      });
}


```

### 自适应高度 Adapt height

```dart

@override
Widget build(BuildContext context) {
  return FlAdaptHeightWevView(
      maxHeight: 1000,
      builder: (onSizeChanged, onScrollChanged, onWebViewCreated) =>
          BaseFlWebView(
              load: LoadUrlRequest(url),
              onWebViewCreated: onWebViewCreated,
              delegate: FlWebViewDelegate(
                  onSizeChanged: onSizeChanged,
                  onScrollChanged: onScrollChanged)))
  ,
}
```

### ScrollView 嵌套 WebView

```dart
@override
Widget build(BuildContext context) {
  double webHeight = context.mediaQuery.size.height -
      context.mediaQuery.padding.top -
      kToolbarHeight;
  return ExtendedScaffold(
      appBar:
      AppBar(title: const Text('ExtendedFlWebViewWithScrollViewPage')),
      body: ExtendedFlWebViewWithScrollView(
          contentHeight: webHeight,
          scrollViewBuilder:
              (ScrollController controller, bool canScroll, Widget webView) {
            return CustomScrollView(
                controller: controller,
                physics: canScroll
                    ? const BouncingScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(child: webView),
                  SliverListGrid.builder(
                      itemBuilder: (_, int index) =>
                          Container(
                              height: 100,
                              width: double.infinity,
                              color: index.isEven
                                  ? Colors.lightBlue
                                  : Colors.amberAccent),
                      itemCount: 30)
                ]);
          },
          webViewBuilder: (FlWebViewDelegateWithSizeCallback onSizeChanged,
              FlWebViewDelegateWithScrollChangedCallback onScrollChanged,
              WebViewCreatedCallback onWebViewCreated) {
            return BaseFlWebView(
                load: LoadUrlRequest(url),
                delegate: FlWebViewDelegate(
                    onSizeChanged: onSizeChanged,
                    onScrollChanged: onScrollChanged),
                onWebViewCreated: onWebViewCreated,
                webSettings:
                WebSettings(javascriptMode: JavascriptMode.unrestricted));
          }));
}
```