import 'package:fl_webview/fl_webview.dart';
import 'package:fl_webview/src/extension.dart';
import 'package:flutter/material.dart';

typedef NestedWebViewBuilder = FlWebView Function(
    ContentSizeCallback onContentSizeChanged,
    PageFinishedCallback onPageFinished,
    WebViewCreatedCallback onWebViewCreated,
    ScrollChangedCallback onScrollChanged);

class NestedScrollWebView extends StatefulWidget {
  const NestedScrollWebView({
    Key? key,
    required this.controller,
    required this.scrollViewBuilder,
    required this.webViewBuilder,
  }) : super(key: key);

  final NestedScrollViewBuilder scrollViewBuilder;

  final NestedWebViewBuilder webViewBuilder;

  final ScrollWebViewController controller;

  @override
  _NestedScrollWebViewState createState() => _NestedScrollWebViewState();
}

class _NestedScrollWebViewState extends State<NestedScrollWebView> {
  Offset? interruptionPosition;
  MoveVerticalEvent? oldMoveEnvent;
  late ScrollWebViewController controller;
  bool handover = false;
  bool isNestedScroll = true;

  @override
  void initState() {
    super.initState();
    initController();
  }

  void initController() {
    controller = widget.controller;
  }

  @override
  Widget build(BuildContext context) {
    Widget webView = SizedBox.fromSize(
        size: Size(double.infinity, controller.webViewHeight),
        child: widget.webViewBuilder(onContentSizeChanged, onPageFinished,
            onWebViewCreated, onScrollChanged));
    return ScrollNotificationListener(
        onScrollVerticalEvent: onScrollVerticalEvent,
        controller: controller,
        child: widget.scrollViewBuilder(
            controller, controller.scrollViewPhysics, webView));
  }

  void onContentSizeChanged(Size size) {
    controller.onContentSizeChanged(size);
  }

  void onWebViewCreated(WebViewController _controller) {
    controller.onWebViewCreated(_controller);
    800.milliseconds.delayed(() {
      controller.scrollTo(0);
    });
  }

  void onPageFinished(String url) {
    if (controller.webContentSize.height < controller.webViewHeight) {
      controller.webViewHeight = controller.webContentSize.height;
      controller.webController?.scrollEnabled(false);
      isNestedScroll = false;
      setState(() {});
    }
  }

  Future<void> onScrollChanged(Size size, Size contentSize, Offset offset,
      ScrollPositioned positioned) async {
    controller.onScrollChanged(size, contentSize, offset, positioned);
    if (!isNestedScroll) return;

    if (positioned == ScrollPositioned.start && controller.headerHeight > 0) {
      controller.changeScrollWidget(CombinedScrollWidget.scrollView);
      setState(() {});
    } else if (positioned == ScrollPositioned.end &&
        controller.scrollEvent == ScrollVerticalEvent.down) {
      controller.changeScrollWidget(CombinedScrollWidget.scrollView);
      setState(() {});
    }
  }

  Future<void> onScrollVerticalEvent(Notification notifica) async {
    if (!controller.scrollViewPhysics) return;
    if (!isNestedScroll) return;
    double offset = controller.offset;

    /// 滚动webview
    Future<void> webScroll(double value) async {
      controller.isJumpScroll = true;
      controller.jumpTo(controller.headerHeight);
      await controller.scrollTo(value);
      await controller.changeScrollWidget(CombinedScrollWidget.webView);
      setState(() {});
    }

    switch (controller.scrollEvent) {
      case ScrollVerticalEvent.up:
        if (controller.webviewPositioned == ScrollPositioned.end &&
            offset <= controller.headerHeight) {
          log(controller.webContentSize.height);
          log(controller.webOffset);
          webScroll(controller.webContentSize.height - 10);
        }
        break;
      case ScrollVerticalEvent.down:
        if (controller.webviewPositioned != ScrollPositioned.end &&
            controller.headerHeight > 0 &&
            !controller.isJumpScroll &&
            offset > controller.headerHeight &&
            offset < controller.headerHeight + controller.webViewHeight) {
          webScroll(10);
        }
        break;
      default:
        break;
    }
  }
}

enum CombinedScrollWidget { webView, scrollView }

class ScrollWebViewController extends ScrollController {
  ScrollWebViewController({required this.webViewHeight, this.headerHeight = 0})
      : assert(webViewHeight >= 0),
        super() {
    _initCombinedScroll();
  }

  void _initCombinedScroll() {
    combinedScroll ??= headerHeight == 0
        ? CombinedScrollWidget.webView
        : CombinedScrollWidget.scrollView;
    scrollViewPhysics = headerHeight != 0;
    webviewPositioned = ScrollPositioned.start;
  }

  /// WebViewController
  WebViewController? webController;

  /// webview 展示的高度
  double webViewHeight;

  /// webView 头部的高度 默认为0
  final double headerHeight;

  /// 组合总高度 webview + scrollview ;
  double combinedMaxScrollExtent = 0;

  double webOffset = 0;

  /// webview 内容的真实大小
  Size webContentSize = const Size(0, 0);

  CombinedScrollWidget? combinedScroll;

  /// 根据此参数设置 ScrollView 的 physics
  /// [scrollViewPhysics]=false physics 必须设置 [NeverScrollableScrollPhysics]
  bool scrollViewPhysics = false;

  /// 最近一次滚动时 是否是手势滚动
  bool isGestureScroll = true;

