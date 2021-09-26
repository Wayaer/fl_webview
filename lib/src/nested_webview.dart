import 'package:fl_webview/fl_webview.dart';
import 'package:fl_webview/src/extension.dart';
import 'package:flutter/material.dart';

typedef NestedScrollWebViewBuilder = ScrollView Function(
    ScrollWebViewController controller, bool canScroll, Widget webView);

class NestedWebView extends StatefulWidget {
  const NestedWebView({
    Key? key,
    required this.builder,
    required this.child,
    required this.controller,
  }) : super(key: key);

  final NestedScrollWebViewBuilder builder;
  final ScrollWebViewController controller;

  /// webview
  final FlWebView child;

  @override
  _NestedWebViewState createState() => _NestedWebViewState();
}

class _NestedWebViewState extends State<NestedWebView> {
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
        child: FlWebView(
            initialUrl: widget.child.initialUrl,
            initialData: widget.child.initialData,
            javascriptMode: widget.child.javascriptMode,
            javascriptChannels: widget.child.javascriptChannels,
            navigationDelegate: widget.child.navigationDelegate,
            gestureRecognizers: widget.child.gestureRecognizers,
            onPageStarted: widget.child.onPageStarted,
            onPageFinished: onPageFinished,
            onScrollChanged: onScrollChanged,
            onProgress: widget.child.onProgress,
            onWebResourceError: widget.child.onWebResourceError,
            debuggingEnabled: widget.child.debuggingEnabled,
            gestureNavigationEnabled: widget.child.gestureNavigationEnabled,
            userAgent: widget.child.userAgent,
            initialMediaPlaybackPolicy: widget.child.initialMediaPlaybackPolicy,
            allowsInlineMediaPlayback: widget.child.allowsInlineMediaPlayback,
            onContentSizeChanged: onContentSizeChanged,
            onWebViewCreated: onWebViewCreated));
    return ScrollListener(
      onMoveVerticalEvent: onMoveVerticalEvent,
      onPointerUp: onPointerUp,
      onPointerCancel: (PointerCancelEvent event) {
        interruptionPosition = null;
      },
      child: ScrollNotificationListener(
          onScrollVerticalEvent: onScrollVerticalEvent,
          controller: controller,
          child: widget.builder(
              controller, controller.scrollViewPhysics, webView)),
    );
  }

  void onContentSizeChanged(Size size) {
    controller.onContentSizeChanged(size);
    if (widget.child.onContentSizeChanged != null) {
      widget.child.onContentSizeChanged;
    }
  }

  void onWebViewCreated(WebViewController _controller) {
    controller.onWebViewCreated(_controller);
    800.milliseconds.delayed(() {
      controller.scrollTo(0);
    });
    if (widget.child.onWebViewCreated != null) {
      widget.child.onWebViewCreated!(_controller);
    }
  }

  void onPageFinished(String url) {
    if (controller.webContentSize.height < controller.webViewHeight) {
      controller.webViewHeight = controller.webContentSize.height;
      controller.webController?.scrollEnabled(false);
      isNestedScroll = false;
      setState(() {});
    }

    if (widget.child.onPageFinished != null) {
      widget.child.onPageFinished!(url);
    }
  }

  Future<void> onScrollChanged(Size size, Size contentSize, Offset offset,
      ScrollPositioned positioned) async {
    controller.onScrollChanged(size, contentSize, offset, positioned);
    if (!isNestedScroll) return;
    if (positioned == ScrollPositioned.start) {
      controller.changeScrollWidget(CombinedScrollWidget.scrollView);
      setState(() {});
    } else if (positioned == ScrollPositioned.end &&
        controller.scrollEvent == ScrollVerticalEvent.down) {
      controller.changeScrollWidget(CombinedScrollWidget.scrollView);
      setState(() {});
    }
    if (widget.child.onScrollChanged != null) {
      widget.child.onScrollChanged!(size, contentSize, offset, positioned);
    }
  }

  void onPointerUp(PointerUpEvent event) {
    if (!isNestedScroll) return;
    handover = false;
    if (controller.scrollViewPhysics) {
      if (controller.offset == controller.webViewHeight) {
        controller.webController!.getScrollY().then((value) {
          log('onPointerCancel=====${controller.scrollViewPhysics}');
          log('getScrollY=$value');
          if (value > 0) {
            controller
                .changeScrollWidget(CombinedScrollWidget.webView)
                .then((value) {
              setState(() {});
            });
          }
        });
      }
    } else if (controller.webviewPositioned == ScrollPositioned.end) {
      log('onPointerCancel=====ScrollPositioned.end');
      controller
          .changeScrollWidget(CombinedScrollWidget.scrollView)
          .then((value) {
        setState(() {});
      });
    }
  }

  Future<void> onMoveVerticalEvent(MoveVerticalEvent moveEvent,
      PointerMoveEvent event, double distance) async {
    if (!isNestedScroll) return;
    return;
    final position = event.localPosition;
    if (oldMoveEnvent != moveEvent) {
      interruptionPosition = null;
      handover = false;
    }
    switch (moveEvent) {
      case MoveVerticalEvent.up:
        log('=====$moveEvent===$distance===');
        if (controller.offset >= controller.headerHeight) {
          if (interruptionPosition == null) {
            log('上滑设置拦截开始的坐标==${controller.scrollViewPhysics}');
            interruptionPosition = position;
          } else if (controller.scrollViewPhysics) {
            var distance = (position.dy - interruptionPosition!.dy).abs();
            log('上滑单次中断滑动距离：$distance');
            if (controller.offset != controller.headerHeight) {
              controller.jumpTo(controller.headerHeight);
            }
            controller.scrollTo(distance);
          }
        }
        break;
      case MoveVerticalEvent.stay:
        break;
      case MoveVerticalEvent.down:
        if (controller.offset >= controller.headerHeight) {
          if (interruptionPosition == null) {
            interruptionPosition = Offset(position.dx.abs(), position.dy.abs());
            log('下滑滑设置拦截开始的坐标==$interruptionPosition');
          } else if (controller.scrollViewPhysics) {
            log('controller.scrollViewPhysics==${controller.scrollViewPhysics}');
            controller.webController!.getScrollY().then((value) {
              log('controller.webController.getScrollY==$value');
              if (value > 0) {
                var distance =
                    value - (position.dy - interruptionPosition!.dy).abs();
                if (distance <= 0) {
                  controller.scrollTo(0);
                } else {
                  controller.scrollTo(distance);
                  if (controller.offset != controller.headerHeight) {
                    controller.jumpTo(controller.headerHeight);
                  }
                }
                // interruptionPosition =
                //     Offset(position.dx.abs(), position.dy.abs());
              } else {
                var distance = position.dy - interruptionPosition!.dy;
                log('上滑到顶部走这里===$distance');
                controller.jumpTo(controller.headerHeight - distance);
                interruptionPosition = null;
                handover = true;
              }
            });
          }
        } else {
          if (interruptionPosition == null) {
            interruptionPosition = Offset(position.dx.abs(), position.dy.abs());
            log('下滑滑设置拦截开始的坐标======$interruptionPosition');
          } else if (handover) {
            var distance = position.dy - interruptionPosition!.dy;
            log('上滑到顶部走这里=======$distance');
            controller.jumpTo(controller.headerHeight - distance);
          }
        }
        break;
    }
    oldMoveEnvent = moveEvent;
  }

  Future<void> onScrollVerticalEvent(Notification notifica) async {
    if (!controller.scrollViewPhysics) return;
    if (!isNestedScroll) return;
    double offset = controller.offset;
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
          webScroll(controller.webOffset - 10);
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

  //
  // /// 组合总偏移位置
  // double get combinedOffset {
  //   double _combinedOffset = 0;
  //   double halfHeaderTolerance = 0;
  //   if (headerHeight > 0) halfHeaderTolerance = headerToleranceHeight / 2;
  //   double actualHeaderHeight = headerHeight - halfHeaderTolerance;
  //   if (offset < actualHeaderHeight) {
  //     _combinedOffset = offset;
  //   } else if (offset >= actualHeaderHeight && offset < headerHeight) {
  //     double halfFooterTolerance = footerToleranceHeight / 2;
  //     double actualWebViewHeight = webContentSize.height - halfFooterTolerance;
  //     if (webOffset <= halfHeaderTolerance) {
  //       _combinedOffset = headerHeight;
  //     } else if (webOffset > halfHeaderTolerance &&
  //         webOffset <= actualWebViewHeight) {
  //       _combinedOffset = webOffset + headerHeight;
  //     } else if (webOffset > actualWebViewHeight) {
  //       _combinedOffset = offset + actualWebViewHeight - webViewHeight;
  //     }
  //   }
  //   return _combinedOffset;
  // }

  /// webview 滚动的位置
  ScrollPositioned? webviewPositioned;

  // /// 跳转至指定位置
  // Future<bool> jumpToOffset(double value,
  //     {bool animate = false,
  //     Duration duration = const Duration(milliseconds: 10),
  //     Curve curve = Curves.linear}) async {
  //   /// scrollview 跳转
  //   Future<bool> scrollViewJumpTo(double value) async {
  //     if (value <= 0) return false;
  //     if (animate) {
  //       await animateTo(value, duration: duration, curve: curve);
  //     } else {
  //       jumpTo(value);
  //     }
  //     return true;
  //   }
  //
  //   /// webview 跳转
  //   Future<bool> webViewJumoTo(double value) async {
  //     if (value <= 0) return false;
  //     assert(webController != null);
  //     await webController!.scrollTo(0, value.toInt());
  //     return true;
  //   }
  //
  //   double halfFooterTolerance = footerToleranceHeight / 2;
  //   double actualWebViewHeight = webContentSize.height - halfFooterTolerance;
  //
  //   if (value > combinedMaxScrollExtent) {
  //     await webViewJumoTo(actualWebViewHeight);
  //     await scrollViewJumpTo(position.maxScrollExtent);
  //     return true;
  //   }
  //
  //   /// 容错高度的一半
  //   double halfHeaderTolerance = 0;
  //
  //   if (headerHeight > 0) halfHeaderTolerance = headerToleranceHeight / 2;
  //
  //   /// 头部的高度
  //   double actualHeaderHeight = headerHeight - halfHeaderTolerance;
  //   bool hasNotifyListeners = false;
  //   if (value < actualHeaderHeight) {
  //     log('===header内==有header');
  //     hasNotifyListeners = await scrollViewJumpTo(value);
  //     await webViewJumoTo(0);
  //   } else if (value <= headerHeight && value > actualHeaderHeight) {
  //     log('===header内容错区域==有header');
  //     hasNotifyListeners = await scrollViewJumpTo(actualHeaderHeight);
  //     await webViewJumoTo(halfHeaderTolerance);
  //   } else if (value > headerHeight &&
  //       value < headerHeight + halfHeaderTolerance) {
  //     log('===webview header 容错区域==有header');
  //     hasNotifyListeners = await scrollViewJumpTo(headerHeight);
  //     await webViewJumoTo(halfHeaderTolerance);
  //   } else if (value > headerHeight + halfHeaderTolerance &&
  //       value <= headerHeight + actualWebViewHeight) {
  //     log('===webview 内==有header');
  //     hasNotifyListeners = await scrollViewJumpTo(headerHeight);
  //     await webViewJumoTo(value);
  //   } else if (value > headerHeight + actualWebViewHeight &&
  //       value <= webContentSize.height) {
  //     log('===webview 内底部容错区域==有header');
  //     hasNotifyListeners = await scrollViewJumpTo(actualHeaderHeight);
  //     await webViewJumoTo(webContentSize.height - halfFooterTolerance);
  //   } else if (value > headerHeight + webContentSize.height &&
  //       value < headerHeight + webContentSize.height + halfFooterTolerance) {
  //     log('===fotter 容错区域==footer');
  //     hasNotifyListeners =
  //         await scrollViewJumpTo(webViewHeight + halfFooterTolerance);
  //     await webViewJumoTo(webContentSize.height - halfFooterTolerance);
  //   } else if (value >
  //           headerHeight + webContentSize.height + halfFooterTolerance &&
  //       value < combinedMaxScrollExtent) {
  //     log('===fotter 外');
  //     await webViewJumoTo(actualWebViewHeight);
  //     double v = value - webContentSize.height;
  //     hasNotifyListeners = await scrollViewJumpTo(webViewHeight + v);
  //   } else {
  //     log('===最底部');
  //     await webViewJumoTo(actualWebViewHeight);
  //     hasNotifyListeners = await scrollViewJumpTo(position.maxScrollExtent);
  //     return true;
  //   }
  //   if (!hasNotifyListeners) {
  //     notifyListeners();
  //   }
  //   return true;
  // }

  Future<void> scrollTo(double offset) async {
    assert(webController != null);
    log('offset====${offset.toInt()}');
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
