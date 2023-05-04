import 'package:fl_webview/fl_webview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_waya/flutter_waya.dart';

const String url = 'https://www.zhihu.com/';

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
          FlWebView(onWebViewCreated: (FlWebViewController controller) {
            controller.setWebSettings(WebSettings());
          })
        ]);
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
