# fl_webview

使用方式和 [webview_flutter](https://pub.dev/packages/webview_flutter) 一致

- 添加了 `onContentSizeChanged` ,
  可以在必须设置高度的组件中动态设置高度，参考 [example](https://github.com/Wayaer/fl_webview/blob/main/example/lib/main.dart)
- `onContentSizeChanged` is added. You can dynamically set the height in components that must be
  set. Refer to [example](https://github.com/Wayaer/fl_webview/blob/main/example/lib/main.dart)

- Android 端支持缩放，且自适应屏幕，解决android上webview中有视频时无法播放问题
- Android supports zooming and adaptive screen, which solves the problem that video cannot be played
  when there is video in WebView on Android

### 使用 use

```dart

@override
Widget build(BuildContext context) {
  return FlWebView(
      javascriptMode: JavascriptMode.unrestricted,
      navigationDelegate: (NavigationRequest navigation) async {
        log('navigationDelegate');
        log(navigation.url);
        return NavigationDecision.navigate;
      },
      onWebViewCreated: (WebViewController controller) async {
        log('onWebViewCreated');
        log(await controller.currentUrl());
      },
      onPageStarted: (String url) {
        log('onPageStarted');
        log(url);
      },
      onPageFinished: (String url) {
        log('onPageFinished');
        log(url);
      },
      onProgress: (int progress) {
        log('onProgress');
        log(progress);
      },
      onContentSizeChanged: (Size size) {
        log('onContentSizeChanged');
        log(size);
      },
      onScrollChanged: (Size size, Size contentSize, Offset offset,
          ScrollPositioned positioned) {
        log('onScrollChanged');
        log(offset);
      },
      initialUrl: 'https://zhuanlan.zhihu.com/p/62821195');
}


```

### 自适应高度 Adapt hight

```dart

@override
Widget build(BuildContext context) {
  return FlAdaptHeightWevView(
      builder: (onContentSizeChanged, onScrollChanged) =>
          _FlWebView(
              initialUrl: url,
              onContentSizeChanged: onContentSizeChanged,
              onScrollChanged: onScrollChanged));
}
```

### webview底部嵌套其他scrllview  Other scrllViews are nested at the bottom of the WebView

```dart

@override
Widget build(BuildContext context) {
  double webHeight = deviceHeight - getStatusBarHeight - kToolbarHeight;
  return ExtendedFlWebViewWithScrollView(
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
              SliverListGrid(
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
      webViewBuilder: (ContentSizeCallback onContentSizeChanged,
          WebViewCreatedCallback onWebViewCreated,
          ScrollChangedCallback onScrollChanged) {
        return FlWebView(
            onContentSizeChanged: onContentSizeChanged,
            onWebViewCreated: onWebViewCreated,
            onScrollChanged: onScrollChanged,
            javascriptMode: JavascriptMode.unrestricted,
            initialUrl: url);
      });
}
```