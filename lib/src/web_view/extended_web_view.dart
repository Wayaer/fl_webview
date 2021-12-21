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
      {Key? key,
      required this.builder,
      this.initialHeight = 40,
      this.gapUpdateHeight = 40})
      : super(key: key);
  final FlAdaptHeightWevViewBuilder builder;

  /// 初始高度
  /// The initial height
  final double initialHeight;

  /// [onContentSizeChanged] 高度差距更新间隔 两次回调高低小于这个值 就不刷新
  /// 默认为 40  根据实际需求设置 间隔高度更新
  final double gapUpdateHeight;

  @override
  _FlAdaptHeightWevViewState createState() => _FlAdaptHeightWevViewState();
}

class _FlAdaptHeightWevViewState extends State<FlAdaptHeightWevView> {
  double currenrHeight = 10;
  List<double> historyHight = [];

  /// 禁止更新高度
  bool forbidUpdateHeight = false;

  @override
  void initState() {
    super.initState();
    currenrHeight = widget.initialHeight;
    historyHight.add(widget.initialHeight);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.fromSize(
        size: Size(double.infinity, currenrHeight),
        child: widget.builder(
            (Size frameSize, Size contentSize) =>
                changeHeight(frameSize, contentSize),
            (Size frameSize, Size contentSize, Offset offset,
                ScrollPositioned positioned) {
          if (contentSize.height > currenrHeight) {
            currenrHeight = contentSize.height;
            if (mounted) setState(() {});
          }
        }, (WebViewController controller) {
          controller.scrollEnabled(false);
        }, true));
  }

  void changeHeight(Size frameSize, Size contentSize) {
    var _contentSizeHeight = contentSize.height;
    if (_contentSizeHeight == 0 || currenrHeight == _contentSizeHeight) return;
    if (_differenceWithHeight(
        _contentSizeHeight, historyHight.last, widget.gapUpdateHeight)) {
      return;
    } else if (historyHight.length > 1) {
      if (_differenceWithHeight(
          historyHight[historyHight.length - 1], _contentSizeHeight, 10)) {
        if (!forbidUpdateHeight) {
          forbidUpdateHeight = true;
          currenrHeight = historyHight[historyHight.length - 1];
          setState(() {});
        }
        return;
      }
    }
    historyHight.add(_contentSizeHeight);
    if (currenrHeight != _contentSizeHeight) {
      currenrHeight = _contentSizeHeight;
      if (mounted) setState(() {});
    }
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
    this.minHeight = 15,
    this.faultTolerantHeight = 15,
    this.gapUpdateHeight = 40,
    this.initialHeight = 40,
  })  : assert(contentHeight > minHeight),
        super(key: key);

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

  /// 初始高度
  final double initialHeight;

  /// 当webview 滚动结束的时候 会自动在外层滚动组件跳转这个高度 即为容错高度
  /// 当外层滚动组件 到达最头部的时候 webview 自动向上滚动这个高度
  final int faultTolerantHeight;

  /// [onContentSizeChanged] 高度差距更新间隔 两次回调高低小于这个值 就不刷新
  /// 默认为 40  根据实际需求设置 间隔高度更新
  final double gapUpdateHeight;

  @override
  _ExtendedFlWebViewWithScrollViewState createState() =>
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

  /// 始终禁止webview 滚动
  bool forbidScrollWeb = false;

  double currenrHeight = 10;
  late ScrollController controller;
  late WebViewController webViewController;
  List<double> historyHight = [];

  /// 禁止更新高度
  bool forbidUpdateHeight = false;

  @override
  void initState() {
    super.initState();
    currenrHeight = widget.initialHeight;
    historyHight.add(widget.initialHeight);
    // lastHeight = widget.initialHeight;
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
      webViewController.scrollEnabled(true).then((value) {
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
        size: Size(double.infinity, currenrHeight),
        child: widget.webViewBuilder(
            onContentSizeChanged, onWebViewCreated, onScrollChanged));
    return widget.scrollViewBuilder(controller, isScrollView, webView);
  }

  void onContentSizeChanged(Size frameSize, Size contentSize) {
    var _contentSizeHeight = contentSize.height;
    if (_contentSizeHeight == 0 || currenrHeight == _contentSizeHeight) return;
    if (_differenceWithHeight(
        _contentSizeHeight, historyHight.last, widget.gapUpdateHeight)) {
      return;
    } else if (historyHight.length > 1) {
      if (_differenceWithHeight(
          historyHight[historyHight.length - 1], _contentSizeHeight, 10)) {
        if (!forbidUpdateHeight) {
          forbidUpdateHeight = true;
          currenrHeight = historyHight[historyHight.length - 1];
          setState(() {});
        }
        return;
      }
    }
    historyHight.add(_contentSizeHeight);
    if (_contentSizeHeight <= widget.contentHeight * 1.5) {
      isScrollView = true;
      if (currenrHeight != _contentSizeHeight) {
        currenrHeight = _contentSizeHeight;
        webViewController.scrollEnabled(false);
        forbidScrollWeb = true;
        if (mounted) setState(() {});
      }
    } else {
      if (currenrHeight != widget.contentHeight) {
        currenrHeight = widget.contentHeight;
        isScrollView = false;
        forbidScrollWeb = false;
        webViewController.scrollEnabled(true);
        if (mounted) setState(() {});
      }
    }
  }

  void onWebViewCreated(WebViewController controller) {
    webViewController = controller;
  }

  Future<void> onScrollChanged(Size size, Size contentSize, Offset offset,
      ScrollPositioned positioned) async {
    if (positioned == ScrollPositioned.end && !isScrollView) {
      isScrollView = true;
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
