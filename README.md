# fl_webview

使用方式和 [webview_flutter](https://pub.dev/packages/webview_flutter) 一致

- 添加了 `onSizeChanged` , 可以在必须设置高度的组件中 动态设置高度，参考 [example](https://github.com/Wayaer/fl_webview/blob/main/example/lib/main.dart)
- `onSizeChanged` is added. You can dynamically set the height in components that must be set. Refer to [example](https://github.com/Wayaer/fl_webview/blob/main/example/lib/main.dart)

- Android 端支持缩放，且自适应屏幕，解决android上webview中有视频时无法播放问题
- Android supports zooming and adaptive screen, which solves the problem 
  that video cannot be played when there is video in WebView on Android
  
### 使用  use

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
        onSizeChanged: (Size size) {
              log('onSizeChanged');
              log(size);
            },
        initialUrl: 'https://zhuanlan.zhihu.com/p/62821195');
  }


```