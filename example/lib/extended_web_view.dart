import 'dart:core';

import 'package:example/main.dart';
import 'package:fl_webview/fl_webview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_waya/flutter_waya.dart';

class ExtendedFlWebViewWithScrollViewPage extends StatelessWidget {
  const ExtendedFlWebViewWithScrollViewPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double webHeight = deviceHeight - getStatusBarHeight - kToolbarHeight;
    return ExtendedScaffold(
        appBar:
            AppBar(title: const Text('ExtendedFlWebViewWithScrollViewPage')),
        body: ExtendedFlWebViewWithScrollView(
            contentHeight: webHeight,
            scrollViewBuilder:
                (ScrollController controller, bool canScroll, Widget webView) {
              return CustomScrollView(
                  controller: controller,
                  physics: canScroll
                      ? const BouncingScrollPhysics()
                      : const NeverScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(child: webView),
                    SliverListGrid.builder(
                        itemBuilder: (_, int index) => Container(
                            height: 100,
                            width: double.infinity,
                            color: index.isEven
                                ? Colors.lightBlue
                                : Colors.amberAccent),
                        itemCount: 30)
                  ]);
            },
            webViewBuilder: (FlWebViewDelegateWithSizeCallback onSizeChanged,
                FlWebViewDelegateWithScrollChangedCallback onScrollChanged,
                WebViewCreatedCallback onWebViewCreated) {
              return BaseFlWebView(
                  load: LoadUrlRequest(url),
                  delegate: FlWebViewDelegate(
                      onSizeChanged: onSizeChanged,
                      onScrollChanged: onScrollChanged),
                  onWebViewCreated: onWebViewCreated,
                  webSettings:
                      WebSettings(javascriptMode: JavascriptMode.unrestricted));
            }));
  }
}
