import 'package:example/nested_scroll_webview.dart';
import 'package:example/nested_webview.dart';
import 'package:fl_webview/fl_webview.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_waya/flutter_waya.dart';

// const String url = 'https://www.zhihu.com/';
const String url =
    'https://mp.weixin.qq.com/s?__biz=Mzk0ODEwNDgwNg==&mid=100043746&idx=1&sn=5da29970d3c39271f4d285d7d093099f&chksm=436e90eb741919fd6a804f5a7a1ef36d2b53422891640fc55b84d422e8f24d38fbc5bfb77de7#rd';

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
          ElevatedText(
              text: 'Scrollview nested WebView',
              onPressed: () => push(const NestedScrollWebView())),
          ElevatedText(
              text: 'NestedScroll WebView',
              onPressed: () => push(const NestedScrollViewAndWebView())),
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
          FlAdaptHeightWevView(child: _FlWebView(initialData: initialData)),
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
          FlAdaptHeightWevView(child: _FlWebView(initialUrl: url)),
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
        body: _FlWebView(initialUrl: url));
  }
}

class _FlWebView extends FlWebView {
  _FlWebView({Key? key, HtmlData? initialData, String? initialUrl})
      : assert(initialData == null || initialUrl == null),
        super(
            key: key,
            initialData: initialData,
            javascriptMode: JavascriptMode.unrestricted,
            navigationDelegate: (NavigationRequest navigation) async {
              log('navigationDelegate');
              log(navigation.url);
              return NavigationDecision.navigate;
            },
            onWebViewCreated: (WebViewController controller) async {
              5.seconds.delayed(() {
                controller.scrollEnabled(false);
              });
              10.seconds.delayed(() {
                controller.scrollEnabled(true);
              });
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
            onContentSizeChanged: (Size size) {
              log('onContentSizeChanged');
              log(size);
            },
            onScrollChanged: (Size size, Size contentSize, Offset offset,
                ScrollPositioned positioned) {
              log('onScrollChanged');
              log(offset);
            },
            initialUrl: initialUrl);
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
