import 'package:fl_webview/fl_webview.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

typedef WebViewCreatedCallback = void Function(FlWebViewController controller);

class _WebViewPlatformWithMacOS extends StatefulWidget {
  const _WebViewPlatformWithMacOS(
      {Key? key, required this.onWebViewPlatformCreated})
      : super(key: key);
  final WebViewCreatedCallback onWebViewPlatformCreated;

  @override
  State<_WebViewPlatformWithMacOS> createState() =>
      _WebViewPlatformWithMacOSState();
}

class _WebViewPlatformWithMacOSState extends State<_WebViewPlatformWithMacOS> {
  int? id;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      id = await FlWebViewManager().createMacWebView();
      if (id == null) return;
      widget.onWebViewPlatformCreated(FlWebViewController._(id!));
    });
  }

  @override
  Widget build(BuildContext context) =>
      const Center(child: Text('Please see the new window'));

  @override
  void dispose() {
    if (id != null) {
      FlWebViewManager().disposeMacWebView(id!);
    }
    super.dispose();
  }
}

class WebViewPlatform extends StatelessWidget {
  const WebViewPlatform(
      {super.key,
      this.layoutDirection = TextDirection.ltr,
      required this.onWebViewPlatformCreated,
      this.creationParamsCodec = const StandardMessageCodec(),
      this.gestureRecognizers,
      this.deleteWindowSharedWorkerForIOS = false});

  final WebViewCreatedCallback onWebViewPlatformCreated;
  final Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers;
  final TextDirection layoutDirection;
  final MessageCodec<dynamic> creationParamsCodec;
  final bool deleteWindowSharedWorkerForIOS;

  @override
  Widget build(BuildContext context) {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return androidView;
      case TargetPlatform.fuchsia:
        break;
      case TargetPlatform.iOS:
        return iosView;
      case TargetPlatform.linux:
        break;
      case TargetPlatform.macOS:
        return _WebViewPlatformWithMacOS(
            onWebViewPlatformCreated: onWebViewPlatformCreated);
      case TargetPlatform.windows:
        break;
    }
    return Center(child: Text('Unsupported platforms $defaultTargetPlatform'));
  }

  Widget get androidView => PlatformViewLink(
      viewType: 'fl.webview',
      surfaceFactory: (_, PlatformViewController controller) =>
          AndroidViewSurface(
              controller: controller as AndroidViewController,
              gestureRecognizers: gestureRecognizers ??
                  const <Factory<OneSequenceGestureRecognizer>>{},
              hitTestBehavior: PlatformViewHitTestBehavior.opaque),
      onCreatePlatformView: (PlatformViewCreationParams params) {
        return PlatformViewsService.initSurfaceAndroidView(
            id: params.id,
            viewType: 'fl.webview',
            layoutDirection: layoutDirection,
            creationParamsCodec: creationParamsCodec)
          ..addOnPlatformViewCreatedListener(params.onPlatformViewCreated)
          ..addOnPlatformViewCreatedListener((int id) {
            onWebViewPlatformCreated.call(FlWebViewController._(id));
          })
          ..create();
      });

  Widget get iosView => UiKitView(
      viewType: 'fl.webview',
      creationParams: {
        'deleteWindowSharedWorker': deleteWindowSharedWorkerForIOS
      },
      layoutDirection: layoutDirection,
      onPlatformViewCreated: (int id) {
        onWebViewPlatformCreated.call(FlWebViewController._(id));
      },
      gestureRecognizers: gestureRecognizers,
      creationParamsCodec: creationParamsCodec);
}

class FlWebViewController {
  FlWebViewController._(int id) : _channel = MethodChannel('fl.webview/$id') {
    _channel.setMethodCallHandler(_onMethodCall);
  }

  final MethodChannel _channel;

  FlWebViewCallbackHandler? _callbackHandler;

  set callbackHandler(FlWebViewCallbackHandler delegate) =>
      _callbackHandler = delegate;

