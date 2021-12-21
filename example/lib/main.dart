import 'package:example/extended_web_view.dart';
import 'package:fl_webview/fl_webview.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_waya/flutter_waya.dart';

const String url = 'https://www.zhihu.com/';

void main() {
  runApp(const ExtendedWidgetsApp(home: App(), title: 'FlWebview'));
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
              text: 'WebView With ScrollView',
              onPressed: () =>
                  push(const ExtendedFlWebViewWithScrollViewPage())),
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
          FlAdaptHeightWevView(
              builder: (onContentSizeChanged, onScrollChanged, onWebViewCreated,
                      bool useProgressGetContentSize) =>
                  _FlWebView(
                      initialData: initialData,
                      useProgressGetContentSize: useProgressGetContentSize,
                      onWebViewCreated: onWebViewCreated,
                      onContentSizeChanged: onContentSizeChanged,
                      onScrollChanged: onScrollChanged)),
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
          FlAdaptHeightWevView(
              builder: (onContentSizeChanged, onScrollChanged, onWebViewCreated,
                      bool useProgressGetContentSize) =>
                  _FlWebView(
                      initialUrl: url,
                      useProgressGetContentSize: useProgressGetContentSize,
                      onWebViewCreated: onWebViewCreated,
                      onContentSizeChanged: onContentSizeChanged,
                      onScrollChanged: onScrollChanged)),
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
  _FlWebView(
      {Key? key,
      HtmlData? initialData,
      String? initialUrl,
      bool useProgressGetContentSize = false,
      WebViewCreatedCallback? onWebViewCreated,
      ContentSizeCallback? onContentSizeChanged,
      ScrollChangedCallback? onScrollChanged})
      : assert(initialData == null || initialUrl == null),
        super(
            key: key,
            initialData: initialData,
            javascriptMode: JavascriptMode.unrestricted,
            navigationDelegate: (NavigationRequest navigation) async {
              log('navigationDelegate = ${navigation.url}');
              return NavigationDecision.navigate;
            },
            onWebViewCreated: onWebViewCreated ??
                (WebViewController controller) async {
                  5.seconds.delayed(() {
                    controller.scrollEnabled(false);
                  });
                  10.seconds.delayed(() {
                    controller.scrollEnabled(true);
                  });
                  log('onWebViewCreated = ${await controller.currentUrl()}');
                },
            onPageStarted: (String url) {
              log('onPageStarted = $url');
            },
            onPageFinished: (String url) {
              log('onPageFinished = $url ');
            },
            onProgress: (int progress) {
              log('onProgress = $progress');
            },
            useProgressGetContentSize: useProgressGetContentSize,
            onContentSizeChanged: (Size frameSize, Size contentSize) {
              if (onContentSizeChanged != null) {
                onContentSizeChanged(frameSize, contentSize);
              }
              log('onContentSizeChanged  frameSize= $frameSize, contentSize= $contentSize');
            },
            onScrollChanged: (Size frameSize, Size contentSize, Offset offset,
                ScrollPositioned positioned) {
              if (onScrollChanged != null) {
                onScrollChanged(frameSize, contentSize, offset, positioned);
              }
              log('onScrollChanged :  frameSize = $frameSize  contentSize = $contentSize offset = $offset positioned = $offset');
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
