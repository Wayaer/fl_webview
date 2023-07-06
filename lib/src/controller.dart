import 'package:fl_webview/fl_webview.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class FlWebViewController {
  FlWebViewController(int id) : _channel = MethodChannel('fl.webview/$id') {
    _channel.setMethodCallHandler(_onMethodCall);
  }

  final MethodChannel _channel;

  MethodChannel get channel => _channel;

  FlWebViewDelegate? _delegate;

  set delegate(FlWebViewDelegate? delegate) => _delegate = delegate;

  Future<dynamic> _onMethodCall(MethodCall call) async {
    debugPrint('>>> ${call.method}=====${call.arguments}');
    switch (call.method) {
      case 'onJavascriptChannelMessage':
        final String channel = call.arguments['channel'] as String;
        final String message = call.arguments['message'] as String;
        _javascriptChannels[channel]?.onMessageReceived?.call(message);
        break;
      case 'onNavigationRequest':
        final value = await _delegate?.onNavigationRequest?.call(
            this,
            NavigationRequest(
                url: call.arguments['url']! as String,
                isForMainFrame: call.arguments['isForMainFrame']! as bool));
        return value ?? true;
      case 'onPageStarted':
        _delegate?.onPageStarted?.call(this, call.arguments as String?);
        break;
      case 'onPageFinished':
        _delegate?.onPageFinished?.call(this, call.arguments as String?);
        break;
      case 'onProgress':
        _delegate?.onProgress?.call(this, (call.arguments as int?) ?? 0);
        break;
      case 'onSizeChanged':
        _delegate?.onSizeChanged
            ?.call(this, WebViewSize.formMap(call.arguments as Map));
        break;
      case 'onScrollChanged':
        final int position = call.arguments['position'] as int;
        _delegate?.onScrollChanged?.call(
            this,
            WebViewSize.formMap(call.arguments as Map),
            Offset(
                call.arguments['x'] as double, call.arguments['y'] as double),
            ScrollPositioned.values[position]);
        break;
      case 'onUrlChanged':
        _delegate?.onUrlChanged?.call(this, call.arguments as String?);
        break;
      case 'onShowFileChooser':
        return await _delegate?.onShowFileChooser
            ?.call(this, FileChooserParams.fromMap(call.arguments as Map));
      case 'onPermissionRequest':
        final value = await _delegate?.onPermissionRequest?.call(
            this, (call.arguments as List?)?.map((e) => e as String).toList());
        return value ?? false;
      case 'onGeolocationPermissionsShowPrompt':
        final value = await _delegate?.onGeolocationPermissionsShowPrompt
            ?.call(this, call.arguments as String?);
        return value ?? false;
      case 'onPermissionRequestCanceled':
        _delegate?.onPermissionRequestCanceled?.call(
            this, (call.arguments as List?)?.map((e) => e as String).toList());
        break;
      case 'onWebResourceError':
        _delegate?.onWebResourceError
            ?.call(this, WebResourceError.fromMap(call.arguments as Map));
        break;
    }
    return null;
  }

  Future<bool> loadUrl(LoadUrlRequest urlRequest) async =>
      (await _channel.invokeMethod<bool>('loadUrl', urlRequest.toMap())) ??
      false;

  Future<bool> loadData(LoadDataRequest dataRequest) async =>
      (await _channel.invokeMethod<bool>('loadData', dataRequest.toMap())) ??
      false;

  Future<String?> currentUrl() => _channel.invokeMethod<String>('currentUrl');

  Future<String?> getNavigatorUserAgent() =>
      evaluateJavascript('navigator.userAgent');

  Future<String?> getUserAgent() =>
      _channel.invokeMethod<String>('getUserAgent');

  Future<String?> setUserAgent(String userAgent) =>
      _channel.invokeMethod<String>('setUserAgent', userAgent);

  Future<bool?> canGoBack() => _channel.invokeMethod<bool>('canGoBack');

  Future<bool?> enabledScroll(bool enabled) =>
      _channel.invokeMethod<bool>('enabledScroll', enabled);

  Future<bool?> canGoForward() => _channel.invokeMethod<bool>('canGoForward');

  Future<void> goBack() => _channel.invokeMethod<void>('goBack');

  Future<void> goForward() => _channel.invokeMethod<void>('goForward');

  Future<void> reload() => _channel.invokeMethod<void>('reload');

  Future<void> clearCache() => _channel.invokeMethod<void>('clearCache');

  Future<void> applyWebSettings(WebSettings settings) async {
    settings.enableSizeChanged = _delegate?.onSizeChanged != null;
    settings.enabledNavigationDelegate = _delegate?.onNavigationRequest != null;
    settings.enabledProgressChanged = _delegate?.onProgress != null;
    settings.enabledScrollChanged = _delegate?.onScrollChanged != null;
    _channel.invokeMethod<void>('applyWebSettings', settings.toMap());
  }

  Future<String?> evaluateJavascript(String javascriptString) async {
    assert(javascriptString.isNotEmpty);
    return await _channel.invokeMethod<String?>(
        'evaluateJavascript', javascriptString);
  }

  final Map<String, JavascriptChannel> _javascriptChannels = {};

  Future<void> addJavascriptChannel(JavascriptChannel javascriptChannel) async {
    if (_javascriptChannels.keys.contains(javascriptChannel.name)) {
      removeJavascriptChannel(javascriptChannel.name);
    }
    _javascriptChannels[javascriptChannel.name] = javascriptChannel;
    await _channel.invokeMethod<void>(
        'addJavascriptChannel', javascriptChannel.toMap());
  }

  Future<void> removeJavascriptChannel(String javascriptChannelName) async {
    _javascriptChannels.remove(javascriptChannelName);
    await _channel.invokeMethod<void>(
        'removeJavascriptChannel', javascriptChannelName);
  }

  Future<String?> getTitle() => _channel.invokeMethod<String>('getTitle');

  Future<void> scrollTo(int x, int y) =>
      _channel.invokeMethod<void>('scrollTo', {'x': x, 'y': y});

  Future<void> scrollBy(int x, int y) =>
      _channel.invokeMethod<void>('scrollBy', {'x': x, 'y': y});

  Future<Offset?> getScrollXY() async {
    final map = await _channel.invokeMethod<Map>('getScrollXY');
    return map == null
        ? null
        : Offset((map['x'] as double?) ?? 0, (map['y'] as double?) ?? 0);
  }

  Future<WebViewSize?> getWebViewSize() async {
    final map = await _channel.invokeMethod<Map>('getWebViewSize');
    return map == null ? null : WebViewSize.formMap(map);
  }

  Future<bool> createForMac(WebSettings webSettings, Size size) async {
    if (!_isMacOS) return false;
    final map = webSettings.toMap()
      ..addAll({
        'width': size.width,
        'height': size.height,
      });
    return (await _channel.invokeMethod<bool>('create', map)) ?? false;
  }

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
}
