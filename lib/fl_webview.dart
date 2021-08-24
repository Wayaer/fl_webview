import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const MethodChannel _channel = MethodChannel('fl.webview');

class FlWebView extends StatefulWidget {
  const FlWebView({Key? key, required this.controller}) : super(key: key);
  final FlWebViewController controller;

  @override
  _FlWebViewState createState() => _FlWebViewState();
}

class _FlWebViewState extends State<FlWebView> {
  late FlWebViewController controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      initial();
    });
  }

  Future<void> initial() async {
    controller = widget.controller;
    final bool state = await controller.initial();
    if (state) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    Widget current = const SizedBox();
    if (controller.textureId != null)
      current = Texture(textureId: controller.textureId!);
    return SizedBox.expand(child: current);
  }
}

class FlWebViewController extends ChangeNotifier {
  int? textureId;

  Future<bool> initial() async {
    final bool? state = await _channel.invokeMethod<bool>('initial');
    return state ?? false;
  }
}
