import 'dart:core';

import 'package:example/main.dart';
import 'package:fl_webview/fl_webview.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_waya/flutter_waya.dart';

typedef NestedScrollWebViewBuilder = ScrollView Function(
    ScrollController controller, bool canScroll, Widget webView);

class NestedWebView extends StatefulWidget {
  const NestedWebView({
    Key? key,
    this.headerHeight = 0,
    required this.webViewHeight,
    this.controller,
    required this.builder,
    required this.child,
    this.headerToleranceHeight = 10,
    this.footerToleranceHeight = 10,
  }) : super(key: key);

  /// webview 展示的高度
  final double webViewHeight;

  /// webView 头部的高度 默认为0
  final double headerHeight;

  /// header 和 webview 底部 容错高度
  final double headerToleranceHeight;
  final double footerToleranceHeight;

  /// ScrollView 的 controller
  final ScrollController? controller;

  final NestedScrollWebViewBuilder builder;

  /// webview
  final FlWebView child;

  @override
  _NestedWebViewState createState() => _NestedWebViewState();
}

class _NestedWebViewState extends State<NestedWebView> {
  bool canScroll = false;
  late ScrollController controller;
  ScrollPositioned? scrollPositioned;
  late bool isScrollView;
  bool isInit = false;
  Offset webOffset = const Offset(0, 0);
  Offset startOffset = const Offset(0, 0);
  late WebViewController webController;
  Size webContentSize = const Size(double.infinity, 10);

  bool isTouch = false;

  @override
  void initState() {
    super.initState();
    initController();
  }

  void initController() {
    canScroll = widget.headerHeight != 0;
    isScrollView = canScroll;
    controller = widget.controller ?? ScrollController();
    // controller.addListener(listener);
  }

  void listener() {
    isScrollView = true;
    // double offset = controller.offset;
    // log('$offset====$scrollPositioned');
    // if (offset > widget.headerHeight &&
    //     offset < (widget.webViewHeight + widget.headerHeight) &&
    //     scrollPositioned != ScrollPositioned.end) {
    //   if (canScroll && isScrollView) {
    //     canScroll = !canScroll;
    //     setState(() {});
    //     if (widget.headerHeight > 0) {
    //       log('====${widget.headerHeight}');
    //       200.milliseconds.delayed(() {
    //         controller.animateTo(widget.headerHeight,
    //             duration: const Duration(milliseconds: 100),
    //             curve: Curves.linear);
    //       });
    //     }
    //   }
    // }

    // double diff = controller.offset - widget.headerHeight;
    // if (diff > -1 && diff < 1) {
    //   if (canScroll && isScrollView) {
    //     log('$diff===canScroll:$canScroll');
    //     canScroll = !canScroll;
    //     if (widget.headerHeight > 0) {
    //       log('====${widget.headerHeight}');
    //       controller
    //           .animateTo(widget.headerHeight,
    //               duration: const Duration(milliseconds: 50),
    //               curve: Curves.linear)
    //           .then((value) {
    //         setState(() {});
    //       });
    //     } else {
    //       setState(() {});
    //     }
    //   }
    // }
  }

