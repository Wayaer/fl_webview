import 'package:fl_webview/fl_webview.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_waya/flutter_waya.dart';

void main() {
  runApp(ExtendedWidgetsApp(home: const App(), title: 'FlWebview'));
}

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ExtendedScaffold(
        appBar: AppBar(title: const Text('FlWebView Example')),
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          ElevatedText(
              text: 'Fixed height',
              onPressed: () => push(const _FixedHeightFlWebView())),
          ElevatedText(
              text: 'Adapt height',
              onPressed: () => push(const _AdaptHeightFlWebView())),
          const SizedBox(height: 10),
          ElevatedText(text: 'Html Text', onPressed: getHtml),
          ElevatedText(
              text: 'Html Text Adapt height', onPressed: () => getHtml(true)),
        ]);
  }

  Future<void> getHtml([bool adaptHight = false]) async {
    final String data = await rootBundle.loadString('lib/res/html.html');
    if (adaptHight) {
      push(_AdaptHtmlTextFlWebView(HtmlData(html: data)));
    } else {
      push(_HtmlTextFlWebView(HtmlData(html: data)));
    }
  }
}

class _AdaptHtmlTextFlWebView extends StatelessWidget {
  const _AdaptHtmlTextFlWebView(this.initialData, {Key? key}) : super(key: key);
  final HtmlData initialData;

  @override
  Widget build(BuildContext context) {
    return ExtendedScaffold(
        appBar: AppBar(title: const Text('Adapt Hight Html Text FlWebView')),
        isScroll: true,
        children: <Widget>[
          Container(
              alignment: Alignment.center,
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: const Text('Header'),
              height: 100),
          SizedBox(
              // height: 500,
              child: _FlWebView(adaptHight: true, initialData: initialData)),
          Container(
              alignment: Alignment.center,
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: const Text('Footer'),
              height: 100),
        ]);
  }
}

class _HtmlTextFlWebView extends StatelessWidget {
  const _HtmlTextFlWebView(this.initialData, {Key? key}) : super(key: key);
  final HtmlData initialData;

  @override
  Widget build(BuildContext context) {
    return ExtendedScaffold(
        appBar: AppBar(title: const Text('Html Text FlWebView')),
        mainAxisAlignment: MainAxisAlignment.center,
        body: _FlWebView(initialData: initialData));
  }
}

const String url = 'https://www.zhihu.com/';

class _AdaptHeightFlWebView extends StatelessWidget {
  const _AdaptHeightFlWebView({Key? key}) : super(key: key);

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
              child: const Text('Header'),
              height: 100),
          const _FlWebView(adaptHight: true, initialUrl: url),
          Container(
              alignment: Alignment.center,
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: const Text('Footer'),
              height: 100),
        ]);
  }
}

class _FixedHeightFlWebView extends StatelessWidget {
  const _FixedHeightFlWebView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ExtendedScaffold(
        appBar: AppBar(title: const Text('Fixed Height FlWebView')),
        mainAxisAlignment: MainAxisAlignment.center,
        body: const _FlWebView(initialUrl: url));
  }
}

class _FlWebView extends StatelessWidget {
  const _FlWebView(
      {Key? key, this.adaptHight = false, this.initialData, this.initialUrl})
      : super(key: key);
  final bool adaptHight;
  final HtmlData? initialData;
  final String? initialUrl;

  @override
  Widget build(BuildContext context) {
    final FlWebView current = FlWebView(
        initialData: initialData,
        javascriptMode: JavascriptMode.unrestricted,
        navigationDelegate: (NavigationRequest navigation) async {
          log('navigationDelegate');
          log(navigation.url);
          return NavigationDecision.navigate;
        },
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
        initialUrl: initialUrl);
    if (adaptHight) return FlAdaptWevView(child: current);
    return current;
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
