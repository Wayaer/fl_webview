import 'dart:core';

import 'package:example/main.dart';
import 'package:fl_webview/fl_webview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_waya/flutter_waya.dart';

class NestedScrollWebView extends StatefulWidget {
  const NestedScrollWebView({Key? key}) : super(key: key);

  @override
  _NestedScrollWebViewState createState() => _NestedScrollWebViewState();
}

class _NestedScrollWebViewState extends State<NestedScrollWebView> {
  ScrollPhysics physics = const NeverScrollableScrollPhysics();
  ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    scrollController.addListener(() {
      if (scrollController.offset <= 0) {
        if (physics != const NeverScrollableScrollPhysics()) {
          physics = const NeverScrollableScrollPhysics();
          setState(() {});
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    log('build====');
    double bodyHeight = deviceHeight -
        getStatusBarHeight -
        getBottomNavigationBarHeight -
        kToolbarHeight;
    return ExtendedScaffold(
        appBar: AppBar(title: const Text('FlWebView Example')),
        body: CustomScrollView(
            controller: scrollController,
            physics: physics,
            slivers: [
              SliverToBoxAdapter(
                  child: SizedBox(height: bodyHeight, child: webView())),
              SliverListGrid(
                  itemBuilder: (_, int index) {
                    return Container(
                        height: 100,
                        width: double.infinity,
                        color: index.isEven
                            ? Colors.lightBlue
                            : Colors.amberAccent);
                  },
                  itemCount: 1000)
            ]));
  }

  Widget webView() {
    late ScrollPhysics _physics = const NeverScrollableScrollPhysics();
    Widget web = _FlWebView(onScrollChanged: (Size size, Size contentSize,
        Offset offset, ScrollPositioned positioned) {
      log('beyond=== ${offset.dy}=${size.height}=${contentSize.height}==${offset.dy + size.height}=$positioned');
      if (positioned == ScrollPositioned.end) {
        _physics = const AlwaysScrollableScrollPhysics();
        double beyond = contentSize.height - size.height - offset.dy;
        if (beyond > 0) return;
        beyond = beyond.abs();
        // log('beyond=== $size');
        if (beyond > 0 && beyond > scrollController.offset) {
          log('beyond=== $beyond');
          scrollController.jumpTo(beyond);
          // scrollController.animateTo(beyond,
          //     duration: const Duration(milliseconds: 100),
          //     curve: Curves.linear);
        }

        if (_physics.runtimeType != physics.runtimeType) {
          physics = _physics;
          setState(() {});
        }
      }
    });
    if (physics == const AlwaysScrollableScrollPhysics()) {
      // web = GestureDetector(
      //     onPanUpdate: (DragUpdateDetails details) {
      //       log(details.localPosition.dy);
      //     },
      //     child: web);
    }

    return web;
  }
}

class _FlWebView extends StatefulWidget {
  const _FlWebView({Key? key, this.onScrollChanged, this.onWebViewCreated})
      : super(key: key);
  final ScrollChangedCallback? onScrollChanged;
  final WebViewCreatedCallback? onWebViewCreated;

  @override
  _FlWebViewState createState() => _FlWebViewState();
}

class _FlWebViewState extends State<_FlWebView> {
  @override
  void initState() {
    super.initState();
    log('_FlWebView===== initState');
  }

  @override
  Widget build(BuildContext context) {
    return FlWebView(
        javascriptMode: JavascriptMode.unrestricted,
        initialUrl: url,
        onWebViewCreated: widget.onWebViewCreated,
        onScrollChanged: widget.onScrollChanged);
  }

  @override
  void dispose() {
    super.dispose();
    log('_FlWebView===== dispose');
  }
}
