import 'package:fl_webview/fl_webview.dart';
import 'package:fl_webview/src/extension.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

abstract class LoadRequest {}

class LoadUrlRequest extends LoadRequest {
  LoadUrlRequest(this.url, {this.headers = const {}});

  final String url;
  final Map<String, String> headers;

  Map<String, dynamic> toMap() => {'url': url, 'headers': headers};
}

class LoadDataRequest extends LoadRequest {
  LoadDataRequest(
    this.data, {
    this.baseURL,
    this.historyUrl,
    this.mimeType = 'text/html',
    this.encoding = 'UTF-8',
  });

  final String data;
  final String? baseURL;
  final String? historyUrl;
  final String mimeType;
  final String encoding;

  Map<String, dynamic> toMap() => {
        'data': data,
        'baseURL': baseURL,
        'historyUrl': historyUrl,
        'mimeType': mimeType,
        'encoding': encoding
      };
}

class FlWebView extends StatefulWidget {
  const FlWebView({
    Key? key,
    required this.load,
    this.onWebViewCreated,
    this.webSettings,
    this.delegate,
    this.gestureRecognizers,
  }) : super(key: key);
  final LoadRequest load;
  final WebViewCreatedCallback? onWebViewCreated;
  final WebSettings? webSettings;
  final FlWebViewDelegate? delegate;
  final Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers;

  @override
  State<StatefulWidget> createState() => _WebViewState();
}

class _WebViewState extends State<FlWebView> {
  FlWebViewController? flWebViewController;
  late WebSettings webSettings;

  @override
  void initState() {
    super.initState();
    webSettings = widget.webSettings ?? WebSettings();
    initSettings();
  }

  void initSettings() {
    webSettings.enableSizeChanged = widget.delegate?.onSizeChanged != null;
    webSettings.enabledNavigationDelegate =
        widget.delegate?.onNavigationRequest != null;
    webSettings.enabledProgressChanged = widget.delegate?.onProgress != null;
    webSettings.enabledScrollChanged = widget.delegate?.onScrollChanged != null;
  }

  @override
  Widget build(BuildContext context) {
    return WebViewPlatform(
        webSettings: webSettings,
        onWebViewPlatformCreated: (_) async {
          flWebViewController = _;
          if (widget.delegate != null) _.delegate = widget.delegate!;
          await load();
          widget.onWebViewCreated?.call(_);
        },
        gestureRecognizers: widget.gestureRecognizers);
  }

  Future<void> load() async {
    if (widget.load is LoadUrlRequest) {
      await flWebViewController?.loadUrl(widget.load as LoadUrlRequest);
    } else if (widget.load is LoadDataRequest) {
      await flWebViewController?.loadData(widget.load as LoadDataRequest);
    }
  }

  @override
  void didUpdateWidget(covariant FlWebView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.delegate != null && widget.delegate != oldWidget.delegate) {
      flWebViewController?.delegate = widget.delegate!;
    }
  }

  @override
  void dispose() {
    flWebViewController?.dispose();
    super.dispose();
  }
}
