import 'package:fl_webview/fl_webview.dart';
import 'package:fl_webview/src/extension.dart';
import 'package:flutter/material.dart';

/// 返回的Widget树中需要包含[FlWebView]
/// The Widget tree returned needs to include [FlWebView]
typedef ExtendedFlWebViewBuilder = Widget Function(
    FlWebViewDelegateWithSizeCallback onSizeChanged,
    FlWebViewDelegateWithScrollChangedCallback onScrollChanged,
    WebViewCreatedCallback onWebViewCreated);

/// webView content 有多高， widget 就有多高
/// 仅适用 内容比较少的时候
/// The widget is as tall as the WebView content is
/// on ios, if the WebView is too high and there are too many images, swiping will stall
/// only applicable when there is little content
class FlAdaptHeightWevView extends StatefulWidget {
  const FlAdaptHeightWevView({
    Key? key,
    required this.builder,
    this.initialHeight = 40,
    this.gapUpdateHeight = 40,
    this.maxHeight,
  }) : super(key: key);
  final ExtendedFlWebViewBuilder builder;

  /// 初始高度
  /// The initial height
  final double initialHeight;

  /// [onContentSizeChanged] 高度差距更新间隔 两次回调高低小于这个值 就不刷新
  /// 默认为 40  根据实际需求设置 间隔高度更新
  final double gapUpdateHeight;

  /// 设置最大高度，
  final double? maxHeight;

  @override
  State<FlAdaptHeightWevView> createState() => _FlAdaptHeightWevViewState();
}

class _FlAdaptHeightWevViewState extends State<FlAdaptHeightWevView> {
  late double currentHeight;
  List<double> historyHeight = [];

  /// 禁止更新高度
  bool forbidUpdateHeight = false;
  FlWebViewController? controller;

  @override
  void initState() {
    super.initState();
    currentHeight = widget.initialHeight;
    historyHeight.add(widget.initialHeight);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.fromSize(
        size: Size(double.infinity, currentHeight),
        child: widget.builder(onSizeChanged, onScrollChanged, (controller) {
          this.controller = controller;
          controller.enabledScroll(false);
          1.seconds.delayed(() {
            controller.getWebViewSize();
          });
        }));
  }

  void onScrollChanged(
      WebViewSize webViewSize, Offset offset, ScrollPositioned positioned) {
    if (webViewSize.contentSize.height > currentHeight) {
      currentHeight = webViewSize.contentSize.height;
      if (mounted) setState(() {});
    }
  }

  void onSizeChanged(WebViewSize webViewSize) {
    var contentSizeHeight = webViewSize.contentSize.height;
    if (contentSizeHeight == 0 || currentHeight == contentSizeHeight) {
      return;
    }
    if (_differenceWithHeight(
        contentSizeHeight, historyHeight.last, widget.gapUpdateHeight)) {
      return;
    } else if (historyHeight.length > 1) {
      if (_differenceWithHeight(
          historyHeight[historyHeight.length - 1], contentSizeHeight, 10)) {
        if (!forbidUpdateHeight) {
          forbidUpdateHeight = true;
          currentHeight = historyHeight[historyHeight.length - 1];
          setState(() {});
        }
        return;
      }
    }
    historyHeight.add(contentSizeHeight);
    if (currentHeight != contentSizeHeight) {
      currentHeight = contentSizeHeight;
      if (mounted) setState(() {});
    }
  }
}

/// 返回的Widget树中需要包含[ScrollView]
/// The Widget tree returned needs to include [ScrollView]
typedef NestedScrollViewBuilder = Widget Function(
    ScrollController controller, bool canScroll, Widget webView);