  /// 是否在滚动中
  bool isJumpScroll = false;

  /// 当前最近一次滚动时的状态
  ScrollVerticalEvent? scrollEvent;

  @override
  void jumpTo(double value) {
    isGestureScroll = false;
    super.jumpTo(value);
  }

  /// webview 滚动的位置
  ScrollPositioned? webviewPositioned;

  Future<void> scrollTo(double offset) async {
    assert(webController != null);
    // log('offset====${offset.toInt()}');
    await webController!.scrollTo(0, offset.toInt());
  }

  Future<void> scrollBy(double offset) async {
    assert(webController != null);
    await webController!.scrollBy(0, offset.toInt());
  }

  /// [FlWebView] 的 onScrollChanged
  void onScrollChanged(
      Size size, Size contentSize, Offset offset, ScrollPositioned positioned) {
    webContentSize = contentSize;
    combinedMaxScrollExtent =
        contentSize.height + position.maxScrollExtent - webViewHeight;
    webOffset = offset.dy;
    if (webviewPositioned != positioned) {
      webviewPositioned = positioned;
    }
  }

  /// 修改滚动组件
  Future<void> changeScrollWidget(CombinedScrollWidget combinedScroll) async {
    assert(webController != null);
    switch (combinedScroll) {
      case CombinedScrollWidget.webView:
        scrollViewPhysics = false;
        await webController!.scrollEnabled(true);
        break;
      case CombinedScrollWidget.scrollView:
        scrollViewPhysics = true;
        await webController!.scrollEnabled(false);
        break;
    }
  }

  /// [FlWebView] 的 onContentSizeChanged
  void onContentSizeChanged(Size size) {
    _initCombinedScroll();
    webContentSize = size;
    combinedMaxScrollExtent =
        size.height + position.maxScrollExtent - webViewHeight;
  }

  /// [FlWebView] 的 onWebViewCreated
  void onWebViewCreated(WebViewController controller) {
    _initCombinedScroll();
    webController = controller;
  }
}

enum ScrollVerticalEvent {
  /// 往上滚动
  up,

  /// 往下滚动
  down,
}

typedef ScrollVerticalEventState = void Function(Notification notification);

class ScrollNotificationListener extends StatelessWidget {
  const ScrollNotificationListener(
      {Key? key,
      required this.child,
      required this.controller,
      this.onScrollVerticalEvent})
      : super(key: key);
  final Widget child;
  final ScrollWebViewController controller;
  final ScrollVerticalEventState? onScrollVerticalEvent;

  @override
  Widget build(BuildContext context) {
    double? y;
    return NotificationListener(
        onNotification: (Notification notification) {
          if (notification is ScrollStartNotification) {
            y = controller.offset;
          } else if (notification is ScrollUpdateNotification) {
            if (y != null) {
              if (controller.offset > y!) {
                controller.scrollEvent = ScrollVerticalEvent.down;
              } else {
                controller.scrollEvent = ScrollVerticalEvent.up;
              }
            }
          } else if (notification is ScrollEndNotification) {
            controller.scrollEvent = null;
            y = null;
            controller.isJumpScroll = false;
            500.milliseconds.delayed(() {
              controller.isGestureScroll = true;
            });
          }
          if (onScrollVerticalEvent != null &&
              controller.scrollEvent != null &&
              controller.isGestureScroll) {
            onScrollVerticalEvent!(notification);
          }
          return true;
        },
        child: child);
  }
}

enum MoveVerticalEvent {
  /// 上滑
  up,

  /// 停留
  stay,

  /// 下滑
  down,
}

typedef PointerMoveEventState = void Function(
    MoveVerticalEvent moveEvent, PointerMoveEvent event, double distance);

class ScrollListener extends StatelessWidget {
  const ScrollListener(
      {Key? key,
      required this.child,
      this.onPointerCancel,
      this.onPointerDown,
      this.onPointerMove,
      this.onPointerUp,
      this.onMoveVerticalEvent})
      : super(key: key);
  final Widget child;
  final PointerCancelEventListener? onPointerCancel;
  final PointerDownEventListener? onPointerDown;
  final PointerMoveEventListener? onPointerMove;
  final PointerUpEventListener? onPointerUp;
  final PointerMoveEventState? onMoveVerticalEvent;

  @override
  Widget build(BuildContext context) {
    MoveVerticalEvent moveEvent = MoveVerticalEvent.stay;
    Offset? downPosition;
    return Listener(
        child: child,
        onPointerCancel: onPointerCancel,
        onPointerDown: (PointerDownEvent event) {
          downPosition = event.localPosition;
          if (onPointerDown != null) onPointerDown!(event);
        },
        onPointerUp: onPointerUp,
        onPointerMove: (PointerMoveEvent event) {
          var localDelta = event.localDelta;
          if (localDelta.dy == 0) {
            moveEvent = MoveVerticalEvent.stay;
          } else if (localDelta.dy > 0) {
            moveEvent = MoveVerticalEvent.down;
          } else if (localDelta.dy < 0) {
            moveEvent = MoveVerticalEvent.up;
          }

          if (onMoveVerticalEvent != null && downPosition != null) {
            double distance = event.localPosition.dy - downPosition!.dy;
            onMoveVerticalEvent!(moveEvent, event, distance);
          }
          if (onPointerMove != null) onPointerMove!(event);
        });
  }
}
