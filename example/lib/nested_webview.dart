import 'dart:core';

import 'package:example/main.dart';
import 'package:fl_webview/fl_webview.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_waya/flutter_waya.dart';

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
  Offset? downPosition;
  Offset? interruptionPosition;
  Offset? oldMovePosition;

  /// 是否上滑
  bool? isWipeUp;
  bool? oldWipeUp;

  late ScrollWebViewController controller;

  @override
  void initState() {
    super.initState();
    initController();
  }

  void initController() {
    controller = widget.controller;
    // controller.addListener(() {
    //   controller.webController!.getScrollY().then((value) {
    //     log('combinedScroll:${controller.combinedScroll}==\n'
    //         'combinedOffset:${controller.combinedOffset}==\n'
    //         'offset:${controller.offset}==\n'
    //         'webViewOffset:$value==\n'
    //         'combinedMaxScrollExtent:${controller.combinedMaxScrollExtent}==\n'
    //         'webViewHeight:${controller.webViewHeight}==\n'
    //         'maxScrollExtent:${controller.position.maxScrollExtent}==\n'
    //         'webContentSize:${controller.webContentSize}==\n'
    //         'scrollViewPhysics:${controller.scrollViewPhysics}==\n'
    //         '');
    //   });
    // });
  }

  @override
  Widget build(BuildContext context) {
    Widget webView = SizedBox.fromSize(
        size: Size(double.infinity, controller.webViewHeight),
        child: FlWebView(
            onContentSizeChanged: (Size size) {
              controller.onContentSizeChanged(size);
              if (widget.child.onContentSizeChanged != null) {
                widget.child.onContentSizeChanged;
              }
            },
            onWebViewCreated: (WebViewController _controller) {
              controller.onWebViewCreated(_controller);
              1.seconds.delayed(() {
                controller.scrollTo(0);
              });
              if (widget.child.onWebViewCreated != null) {
                widget.child.onWebViewCreated!(_controller);
              }
            },
            initialUrl: widget.child.initialUrl,
            initialData: widget.child.initialData,
            javascriptMode: widget.child.javascriptMode,
            javascriptChannels: widget.child.javascriptChannels,
            navigationDelegate: widget.child.navigationDelegate,
            gestureRecognizers: widget.child.gestureRecognizers,
            onPageStarted: widget.child.onPageStarted,
            onPageFinished: widget.child.onPageFinished,
            onProgress: widget.child.onProgress,
            onWebResourceError: widget.child.onWebResourceError,
            debuggingEnabled: widget.child.debuggingEnabled,
            gestureNavigationEnabled: widget.child.gestureNavigationEnabled,
            userAgent: widget.child.userAgent,
            initialMediaPlaybackPolicy: widget.child.initialMediaPlaybackPolicy,
            allowsInlineMediaPlayback: widget.child.allowsInlineMediaPlayback,
            onScrollChanged: (Size size, Size contentSize, Offset offset,
                ScrollPositioned positioned) async {
              controller.onScrollChanged(size, contentSize, offset, positioned);
              // scrollPositioned = positioned;
              // log('onScrollChanged offset : $offset');
              // if (!canScroll && canSwitch) {
              //   // log('===$canScroll===${!canSwitch}');
              //   switch (positioned) {
              //     case ScrollPositioned.start:
              //       if (widget.headerHeight > 0) {
              //         canScroll = true;
              //         await controller.webController!.scrollEnabled(false);
              //         // animateTo(widget.headerHeight -
              //         //     widget.headerToleranceHeight -
              //         //     1);
              //         // setState(() {});
              //       }
              //       break;
              //     case ScrollPositioned.scrolling:
              //       break;
              //     case ScrollPositioned.end:
              //       log(positioned);
              //       canScroll = true;
              //       await controller.webController!.scrollEnabled(false);
              //       // animateTo(
              //       //     controller.offset + widget.footerToleranceHeight + 1);
              //       canSwitch = false;
              //       // setState(() {});
              //       break;
              //   }
              // }
              if (widget.child.onScrollChanged != null) {
                widget.child.onScrollChanged!(
                    size, contentSize, offset, positioned);
              }
            }));
    return ScrollListener(
      onPointerDown: (PointerDownEvent event) {
        downPosition = event.localPosition;
      },
      onMoveVerticalEvent: (MoveVerticalEvent moveEvent, PointerMoveEvent event,
          double distance) {
        log('=====$moveEvent');
      },
      onPointerMove: (PointerMoveEvent event) {
        var localDelta = event.localDelta;
        if (controller.offset >= controller.headerHeight) {
          if (localDelta.dy < 0) {
            // controller.scrollTo();

          } else {}
        }
        var position = event.localPosition;
        isWipeUp = downPosition!.dy < position.dy;
        oldMovePosition = position;
        if (oldWipeUp != isWipeUp) {
          interruptionPosition = position;
        }
        // if (isWipeUp!) {
        //   if (controller.offset >= controller.headerHeight) {
        //     log('---$oldWipeUp---$isWipeUp');
        //     if (interruptionPosition == null || oldWipeUp != isWipeUp) {
        //       log('下滑设置拦截开始的坐标==${controller.scrollViewPhysics}');
        //       interruptionPosition = position;
        //     } else if (!controller.scrollViewPhysics) {
        //       var distance = (position.dy - interruptionPosition!.dy).abs();
        //       log('下滑单次中断滑动距离：$distance');
        //       controller.jumpTo(controller.headerHeight);
        //       controller.scrollTo(distance);
        //     }
        //   }
        // } else {
        if (controller.offset >= controller.headerHeight) {
          if (interruptionPosition == null) {
            log('设置拦截开始的坐标==${controller.scrollViewPhysics}');
            interruptionPosition = position;
          } else {
            var distance = interruptionPosition!.dy - position.dy;
            log('上滑单次中断滑动距离：$distance');
            if (distance >= 0) {
              controller.jumpTo(controller.headerHeight);
              controller.scrollTo(distance);
            } else {
              log(controller.headerHeight + distance);
              controller.jumpTo(controller.headerHeight + distance);
            }
          }
        } else {
          controller.scrollTo(0);
          var distance = interruptionPosition!.dy - position.dy;
          controller.jumpTo(controller.headerHeight + distance);
        }
        oldWipeUp = isWipeUp;
      },
      onPointerUp: (PointerUpEvent event) {
        downPosition = null;
        isWipeUp = null;
        log('onPointerCancel=====');
        if (controller.scrollViewPhysics) {
          controller.webController!.getScrollY().then((value) {
            log('getScrollY=$value');
            if (value > 0) {
              controller.changeScrollWidget().then((value) {
                setState(() {});
              });
            }

            // if (value <= controller.headerToleranceHeight / 2) {
            //   controller.webviewPositioned = ScrollPositioned.start;
            //   controller.scrollViewPhysics = true;
            // } else if (controller.webviewPositioned !=
            //     ScrollPositioned.scrolling) {
            //   log('设置为滚动中');
            //   controller.webviewPositioned = ScrollPositioned.scrolling;
            //   controller.scrollViewPhysics = false;
            //   controller.webController!.scrollEnabled(true).then((value) {
            //     setState(() {});
            //   });
            // }
          });
        }
      },
      onPointerCancel: (PointerCancelEvent event) {
        downPosition = null;
        isWipeUp = null;
        interruptionPosition = null;
        // log('onPointerCancel=====');
        // webController.getScrollY().then((value) {
        //   log('=getScrollY=$value');
        // });
      },
      child: NotificationListener(
          onNotification: (Notification notifica) {
            onNotification(notifica);
            return true;
          },
          child: widget.builder(
              controller, controller.scrollViewPhysics, webView)),
    );
  }

  void onMoveEnd() {}

  Future<void> onNotification(Notification notifica) async {
    if (!controller.scrollViewPhysics) return;
    double offset = controller.offset;
    if (controller.headerHeight > 0) {
      // if (offset > controller.headerHeight &&
      //     offset < controller.headerHeight + controller.webViewHeight) {
      //   controller.scrollViewPhysics = false;
      // }
      // double diffHeader = offset - controller.headerHeight;
      // if (diffHeader < 0) diffHeader = -diffHeader;
      // if (diffHeader < controller.headerToleranceHeight) {
      //   controller.scrollViewPhysics = false;
      //   // animateTo(widget.headerHeight);
      //   // await webController.scrollEnabled(true);
      //   // await scrollTo(widget.headerToleranceHeight);
      //   // setState(() {});
      // }
    }

    // if(offset>controller.headerHeight + controller.webViewHeight)
    // double diffFooter =
    //     offset - controller.headerHeight - controller.webViewHeight;
    // if (diffFooter < 0) diffFooter = -diffFooter;
    // if (diffFooter < controller.footerToleranceHeight && isWipeUp == true) {
    //   controller.scrollViewPhysics = false;
    //   // await webController.scrollEnabled(true);
    //   // await scrollTo(webContentSize.height - widget.footerToleranceHeight);
    //   // animateTo(widget.headerHeight + widget.webViewHeight);
    //   // setState(() {});
    // }
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
            moveEvent = MoveVerticalEvent.down;
          }

          if (onMoveVerticalEvent != null && downPosition != null) {
            double distance = downPosition!.dy - event.position.dy;
            onMoveVerticalEvent!(moveEvent, event, distance);
          }
          if (onPointerMove != null) onPointerMove!(event);
        });
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
  }

  /// WebViewController
  WebViewController? webController;

  /// webview 展示的高度
  final double webViewHeight;

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
      if (webviewPositioned == ScrollPositioned.start ||
          webviewPositioned == ScrollPositioned.end) {
        combinedScroll = CombinedScrollWidget.scrollView;
      } else {
        combinedScroll = CombinedScrollWidget.webView;
      }
      // changeScrollWidget().then((value) {
      //   notifyListeners();
      // });
    }
  }

  /// 修改滚动组件
  Future<void> changeScrollWidget() async {
    assert(combinedScroll != null);
    assert(webController != null);
    switch (combinedScroll!) {
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

class NestedScrollWebView extends StatelessWidget {
  const NestedScrollWebView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ScrollWebViewController? scrollWebViewController;
    double webHeight = deviceHeight -
        getStatusBarHeight -
        getBottomNavigationBarHeight -
        kToolbarHeight -
        10;
    return ExtendedScaffold(
        appBar: AppBar(title: const Text('NestedScrollWebView Example')),
        body: NestedWebView(
          controller: ScrollWebViewController(
              headerHeight: 200, webViewHeight: webHeight),
          builder: (ScrollWebViewController controller, bool canScroll,
              Widget webView) {
            log('===CustomScrollView=$canScroll==');
            scrollWebViewController = controller;
            return CustomScrollView(
                controller: controller,
                physics: canScroll
                    ? const BouncingScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
                slivers: [
                  SliverListGrid(
                      itemBuilder: (_, int index) => Container(
                          height: 100,
                          width: double.infinity,
                          color: index.isEven
                              ? Colors.lightBlue
                              : Colors.amberAccent),
                      itemCount: 2),
                  // webView,
                  SliverToBoxAdapter(child: webView),
                  SliverListGrid(
                      itemBuilder: (_, int index) => Container(
                          height: 100,
                          width: double.infinity,
                          color: index.isEven
                              ? Colors.lightBlue
                              : Colors.amberAccent),
                      itemCount: 30)
                ]);
            // return ScrollList.builder(
            //     controller: controller,
            //     physics: canScroll
            //         ? const AlwaysScrollableScrollPhysics()
            //         : const NeverScrollableScrollPhysics(),
            //     header: SliverToBoxAdapter(child: webView),
            //     itemBuilder: (_, int index) => Container(
            //         height: 100,
            //         width: double.infinity,
            //         color:
            //             index.isEven ? Colors.lightBlue : Colors.amberAccent),
            //     itemCount: 30);
          },
          child: const FlWebView(
              javascriptMode: JavascriptMode.unrestricted, initialUrl: url),
        ));
  }
}
