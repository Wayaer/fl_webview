import 'package:example/main.dart';
import 'package:fl_webview/fl_webview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_waya/flutter_waya.dart';

class AdaptHeightFlWebView extends StatelessWidget {
  const AdaptHeightFlWebView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ExtendedScaffold(
        appBar: AppBar(title: const Text('Adapt Height FlWebView')),
        isScroll: true,
        children: <Widget>[
          Container(
              alignment: Alignment.center,
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.symmetric(vertical: 20),
              height: 100,
              child: const Text('Header')),
          FlAdaptHeightWevView(
              maxHeight: 2000,
              builder: (onPageFinished, onScrollChanged, onWebViewCreated) =>
                  BaseFlWebView(
                      load: LoadUrlRequest(url),
                      onWebViewCreated: onWebViewCreated,
                      delegate: FlWebViewDelegate(
                          onPageFinished: onPageFinished,
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

class FixedHeightFlWebView extends StatelessWidget {
  const FixedHeightFlWebView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ExtendedScaffold(
        appBar: AppBar(title: const Text('FlWebView')),
        mainAxisAlignment: MainAxisAlignment.center,
        body: BaseFlWebView(load: LoadUrlRequest(url)));
  }
}