  Future<dynamic> _onMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onJavascriptChannelMessage':
        final String channel = call.arguments['channel'] as String;
        final String message = call.arguments['message'] as String;
        _javascriptChannels[channel]?.onMessageReceived(message);
        break;
      case 'onNavigationRequest':
        final value = await _callbackHandler?.onNavigationRequest?.call(
            NavigationRequest(
                url: call.arguments['url']! as String,
                isForMainFrame: call.arguments['isForMainFrame']! as bool));
        if (value != null) return value.index == 1;
        break;
      case 'onPageFinished':
        _callbackHandler?.onPageFinished
            ?.call(call.arguments['url']! as String);
        break;
      case 'onProgress':
        _callbackHandler?.onProgress?.call(call.arguments['progress'] as int);
        break;
      case 'onPageStarted':
        _callbackHandler?.onPageStarted?.call(call.arguments['url']! as String);
        break;
      case 'onSizeChanged':
        final double width = call.arguments['width'] as double;
        final double height = call.arguments['height'] as double;
        final double contentHeight = call.arguments['contentHeight'] as double;
        final double contentWidth = call.arguments['contentWidth'] as double;
        _callbackHandler?.onSizeChanged
            ?.call(Size(width, height), Size(contentWidth, contentHeight));
        break;
      case 'onScrollChanged':
        final double x = call.arguments['x'] as double;
        final double y = call.arguments['y'] as double;
        final double width = call.arguments['width'] as double;
        final double height = call.arguments['height'] as double;
        final double contentWidth = call.arguments['contentWidth'] as double;
        final double contentHeight = call.arguments['contentHeight'] as double;
        final int position = call.arguments['position'] as int;
        _callbackHandler?.onScrollChanged?.call(
            Size(width, height),
            Size(contentWidth, contentHeight),
            Offset(x, y),
            ScrollPositioned.values[position]);
        break;
      case 'onWebResourceError':
        _callbackHandler?.onWebResourceError?.call(WebResourceError(
            errorCode: call.arguments['errorCode']! as int,
            description: call.arguments['description']! as String,
            failingUrl: call.arguments['failingUrl'] as String,
            domain: call.arguments['domain'] as String,
            errorType: call.arguments['errorType'] == null
                ? null
                : WebResourceErrorType.values.firstWhere((WebResourceErrorType
                        type) =>
                    type.toString() ==
                    '$WebResourceErrorType.${call.arguments['errorType']}')));
        break;
      case 'onClosed':
        _callbackHandler?.onClosed?.call(call.arguments['url']! as String);
        break;
    }
  }

  // Future<void> loadUrl(UrlData urlData) =>
  //     _channel.invokeMethod<void>('loadUrl', urlData.toMap());

  Future<String?> currentUrl() => _channel.invokeMethod<String>('currentUrl');

  Future<bool?> canGoBack() => _channel.invokeMethod<bool>('canGoBack');

  Future<bool?> isScroll(bool enabled) =>
      _channel.invokeMethod<bool>('isScroll', enabled);

  Future<bool?> canGoForward() => _channel.invokeMethod<bool>('canGoForward');

  Future<void> goBack() => _channel.invokeMethod<void>('goBack');

  Future<void> goForward() => _channel.invokeMethod<void>('goForward');

  Future<void> reload() => _channel.invokeMethod<void>('reload');

  Future<void> clearCache() => _channel.invokeMethod<void>('clearCache');

  Future<void> setWebSettings(WebSettings settings) =>
      _channel.invokeMethod<void>('setWebSettings', settings.toMap());

  Future<String?> evaluateJavascript(String javascriptString) =>
      _channel.invokeMethod<String?>('evaluateJavascript', javascriptString);

  final Map<String, JavascriptChannel> _javascriptChannels = {};

  Future<void> addJavascriptChannel(JavascriptChannel javascriptChannel) async {
    if (_javascriptChannels.keys.contains(javascriptChannel.name)) {
      removeJavascriptChannel(javascriptChannel.name);
    }
    _javascriptChannels[javascriptChannel.name] = javascriptChannel;
    await _channel.invokeMethod<void>(
        'addJavascriptChannel', javascriptChannel.name);
  }

  Future<void> removeJavascriptChannel(String javascriptChannelName) => _channel
      .invokeMethod<void>('removeJavascriptChannel', javascriptChannelName);

  Future<String?> getTitle() => _channel.invokeMethod<String>('getTitle');

  Future<void> scrollTo(int x, int y) =>
      _channel.invokeMethod<void>('scrollTo', <String, int>{'x': x, 'y': y});

  Future<void> scrollBy(int x, int y) =>
      _channel.invokeMethod<void>('scrollBy', <String, int>{'x': x, 'y': y});

  Future<int?> getScrollX() => _channel.invokeMethod<int>('getScrollX');

  Future<int?> getScrollY() => _channel.invokeMethod<int>('getScrollY');

  void dispose() {
    _channel.setMethodCallHandler(null);
  }
}

bool get _isMacOS => defaultTargetPlatform == TargetPlatform.macOS;

class FlWebViewManager {
  factory FlWebViewManager() => _instance ??= FlWebViewManager._();

  FlWebViewManager._();

  static FlWebViewManager? _instance;

  final MethodChannel _flChannel = const MethodChannel('fl.webview.channel');

  Future<bool?> clearCookies() => _flChannel.invokeMethod<bool>('clearCookies');

  Future<int?> createMacWebView() async {
    if (!_isMacOS) return null;
    final value = await _flChannel.invokeMethod<int>('createWebView');
    return value;
  }

  Future<bool> disposeMacWebView(int id) async {
    if (!_isMacOS) return false;
    final value = await _flChannel.invokeMethod<bool>('disposeWebView', id);
    return value ?? false;
  }
}
