import 'package:example/extended_web_view.dart';
import 'package:example/html_webview.dart';
import 'package:example/url_webview.dart';
import 'package:fl_webview/fl_webview.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_waya/flutter_waya.dart';
import 'package:flutter_curiosity/flutter_curiosity.dart';

const String url =
    'https://blog.csdn.net/ozhuimeng123/article/details/98120505';
// const String url = 'https://www.baidu.com/';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Curiosity().desktop.focusDesktop().then((value) {
    Curiosity().desktop.setDesktopSizeTo6P1();
  });
  runApp(const ExtendedWidgetsApp(home: App(), title: 'FlWebview'));
}

class App extends StatefulWidget {
  const App({Key? key}) : super(key: key);

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  void initState() {
    super.initState();
    addPostFrameCallback((_) {});
  }

  @override
  Widget build(BuildContext context) {
    return ExtendedScaffold(
        appBar: AppBar(title: const Text('FlWebView Example')),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
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
            progressBar: FlProgressBar(color: Colors.red),
            delegate: FlWebViewDelegate(onPageStarted:
                (FlWebViewController controller, String url) {
              log('onPageStarted : $url');
              delegate?.onPageStarted?.call(controller, url);
            }, onPageFinished: (FlWebViewController controller, String url) {
              log('onPageFinished : $url');
              delegate?.onPageFinished?.call(controller, url);
            }, onProgress: (FlWebViewController controller, int progress) {
              log('onProgress ：$progress');
              delegate?.onProgress?.call(controller, progress);
            }, onSizeChanged:
                (FlWebViewController controller, WebViewSize webViewSize) {
              log('onSizeChanged : ${webViewSize.frameSize} --- ${webViewSize.contentSize}');
              delegate?.onSizeChanged?.call(controller, webViewSize);
            }, onScrollChanged: (FlWebViewController controller,
                WebViewSize webViewSize,
                Offset offset,
                ScrollPositioned positioned) {
              log('onScrollChanged : ${webViewSize.frameSize} --- ${webViewSize.contentSize} --- $offset --- $positioned');
              delegate?.onScrollChanged
                  ?.call(controller, webViewSize, offset, positioned);
            }, onNavigationRequest:
                (FlWebViewController controller, NavigationRequest request) {
              log('onNavigationRequest : url=${request.url} --- isForMainFrame=${request.isForMainFrame}');
              return delegate?.onNavigationRequest?.call(controller, request) ??
                  true;
            }, onUrlChanged: (FlWebViewController controller, String url) {
              log('onUrlChanged : $url');
              delegate?.onUrlChanged?.call(controller, url);
            }),
            onWebViewCreated: (FlWebViewController controller) async {
              String userAgentString = 'userAgentString';
              final value = await controller.getNavigatorUserAgent();
              log('navigator.userAgent :  $value');
              userAgentString = '$value = $userAgentString';
              final userAgent = await controller.setUserAgent(userAgentString);
              log('set userAgent:  $userAgent');
              onWebViewCreated?.call(controller);
              10.seconds.delayed(() {
                controller.getWebViewSize();
              });
            });
}

class ElevatedText extends StatelessWidget {
  const ElevatedText({Key? key, required this.text, required this.onPressed})
      : super(key: key);

  final String text;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final button = ElevatedButton(onPressed: onPressed, child: Text(text));
    if (!isMacOS) return button;
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6), child: button);
  }
}
