import 'dart:async';

import 'package:fl_webview/fl_webview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

class FlWebView extends StatefulWidget {
  const FlWebView({
    Key? key,
    this.onWebViewCreated,
    this.webSettings = const WebSettings(),
    this.gestureRecognizers,
    this.deleteWindowSharedWorkerForIOS = false,
  }) : super(key: key);

  final WebViewCreatedCallback? onWebViewCreated;
  final WebSettings webSettings;
  final Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers;

  /// 解决ios16以上部分webview无法加载
  final bool deleteWindowSharedWorkerForIOS;

  @override
  State<StatefulWidget> createState() => _WebViewState();
}

class _WebViewState extends State<FlWebView> {
  FlWebViewController? flWebViewController;

  @override
  Widget build(BuildContext context) {
    return WebViewPlatform(
        deleteWindowSharedWorkerForIOS: widget.deleteWindowSharedWorkerForIOS,
        onWebViewPlatformCreated: (_) {
          flWebViewController = _;
          widget.onWebViewCreated?.call(_);
        },
        gestureRecognizers: widget.gestureRecognizers);
  }
}
