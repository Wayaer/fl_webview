import 'package:fl_webview/fl_webview.dart';
import 'package:flutter/material.dart';

typedef FlAdaptHeightWevViewBuilder = Widget Function(
    ContentSizeCallback onContentSizeChanged,
    ScrollChangedCallback onScrollChanged);

/// webview content 有多高， widget 就有多高
/// 在ios 如果webview 太高 图片太多 滑动会卡顿
class FlAdaptHeightWevView extends StatefulWidget {
  const FlAdaptHeightWevView(
      {Key? key, required this.builder, this.initialSize})
      : super(key: key);
  final FlAdaptHeightWevViewBuilder builder;
  final Size? initialSize;

  @override
  _FlAdaptHeightWevViewState createState() => _FlAdaptHeightWevViewState();
}

class _FlAdaptHeightWevViewState extends State<FlAdaptHeightWevView> {
  Size currenrSize = const Size(double.infinity, 50);

  @override
  void initState() {
    super.initState();
    if (widget.initialSize != null) currenrSize = widget.initialSize!;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.fromSize(
        size: currenrSize,
        child: widget.builder((Size size) {
          if (currenrSize.height != size.height) {
            currenrSize = Size(currenrSize.width, size.height);
            setState(() {});
          }
        }, (Size frameSize, Size contentSize, Offset offset,
            ScrollPositioned positioned) {
          if (contentSize.height > currenrSize.height) {
            currenrSize = Size(currenrSize.width, contentSize.height);
            setState(() {});
          }
        }));
  }
}

/// 返回的Widget树中需要包含[FlWebView]
typedef NestedFlWebViewBuilder = Widget Function(
    ContentSizeCallback onContentSizeChanged,
    WebViewCreatedCallback onWebViewCreated,
    ScrollChangedCallback onScrollChanged);

/// 返回的Widget树中需要包含[ScrollView]
typedef NestedScrollViewBuilder = Widget Function(
    ScrollController controller, bool canScroll, Widget webView);

/// 固定的webview 高度，建议设置为当前可视高度
/// 滚动中不会卡顿
class ExtendedFlWebViewWithScrollView extends StatefulWidget {
  const ExtendedFlWebViewWithScrollView({
    Key? key,
    required this.scrollViewBuilder,
    required this.webViewBuilder,
    this.controller,
    required this.webViewHeight,
  }) : super(key: key);

  /// scrollview
  final ScrollController? controller;
  final NestedScrollViewBuilder scrollViewBuilder;

  /// webview
  final NestedFlWebViewBuilder webViewBuilder;

  /// 必须要把webview 放在 scrollview的初始位置
  /// 建议设置为当前可视高度
  final double webViewHeight;

  @override
  _ExtendedFlWebViewWithScrollViewState createState() =>
      _ExtendedFlWebViewWithScrollViewState();
}

class _ExtendedFlWebViewWithScrollViewState
    extends State<ExtendedFlWebViewWithScrollView> {
  bool scrollViewPhysics = false;

  double webViewHeight = 10;
  bool noScrollWeb = true;
  Size contentSize = const Size(0, 0);
  late ScrollController controller;

  late WebViewController webViewController;

  @override
  void initState() {
    super.initState();
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
        webViewController.scrollBy(0, -10);
        setState(() {});
      });
    }
  }

  @override
  void didUpdateWidget(covariant ExtendedFlWebViewWithScrollView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      initController();
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget webView = SizedBox.fromSize(
        size: Size(double.infinity, webViewHeight),
        child: widget.webViewBuilder(
            onContentSizeChanged, onWebViewCreated, onScrollChanged));
    return widget.scrollViewBuilder(controller, scrollViewPhysics, webView);
  }

  void onContentSizeChanged(Size size) {
    contentSize = size;
    if (size.height > widget.webViewHeight) {
      noScrollWeb = true;
      if (webViewHeight != widget.webViewHeight) {
        setState(() {
          webViewHeight = widget.webViewHeight;
        });
      }
    } else {
      webViewHeight = size.height;
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
      controller.jumpTo(10);
      setState(() {});
    }
  }

  @override
  void dispose() {
    super.dispose();
    controller.removeListener(listener);
  }
}
