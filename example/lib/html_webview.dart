import 'package:example/main.dart';
import 'package:fl_extended/fl_extended.dart';
import 'package:fl_webview/fl_webview.dart';
import 'package:flutter/material.dart';

class AdaptHtmlTextFlWebView extends StatelessWidget {
  const AdaptHtmlTextFlWebView(this.loadData, {super.key});

  final String loadData;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('Adapt Height Html Text FlWebView')),
        body: Universal(isScroll: true, children: <Widget>[
          Container(
              alignment: Alignment.center,
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.symmetric(vertical: 20),
              height: 100,
              child: const Text('Header')),
          FlAdaptHeightWevView(
              maxHeight: 1000,
              builder: (onSizeChanged, onScrollChanged, onWebViewCreated) =>
                  BaseFlWebView(
                      load: LoadDataRequest(loadData),
                      onWebViewCreated: onWebViewCreated,
                      delegate: FlWebViewDelegate(
                          onSizeChanged: onSizeChanged,
                          onScrollChanged: onScrollChanged))),
          Container(
              alignment: Alignment.center,
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.symmetric(vertical: 20),
              height: 100,
              child: const Text('Footer')),
        ]));
  }
}

class HtmlTextFlWebView extends StatelessWidget {
  const HtmlTextFlWebView(this.loadData,
      {super.key, this.title = 'Html FlWebView'});

  final String loadData;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: BaseFlWebView(load: LoadDataRequest(loadData)));
  }
}
