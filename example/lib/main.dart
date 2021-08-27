import 'package:fl_webview/fl_webview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_waya/flutter_waya.dart';

void main() {
  runApp(ExtendedWidgetsApp(home: App(), title: 'FlWebview'));
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ExtendedScaffold(
        appBar: AppBar(title: const Text('FlCamera Example')),
        mainAxisAlignment: MainAxisAlignment.center,
        body: FlWebView(
            javascriptMode: JavascriptMode.unrestricted,
            // navigationDelegate: (NavigationRequest navigation) async {
            //   log('navigationDelegate');
            //   log(navigation.url);
            //   return NavigationDecision.navigate;
            // },
            onWebViewCreated: (WebViewController controller) async {
              log('onWebViewCreated');
              log(await controller.currentUrl());
            },
            onPageStarted: (String url) {
              log('onPageStarted');
              log(url);
            },
            onPageFinished: (String url) {
              log('onPageFinished');
              log(url);
            },
            onProgress: (int progress) {
              log('onProgress');
              log(progress);
            },
            onSizeChanged: (Size size) {
              log('onSizeChanged');
              log(size);
            },
            initialUrl: 'https://zhuanlan.zhihu.com/p/62821195'));
  }
}

class ElevatedText extends StatelessWidget {
  const ElevatedText({Key? key, required this.text, required this.onPressed})
      : super(key: key);

  final String text;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) =>
      ElevatedButton(onPressed: onPressed, child: Text(text));
}
