import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FlWebViewWithMacOS extends StatefulWidget {
  const FlWebViewWithMacOS({Key? key}) : super(key: key);

  @override
  _FlWebViewWithMacOSState createState() => _FlWebViewWithMacOSState();
}

const MethodChannel _channel = MethodChannel('fl.webview');

class _FlWebViewWithMacOSState extends State<FlWebViewWithMacOS> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      // _channel.
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