/// 固定的 webView 高度，建议设置为当前可视高度
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
    this.minHeight = 15,
    this.faultTolerantHeight = 15,
    this.gapUpdateHeight = 40,
    this.initialHeight = 40,
  })  : assert(contentHeight > minHeight),
        super(key: key);

  /// scrollview
  final ScrollController? controller;
  final NestedScrollViewBuilder scrollViewBuilder;

  /// webView
  final ExtendedFlWebViewBuilder webViewBuilder;

  /// 必须要把 webView 放在 scrollview的初始位置
  /// 建议设置为当前可视高度
  final double contentHeight;

  /// 当 webView content 的高度小于 [webViewHeight] 时显示的高度
  /// 不建议设置为0 最少为10
  final double minHeight;

  /// 初始高度
  final double initialHeight;

  /// 当 webView 滚动结束的时候 会自动在外层滚动组件跳转这个高度 即为容错高度
  /// 当外层滚动组件 到达最头部的时候 webView 自动向上滚动这个高度
  final int faultTolerantHeight;

  /// [onContentSizeChanged] 高度差距更新间隔 两次回调高低小于这个值 就不刷新
  /// 默认为 40  根据实际需求设置 间隔高度更新
  final double gapUpdateHeight;

  @override
  State<ExtendedFlWebViewWithScrollView> createState() =>
      _ExtendedFlWebViewWithScrollViewState();
}

bool _differenceWithHeight(double h1, double h2, double gap) {
  var difference = h1 - h2;
  if (difference < 0) difference = -difference;
  return difference < gap;
}

class _ExtendedFlWebViewWithScrollViewState
    extends State<ExtendedFlWebViewWithScrollView> {
  /// scrollView 是否可以滚动
  bool isScrollView = false;

  /// 始终禁止 webView 滚动
  bool forbidScrollWeb = false;

  double currentHeight = 10;
  late ScrollController controller;
  late FlWebViewController webViewController;
  List<double> historyHeight = [];

  /// 禁止更新高度
  bool forbidUpdateHeight = false;

  @override
  void initState() {
    super.initState();
    currentHeight = widget.initialHeight;
    historyHeight.add(widget.initialHeight);
    initController();
  }

  void initController() {
    controller = widget.controller ?? ScrollController();
    controller.removeListener(listener);
    controller.addListener(listener);
  }

  void listener() {
    if (controller.offset <= 0 && isScrollView && !forbidScrollWeb) {
      isScrollView = false;
      controller.jumpTo(0);
      webViewController.enabledScroll(true).then((value) {
        webViewController.scrollBy(0, -(widget.faultTolerantHeight));
        if (mounted) setState(() {});
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
        size: Size(double.infinity, currentHeight),
        child: widget.webViewBuilder(
            onSizeChanged, onScrollChanged, onWebViewCreated));
    return widget.scrollViewBuilder(controller, isScrollView, webView);
  }

  void onSizeChanged(WebViewSize webViewSize) {
    var contentSizeHeight = webViewSize.contentSize.height;
    if (contentSizeHeight == 0 || currentHeight == contentSizeHeight) return;
    if (_differenceWithHeight(
        contentSizeHeight, historyHeight.last, widget.gapUpdateHeight)) {
      return;
    } else if (historyHeight.length > 1) {
      if (_differenceWithHeight(
          historyHeight[historyHeight.length - 1], contentSizeHeight, 10)) {
        if (!forbidUpdateHeight) {
          forbidUpdateHeight = true;
          currentHeight = historyHeight[historyHeight.length - 1];
          setState(() {});
        }
        return;
      }
    }
    historyHeight.add(contentSizeHeight);
    if (contentSizeHeight <= widget.contentHeight * 1.5) {
      isScrollView = true;
      if (currentHeight != contentSizeHeight) {
        currentHeight = contentSizeHeight;
        webViewController.enabledScroll(false);
        forbidScrollWeb = true;
        if (mounted) setState(() {});
      }
    } else {
      if (currentHeight != widget.contentHeight) {
        currentHeight = widget.contentHeight;
        isScrollView = false;
        forbidScrollWeb = false;
        webViewController.enabledScroll(true);
        if (mounted) setState(() {});
      }
    }
  }

  void onWebViewCreated(FlWebViewController controller) {
    webViewController = controller;
  }

  Future<void> onScrollChanged(WebViewSize webViewSize, Offset offset,
      ScrollPositioned positioned) async {
    if (positioned == ScrollPositioned.end && !isScrollView) {
      isScrollView = true;
      await webViewController.enabledScroll(false);
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
