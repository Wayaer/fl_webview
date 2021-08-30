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
        children: [
          ElevatedText(
              text: 'Fixed height',
              onPressed: () => push(const _FixedHeightFlWebView())),
          ElevatedText(
              text: 'Adaptive height',
              onPressed: () => push(const _AdaptiveHeightFlWebView()))
        ]);
  }
}

class _AdaptiveHeightFlWebView extends StatefulWidget {
  const _AdaptiveHeightFlWebView({Key? key}) : super(key: key);

  @override
  _AdaptiveHeightFlWebViewState createState() =>
      _AdaptiveHeightFlWebViewState();
}

class _AdaptiveHeightFlWebViewState extends State<_AdaptiveHeightFlWebView> {
  ValueNotifier<double> webViewHeight = ValueNotifier<double>(deviceHeight);

  @override
  Widget build(BuildContext context) {
    return ExtendedScaffold(
        appBar: AppBar(title: const Text('Fixed Height FlWebView')),
        isScroll: true,
        children: [
          Container(
              alignment: Alignment.center,
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: const Text('Header'),
              height: 100),
          Container(width: double.infinity, color: Colors.red, child: webView),
          Container(
              alignment: Alignment.center,
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: const Text('Footer'),
              height: 100),
        ]);
  }

  Widget get webView => ValueListenableBuilder<double>(
      valueListenable: webViewHeight,
      builder: (_, double value, __) => SizedBox(
            width: double.infinity,
            height: value,
            child: _FlWebView(onSizeChanged: (Size size) {
              if (size.height != value) {
                log(size);
                webViewHeight.value = size.height;
              }
            }),
          ));

  @override
  void dispose() {
    super.dispose();
    webViewHeight.dispose();
  }
}

class _FixedHeightFlWebView extends StatelessWidget {
  const _FixedHeightFlWebView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ExtendedScaffold(
        appBar: AppBar(title: const Text('Fixed Height FlWebView')),
        mainAxisAlignment: MainAxisAlignment.center,
        body: const _FlWebView());
  }
}

class _FlWebView extends StatelessWidget {
  const _FlWebView({Key? key, this.onSizeChanged}) : super(key: key);
  final ContentSizeCallback? onSizeChanged;

  @override
  Widget build(BuildContext context) {
    return FlWebView(
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
        onSizeChanged: onSizeChanged ??
            (Size size) {
              log('onSizeChanged');
              log(size);
            },
        initialUrl: 'https://zhuanlan.zhihu.com/p/62821195');
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
