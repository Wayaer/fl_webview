import 'package:fl_webview/fl_webview.dart';
import 'package:flutter/material.dart';

typedef FlAdaptHeightWevViewBuilder = Widget Function(
    ContentSizeCallback onContentSizeChanged,
    ScrollChangedCallback onScrollChanged,
    WebViewCreatedCallback? onWebViewCreated,
    bool useProgressGetContentSize);

/// webview content 有多高， widget 就有多高
/// 在ios 如果webview 太高 图片太多 滑动会卡顿
/// 仅适用 内容比较少的时候
/// The widget is as tall as the WebView content is
/// on ios, if the WebView is too high and there are too many images, swiping will stall
/// only applicable when there is little content
class FlAdaptHeightWevView extends StatefulWidget {
  const FlAdaptHeightWevView(
      {Key? key, required this.builder, this.initialHeight = 10})
      : super(key: key);
  final FlAdaptHeightWevViewBuilder builder;

  /// 初始高度
  /// The initial height
  final double initialHeight;

  @override
  _FlAdaptHeightWevViewState createState() => _FlAdaptHeightWevViewState();
}

class _FlAdaptHeightWevViewState extends State<FlAdaptHeightWevView> {
  double currenrHeight = 10;

  @override
  void initState() {
    super.initState();
    currenrHeight = widget.initialHeight;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.fromSize(
        size: Size(double.infinity, currenrHeight),
        child: widget.builder((Size frameSize, Size contentSize) {
          if (currenrHeight != contentSize.height) {
            currenrHeight = contentSize.height;
            if (mounted) setState(() {});
          }
        }, (Size frameSize, Size contentSize, Offset offset,
            ScrollPositioned positioned) {
          if (contentSize.height > currenrHeight) {
            currenrHeight = contentSize.height;
            if (mounted) setState(() {});
          }
        }, (WebViewController controller) {
          controller.scrollEnabled(false);
        }, true));
  }
}

/// 返回的Widget树中需要包含[FlWebView]
/// The Widget tree returned needs to include [FlWebView]
typedef ExtendedFlWebViewBuilder = Widget Function(
    ContentSizeCallback onContentSizeChanged,
    WebViewCreatedCallback onWebViewCreated,
    ScrollChangedCallback onScrollChanged);

/// 返回的Widget树中需要包含[ScrollView]
/// The Widget tree returned needs to include [ScrollView]
typedef NestedScrollViewBuilder = Widget Function(
    ScrollController controller, bool canScroll, Widget webView);

/// 固定的webview 高度，建议设置为当前可视高度
/// 滚动中不会卡顿
/// Fixed webView height. It is recommended to set it to the current viewable height
/// There is no lag in scrolling
class ExtendedFlWebViewWithScrollView extends StatefulWidget {
  const ExtendedFlWebViewWithScrollView({
    Key? key,
    required this.scrollViewBuilder,
    required this.webViewBuilder,
    this.controller,
    required this.contentHeight,
    this.minHeight = 10,
    this.faultTolerantHeight = 15,
  }) : super(key: key);

  /// scrollview
  final ScrollController? controller;
  final NestedScrollViewBuilder scrollViewBuilder;

  /// webview
  final ExtendedFlWebViewBuilder webViewBuilder;

  /// 必须要把webview 放在 scrollview的初始位置
  /// 建议设置为当前可视高度
  final double contentHeight;

  /// 当 webview content 的高度小于 [webViewHeight] 时显示的高度
  /// 不建议设置为0 最少为10
  final double minHeight;

  /// 当webview 滚动结束的时候 会自动在外层滚动组件跳转这个高度 即为容错高度
  /// 当外层滚动组件 到达最头部的时候 webview 自动向上滚动这个高度
  final int faultTolerantHeight;

  @override
  _ExtendedFlWebViewWithScrollViewState createState() =>
      _ExtendedFlWebViewWithScrollViewState();
}

class _ExtendedFlWebViewWithScrollViewState
    extends State<ExtendedFlWebViewWithScrollView> {
  bool scrollViewPhysics = false;

  bool noScrollWeb = true;
  double contentHeight = 10;
  late ScrollController controller;
  late WebViewController webViewController;

  @override
  void initState() {
    super.initState();
    contentHeight = widget.minHeight;
    initController();
  }

  void initController() {
    controller = widget.controller ?? ScrollController();
    controller.removeListener(listener);
    controller.addListener(listener);
  }

  void listener() {
    if (controller.offset <= 0 && scrollViewPhysics && noScrollWeb) {
      scrollViewPhysics = false;
      controller.jumpTo(0);
      webViewController.scrollEnabled(true).then((value) {
        webViewController.scrollBy(0, -(widget.faultTolerantHeight));
        setState(() {});
      });
    }
  }

  @override
  void didUpdateWidget(covariant ExtendedFlWebViewWithScrollView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) initController();
  }

  @override
  Widget build(BuildContext context) {
    Widget webView = SizedBox.fromSize(
        size: Size(double.infinity, contentHeight),
        child: widget.webViewBuilder(
            onContentSizeChanged, onWebViewCreated, onScrollChanged));
    return widget.scrollViewBuilder(controller, scrollViewPhysics, webView);
  }

  void onContentSizeChanged(Size frameSize, Size contentSize) {
    if (contentSize.height <= widget.minHeight) return;
    if (contentSize.height > widget.contentHeight) {
      noScrollWeb = true;
      if (contentHeight != widget.contentHeight) {
        contentHeight = widget.contentHeight;
        setState(() {});
      }
    } else {
      contentHeight = contentSize.height;
      noScrollWeb = false;
      setState(() {});
    }
  }

  void onWebViewCreated(WebViewController controller) {
    webViewController = controller;
  }

  Future<void> onScrollChanged(Size size, Size contentSize, Offset offset,
      ScrollPositioned positioned) async {
    if (positioned == ScrollPositioned.end &&
        !scrollViewPhysics &&
        noScrollWeb) {
      scrollViewPhysics = true;
      await webViewController.scrollEnabled(false);
      controller.jumpTo(widget.faultTolerantHeight.toDouble());
      setState(() {});
    }
  }

  @override
  void dispose() {
    super.dispose();
    controller.removeListener(listener);
  }
}
