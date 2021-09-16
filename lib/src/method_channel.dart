import 'dart:async';
import 'dart:ui';

import 'package:fl_webview/fl_webview.dart';
import 'package:fl_webview/src/platform_interface.dart';
import 'package:flutter/services.dart';

/// A [FlWebViewMethodChannel] that uses a method channel to control the webview.
class FlWebViewMethodChannel {
  /// Constructs an instance that will listen for webviews broadcasting to the
  /// given [id], using the given [WebViewCallbacksHandler].
  FlWebViewMethodChannel(int id, this._callbackHandler)
      : _channel = MethodChannel('fl.webview/$id') {
    _channel.setMethodCallHandler(_onMethodCall);
  }

  final WebViewCallbacksHandler _callbackHandler;

  final MethodChannel _channel;

  Future<bool?> _onMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'javascriptChannelMessage':
        final String channel = call.arguments['channel'] as String;
        final String message = call.arguments['message'] as String;
        _callbackHandler.onJavaScriptChannelMessage(channel, message);
        return true;
      case 'navigationRequest':
        return await _callbackHandler.onNavigationRequest(
            url: call.arguments['url']! as String,
            isForMainFrame: call.arguments['isForMainFrame']! as bool);
      case 'onPageFinished':
        _callbackHandler.onPageFinished(call.arguments['url']! as String);
        return null;
      case 'onProgress':
        _callbackHandler.onProgress(call.arguments['progress'] as int);
        return null;
      case 'onPageStarted':
        _callbackHandler.onPageStarted(call.arguments['url']! as String);
        return null;
      case 'onContentSize':
        final double width = call.arguments['width'] as double;
        final double height = call.arguments['height'] as double;
        _callbackHandler.onSizeChanged(Size(width, height));
        return null;
      case 'onContentOffset':
        final double x = call.arguments['x'] as double;
        final double y = call.arguments['y'] as double;
        _callbackHandler.onOffsetChanged(Offset(x, y));
        return null;
      case 'onWebResourceError':
        _callbackHandler.onWebResourceError(WebResourceError(
            errorCode: call.arguments['errorCode']! as int,
            description: call.arguments['description']! as String,
            // iOS doesn't support `failingUrl`.
            failingUrl: call.arguments['failingUrl'] as String,
            domain: call.arguments['domain'] as String,
            errorType: call.arguments['errorType'] == null
                ? null
                : WebResourceErrorType.values.firstWhere((WebResourceErrorType
                        type) =>
                    type.toString() ==
                    '$WebResourceErrorType.${call.arguments['errorType']}')));
        return null;
    }

    throw MissingPluginException(
        '${call.method} was invoked but has no handler');
  }

  Future<void> loadUrl(String url, Map<String, String>? headers) =>
      _channel.invokeMethod<void>(
          'loadUrl', <String, dynamic>{'url': url, 'headers': headers});

  Future<String?> currentUrl() => _channel.invokeMethod<String>('currentUrl');

  Future<bool?> canGoBack() =>
      _channel.invokeMethod<bool>('canGoBack').then((bool? result) => result);

  Future<bool?> canGoForward() => _channel
      .invokeMethod<bool>('canGoForward')
      .then((bool? result) => result);

  Future<void> goBack() => _channel.invokeMethod<void>('goBack');

  Future<void> goForward() => _channel.invokeMethod<void>('goForward');

  Future<void> reload() => _channel.invokeMethod<void>('reload');

  Future<void> clearCache() => _channel.invokeMethod<void>('clearCache');

  Future<void> updateSettings(WebSettings settings) async {
    final Map<String, dynamic> updatesMap = settings.toMap();
    if (updatesMap.isNotEmpty) {
      return await _channel.invokeMethod<void>('updateSettings', updatesMap);
    }
  }

  Future<String> evaluateJavascript(String javascriptString) {
    return _channel
        .invokeMethod<String>('evaluateJavascript', javascriptString)
        .then((String? result) => result!);
  }

  Future<void> addJavascriptChannels(Set<String> javascriptChannelNames) {
    return _channel.invokeMethod<void>(
        'addJavascriptChannels', javascriptChannelNames.toList());
  }

  Future<void> removeJavascriptChannels(Set<String> javascriptChannelNames) {
    return _channel.invokeMethod<void>(
        'removeJavascriptChannels', javascriptChannelNames.toList());
  }

  Future<String?> getTitle() => _channel.invokeMethod<String>('getTitle');

  Future<void> scrollTo(int x, int y) =>
      _channel.invokeMethod<void>('scrollTo', <String, int>{'x': x, 'y': y});

  Future<void> scrollBy(int x, int y) =>
      _channel.invokeMethod<void>('scrollBy', <String, int>{'x': x, 'y': y});

  Future<int> getScrollX() =>
      _channel.invokeMethod<int>('getScrollX').then((int? result) => result!);

  Future<int> getScrollY() =>
      _channel.invokeMethod<int>('getScrollY').then((int? result) => result!);
}
