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
        children: <Widget>[
          ElevatedText(onPressed: () {}, text: 'open webview'),
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
