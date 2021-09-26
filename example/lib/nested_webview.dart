import 'dart:core';

import 'package:example/main.dart';
import 'package:fl_webview/fl_webview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_waya/flutter_waya.dart';

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
        appBar: AppBar(title: const Text('NestedScrollWebView Example')),
        body: NestedWebView(
          controller: ScrollWebViewController(
              headerHeight: 0, webViewHeight: webHeight),
          builder: (ScrollWebViewController controller, bool canScroll,
              Widget webView) {
            log('==builder ScrollView 是否可以滚动==$canScroll==');
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
                  //     itemCount: 8),
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
          },
          child: const FlWebView(
              javascriptMode: JavascriptMode.unrestricted, initialUrl: url),
        ));
  }
}
