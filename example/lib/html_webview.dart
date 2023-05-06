import 'package:example/main.dart';
import 'package:fl_webview/fl_webview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_waya/extended/widgets_app.dart';

class AdaptHtmlTextFlWebView extends StatelessWidget {
  const AdaptHtmlTextFlWebView(this.loadData, {Key? key}) : super(key: key);
  final String loadData;

  @override
  Widget build(BuildContext context) {
    return ExtendedScaffold(
        appBar: AppBar(title: const Text('Adapt Height Html Text FlWebView')),
        isScroll: true,
        children: <Widget>[
          Container(
              alignment: Alignment.center,
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.symmetric(vertical: 20),
              height: 100,
              child: const Text('Header')),
          FlAdaptHeightWevView(
              maxHeight: 3000,
              builder: (onPageFinished, onScrollChanged, onWebViewCreated) =>
                  BaseFlWebView(
                      load: LoadDataRequest(loadData),
                      onWebViewCreated: onWebViewCreated,
                      delegate: FlWebViewDelegate(
                          onPageFinished: onPageFinished,
                          // onSizeChanged: onSizeChanged,
                          // onProgress:
                          //     (int progress, Size frameSize, Size contentSize) {
                          //   onSizeChanged(frameSize, contentSize);
                          // },
                          onScrollChanged: onScrollChanged))),
          Container(
              alignment: Alignment.center,
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.symmetric(vertical: 20),
              height: 100,
              child: const Text('Footer')),
        ]);
  }
}

class HtmlTextFlWebView extends StatelessWidget {
  const HtmlTextFlWebView(this.loadData, {Key? key}) : super(key: key);
  final String loadData;

  @override
  Widget build(BuildContext context) {
    return ExtendedScaffold(
        appBar: AppBar(title: const Text('Html Text FlWebView')),
        mainAxisAlignment: MainAxisAlignment.center,
        body: BaseFlWebView(load: LoadDataRequest(loadData)));
  }
}
