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
  }) : super(key: key);

  /// webview 展示的高度
  final double webViewHeight;

  /// webView 头部的高度 默认为0
  final double headerHeight;

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
    final webView = SizedBox.fromSize(
        size: Size(double.infinity, widget.webViewHeight),
        child: FlWebView(
            onSizeChanged: widget.child.onSizeChanged,
            onWebViewCreated: widget.child.onWebViewCreated,
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
              switch (positioned) {
                case ScrollPositioned.start:
                  // log('===$positioned= 重置刷新=');
                  // canScroll = true;
                  // setState(() {});
                  break;
                case ScrollPositioned.scrolling:
                  break;
                case ScrollPositioned.end:
                  // log('===$positioned= 重置刷新=');
                  canScroll = true;
                  setState(() {});
                  break;
              }
              scrollPositioned = positioned;
              if (widget.child.onScrollChanged != null) {
                widget.child.onScrollChanged!(
                    size, contentSize, offset, positioned);
              }
            }));
    // log('builder===$canScroll');
    return NotificationListener<Notification>(
        onNotification: (Notification notifica) {
          // notification(notifica);
          return true;
        },
        child: widget.builder(controller, canScroll, webView));
  }

  void notification(Notification notifica) {
    if (notifica is ScrollUpdateNotification) {
      double offset = controller.offset;
      if (offset > widget.headerHeight &&
          offset < (widget.webViewHeight + 10) &&
          scrollPositioned != ScrollPositioned.scrolling) {
        if (canScroll) {
          canScroll = false;
          setState(() {});
          log('====${widget.headerHeight}');
          200.milliseconds.delayed(() {
            controller.animateTo(widget.headerHeight,
                duration: const Duration(milliseconds: 100),
                curve: Curves.linear);
          });
        }
      } else if (scrollPositioned == ScrollPositioned.end) {
        if (canScroll) {
          canScroll = false;
          setState(() {});
        }
      }
    }
  }
}

class NestedScrollWebView extends StatelessWidget {
  const NestedScrollWebView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double webHeight = deviceHeight -
        getStatusBarHeight -
        getBottomNavigationBarHeight -
        kToolbarHeight;
    return ExtendedScaffold(
        appBar: AppBar(title: const Text('FlWebView Example')),
        body: NestedWebView(
          // headerHeight: 200,
          webViewHeight: webHeight,
          builder:
              (ScrollController controller, bool canScroll, Widget webView) {
            log('===CustomScrollView=$canScroll==');
            return CustomScrollView(
                controller: controller,
                physics: canScroll
                    ? const BouncingScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
                slivers: [
                  // SliverListGrid(
                  //     itemBuilder: (_, int index) => Container(
                  //         height: 100,
                  //         width: double.infinity,
                  //         color: index.isEven
                  //             ? Colors.lightBlue
                  //             : Colors.amberAccent),
                  //     itemCount: 2),
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
            return ScrollList.builder(
                controller: controller,
                physics: canScroll
                    ? const AlwaysScrollableScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
                header: SliverToBoxAdapter(child: webView),
                itemBuilder: (_, int index) => Container(
                    height: 100,
                    width: double.infinity,
                    color:
                        index.isEven ? Colors.lightBlue : Colors.amberAccent),
                itemCount: 30);
          },
          child: const FlWebView(
              javascriptMode: JavascriptMode.unrestricted, initialUrl: url),
        ));
  }
}
