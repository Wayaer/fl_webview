import 'package:fl_webview/fl_webview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

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
    this.enableProgressBar = false,
    this.progressBarColor = Colors.blueAccent,
    this.progressBarHeight = 2,
  }) : super(key: key);

  /// 加载的url或者html
  final LoadRequest load;

  /// FlWebViewController 创建回调
  final WebViewCreatedCallback? onWebViewCreated;

  /// webview 设置项
  final WebSettings? webSettings;

  /// webview 加载委托
  final FlWebViewDelegate? delegate;

  final Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers;

  /// 是否开启进度条
  final bool enableProgressBar;

  /// 进度条加载颜色
  final Color progressBarColor;

  /// 进度条高度
  final double progressBarHeight;

  @override
  State<StatefulWidget> createState() => _WebViewState();
}

class _WebViewState extends State<FlWebView> {
  FlWebViewController? flWebViewController;
  late WebSettings webSettings;
  ValueNotifier<int>? currentProgress;

  @override
  void initState() {
    super.initState();
    webSettings = widget.webSettings ?? WebSettings();
    initSettings();
  }

  void initSettings() {
    webSettings.enabledProgressChanged = widget.delegate?.onProgress != null;
    if (widget.enableProgressBar) {
      currentProgress?.dispose();
      currentProgress = ValueNotifier<int>(0);
      webSettings.enabledProgressChanged = true;
    }
    webSettings.enableSizeChanged = widget.delegate?.onSizeChanged != null;
    webSettings.enabledNavigationDelegate =
        widget.delegate?.onNavigationRequest != null;

    webSettings.enabledScrollChanged = widget.delegate?.onScrollChanged != null;
  }

  void initDelegate() {
    flWebViewController?.delegate = widget.delegate;
    if (widget.enableProgressBar) {
      final delegate = (widget.delegate ?? FlWebViewDelegate());
      flWebViewController?.delegate =
          delegate.copyWith(onProgress: (_, int progress) {
        delegate.onProgress?.call(_, progress);
        if (mounted) currentProgress?.value = progress;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final webView = WebViewPlatform(
        webSettings: webSettings,
        onWebViewPlatformCreated: (_) async {
          flWebViewController = _;
          await _.createForMac(webSettings, context.size ?? const Size(0, 0));
          initDelegate();
          await load();
          widget.onWebViewCreated?.call(_);
        },
        gestureRecognizers: widget.gestureRecognizers);
    if (widget.enableProgressBar) {
      return Column(children: [
        buildProgressBar,
        Expanded(child: webView),
      ]);
    }
    return webView;
  }

  Widget get buildProgressBar {
    return ValueListenableBuilder(
        valueListenable: currentProgress!,
        builder: (_, int value, __) {
          if (value < 10 || value == 100) {
            return const SizedBox();
          }
          return Container(
              width: double.infinity,
              height: widget.progressBarHeight,
              alignment: Alignment.centerLeft,
              child: Container(
                  height: double.infinity,
                  color: widget.progressBarColor,
                  width: double.infinity * value / 100));
        });
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
    if (widget.delegate != oldWidget.delegate) {
      initDelegate();
    }
  }

  @override
  void dispose() {
    currentProgress?.dispose();
    currentProgress = null;
    flWebViewController?.dispose();
    super.dispose();
  }
}
