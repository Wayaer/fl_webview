import 'package:example/extended_web_view.dart';
import 'package:example/html_webview.dart';
import 'package:example/url_webview.dart';
import 'package:fl_webview/fl_webview.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_waya/flutter_waya.dart';
import 'package:flutter_curiosity/flutter_curiosity.dart';

// const String url = 'https://juejin.cn/post/7154271406132297764';
const String url = 'https://www.baidu.com/';

void main() {
  runApp(const ExtendedWidgetsApp(home: App(), title: 'FlWebview'));
}

class App extends StatefulWidget {
  const App({Key? key}) : super(key: key);

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  Widget build(BuildContext context) {
    return ExtendedScaffold(
        appBar: AppBar(title: const Text('FlWebView Example')),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isMobile) ...[
            ElevatedText(
                text: 'Fixed height with WebView',
                onPressed: () => push(const FixedHeightFlWebView())),
            ElevatedText(
                text: 'Adapt height with WebView',
                onPressed: () => push(const AdaptHeightFlWebView())),
            const SizedBox(height: 10),
            ElevatedText(
                text: 'WebView With ScrollView',
                onPressed: () =>
                    push(const ExtendedFlWebViewWithScrollViewPage())),
            const SizedBox(height: 10),
            ElevatedText(text: 'Html Text with WebView', onPressed: getHtml),
            ElevatedText(
                text: 'Html Text Adapt height with WebView',
                onPressed: () => getHtml(true)),
          ],
        ]);
  }

  Future<void> getHtml([bool adaptHeight = false]) async {
    final String data = await rootBundle.loadString('assets/html.html');
    if (adaptHeight) {
      push(AdaptHtmlTextFlWebView(data));
    } else {
      push(HtmlTextFlWebView(data));
    }
  }
}

class BaseFlWebView extends FlWebView {
  BaseFlWebView({
    super.key,
    required super.load,
    super.webSettings,
    FlWebViewDelegate? delegate,
    WebViewCreatedCallback? onWebViewCreated,
  }) : super(
            delegate: FlWebViewDelegate(
              onPageStarted: (String url) {
                log('onPageStarted : $url');
                delegate?.onPageStarted?.call(url);
              },
              onPageFinished: (String url) {
                log('onPageFinished : $url');
                delegate?.onPageFinished?.call(url);
              },
              onProgress: (int progress) {
                log('onProgress ：$progress');
                delegate?.onProgress?.call(progress);
              },
              onSizeChanged: (WebViewSize webViewSize) {
                log('onSizeChanged : ${webViewSize.frameSize} --- ${webViewSize.contentSize}');
                delegate?.onSizeChanged?.call(webViewSize);
              },
              //  onScrollChanged: (WebViewSize webViewSize, Offset offset,
              //         ScrollPositioned positioned) {
              //   log('onScrollChanged : ${webViewSize.frameSize} --- ${webViewSize.contentSize} --- $offset --- $positioned');
              //   delegate?.onScrollChanged?.call(webViewSize, offset, positioned);
              // },
              onNavigationRequest: (NavigationRequest request) {
                log('onNavigationRequest : ${request.url} --- ${request.isForMainFrame}');
                return delegate?.onNavigationRequest?.call(request) ?? true;
              },
              onUrlChanged: (String url) {
                log('onUrlChanged : $url');
                delegate?.onUrlChanged?.call(url);
              },
              onClosed: (String url) {
                log('onClosed : $url');
                delegate?.onClosed?.call(url);
              },
            ),
            onWebViewCreated: (FlWebViewController controller) async {
              final userAgent = await controller.getUserAgent();
              log('userAgent:  $userAgent');
              onWebViewCreated?.call(controller);
            });
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