  @override
  void didUpdateWidget(covariant NestedWebView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.headerHeight != widget.headerHeight ||
        oldWidget.controller != widget.controller) {
      // controller.removeListener(listener);
      initController();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget webView = SizedBox.fromSize(
        size: Size(double.infinity, widget.webViewHeight),
        child: FlWebView(
            onContentSizeChanged: (Size size) {
              webContentSize = size;
              log(size);
              setState(() {});
              if (widget.child.onContentSizeChanged != null) {
                widget.child.onContentSizeChanged;
              }
            },
            onWebViewCreated: (WebViewController controller) {
              webController = controller;
              controller.scrollEnabled(false);

              if (widget.headerHeight > 0) {
                log(-widget.headerHeight.toInt());
                webController.scrollTo(0, -widget.headerHeight.toInt());
              }
              if (widget.child.onWebViewCreated != null) {
                widget.child.onWebViewCreated!(controller);
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
                ScrollPositioned positioned) {
              isScrollView = false;
              // controller.jumpTo(offset.dy);
              webContentSize = contentSize;
              // if (!isInit) {
              //   webOffset = offset;
              //   isInit = true;
              // }
              // if (positioned == ScrollPositioned.end ||
              //     (widget.headerHeight > 0 &&
              //         positioned == ScrollPositioned.start)) {
              //   log(positioned);
              //   if (!canScroll) {
              //     canScroll = !canScroll;
              //     setState(() {});
              //   }
              // }
              // log('===onScrollChanged===');
              // switch (positioned) {
              //   case ScrollPositioned.start:
              //     log('===$positioned= 重置刷新=');
              //     canScroll = true;
              //     setState(() {});
              //     break;
              //   case ScrollPositioned.scrolling:
              //     break;
              //   case ScrollPositioned.end:
              //     // log('===$positioned= 重置刷新=');
              //     canScroll = true;
              //     setState(() {});
              //     break;
              // }
              // scrollPositioned = positioned;
              // if (widget.child.onScrollChanged != null) {
              //   widget.child.onScrollChanged!(
              //       size, contentSize, offset, positioned);
              // }
            }));
    // log('builder===$canScroll');

    webView = GestureDetector(
        onTapDown: (TapDownDetails details) {
          log('onTapDown====');
          isTouch = true;
          // setState(() {});
        },
        onTapCancel: () {
          log('onTapCancel====');
          isTouch = false;
          // setState(() {});
        },
        child: webView);
    final pageNum = (webContentSize.height ~/ widget.webViewHeight);
    final remainderNum =
        webContentSize.height - (widget.webViewHeight * pageNum);
    final placeholder = SliverPadding(
        padding: EdgeInsets.only(bottom: remainderNum),
        sliver: SliverFixedExtentList(
          delegate: SliverChildBuilderDelegate(
              (_, __) => SizedBox(height: widget.webViewHeight)
                  .color(Colors.black87.withOpacity(0.4)),
              childCount: pageNum),
          itemExtent: widget.webViewHeight,
        ));

    Widget scrollView = NotificationListener<Notification>(
        onNotification: (Notification notifica) {
          // notification(notifica);
          onNotification(notifica);
          return true;
        },
        child: widget.builder(controller, canScroll, placeholder));
    List<Widget> children = [];
    children.addAll(isTouch ? [scrollView, webView] : [webView, scrollView]);
    return Stack(children: children);

    // child: GestureDetector(
    //   onVerticalDragStart: (DragStartDetails details) {
    //     startOffset = details.globalPosition;
    //     // log('start==$startOffset');
    //   },
    //   onVerticalDragUpdate: (DragUpdateDetails details) {
    //     var offset = details.globalPosition;
    //     // if(offset.dy>start)
    //     // log('update==$offset');
    //     if (startOffset.dy > offset.dy) {
    //       /// 往上滑动
    //       double dy = startOffset.dy - offset.dy;
    //
    //       log('往上滑动==$dy====${dy / getDevicePixelRatio} ');
    //       dy = dy / getDevicePixelRatio;
    //       dy = webOffset.dy + dy;
    //       if (dy > webContentSize.height) {
    //         return;
    //       }
    //
    //       webOffset = Offset(webOffset.dx, dy);
    //       // startOffset = webOffset;
    //       // webController.scrollBy(webOffset.dx.toInt(), dy.toInt());
    //       webController.scrollTo(webOffset.dx.toInt(), dy.toInt());
    //     } else {
    //       /// 往下滑动
    //       double dy = offset.dy - startOffset.dy;
    //       // log('update==$dy===${webOffset.dy + dy}');
    //       log('往下滑动==$dy====${dy / getDevicePixelRatio} ');
    //       dy = dy / getDevicePixelRatio;
    //
    //       // dy = webOffset.dy - dy;
    //       if (dy <= 0) {
    //         return;
    //       }
    //       webOffset = Offset(webOffset.dx, dy);
    //       // startOffset = webOffset;
    //       // webController.scrollBy(webOffset.dx.toInt(), dy.toInt());
    //       webController.scrollTo(webOffset.dx.toInt(), dy.toInt());
    //     }
    //   },
    //   onVerticalDragEnd: (DragEndDetails details) {},
    // )
  }

  void onNotification(Notification notifica) {
    if (controller.offset < (webContentSize.height - widget.webViewHeight)) {
      var offset = controller.offset.toInt();
      if (offset <= widget.headerHeight) {
        if (offset < 0) {
          offset = offset - widget.headerHeight.toInt();
        } else {
          offset = -offset;
        }
      }
      webController.scrollTo(0, offset);
    }
  }

// void notification(Notification notifica) {
//   if (notifica is ScrollUpdateNotification) {
//     double offset = controller.offset;
//     double diffHeader = offset - widget.headerHeight;
//     if (diffHeader < 0) diffHeader = -diffHeader;
//     double diffFooter = offset - widget.headerHeight - widget.webViewHeight;
//     if (diffFooter < 0) diffFooter = -diffFooter;
//     if (diffHeader < widget.headerToleranceHeight) {
//       if (canScroll) {
//         canScroll = false;
//         setState(() {});
//         log('====${widget.headerHeight}');
//         200.milliseconds.delayed(() {
//           controller.animateTo(widget.headerHeight,
//               duration: const Duration(milliseconds: 100),
//               curve: Curves.linear);
//         });
//       }
//     } else if (diffFooter < widget.footerToleranceHeight) {
//       if (canScroll) {
//         canScroll = false;
//         setState(() {});
//         log('====${widget.headerHeight}');
//         200.milliseconds.delayed(() {
//           controller.animateTo(widget.headerHeight + widget.webViewHeight,
//               duration: const Duration(milliseconds: 100),
//               curve: Curves.linear);
//         });
//       }
//     }
//   }
// }
}

class NestedScrollWebView extends StatelessWidget {
  const NestedScrollWebView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double webHeight = deviceHeight -
        getStatusBarHeight -
        getBottomNavigationBarHeight -
        kToolbarHeight -
        10;
    return ExtendedScaffold(
        appBar: AppBar(title: const Text('FlWebView Example')),
        body: NestedWebView(
          headerHeight: 200,
          webViewHeight: webHeight,
          builder:
              (ScrollController controller, bool canScroll, Widget webView) {
            log('===CustomScrollView=$canScroll==');
            return CustomScrollView(controller: controller,
                // physics: canScroll
                //     ? const BouncingScrollPhysics()
                //     : const NeverScrollableScrollPhysics(),
                slivers: [
                  SliverListGrid(
                      itemBuilder: (_, int index) => Container(
                          height: 100,
                          width: double.infinity,
                          color: index.isEven
                              ? Colors.lightBlue
                              : Colors.amberAccent),
                      itemCount: 2),
                  webView,
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
