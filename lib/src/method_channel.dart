import 'dart:async';

import 'package:fl_webview/fl_webview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class FlWebViewMethodChannel {
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
        final double contentHeight = call.arguments['contentHeight'] as double;
        final double contentWidth = call.arguments['contentWidth'] as double;
        _callbackHandler.onContentSizeChanged(
            Size(width, height), Size(contentWidth, contentHeight));
        return null;
      case 'onScrollChanged':
        final double x = call.arguments['x'] as double;
        final double y = call.arguments['y'] as double;
        final double width = call.arguments['width'] as double;
        final double height = call.arguments['height'] as double;
        final double contentWidth = call.arguments['contentWidth'] as double;
        final double contentHeight = call.arguments['contentHeight'] as double;
        final int position = call.arguments['position'] as int;
        _callbackHandler.onScrollChanged(Size(width, height),
            Size(contentWidth, contentHeight), Offset(x, y), position);
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

  Future<void> loadUrl(UrlData urlData) =>
      _channel.invokeMethod<void>('loadUrl', urlData.toMap());

  Future<String?> currentUrl() => _channel.invokeMethod<String>('currentUrl');

  Future<bool?> canGoBack() =>
      _channel.invokeMethod<bool>('canGoBack').then((bool? result) => result);

  Future<bool?> scrollEnabled(bool enabled) => _channel
      .invokeMethod<bool>('scrollEnabled', enabled)
      .then((bool? result) => result);

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
      await _channel.invokeMethod<void>('updateSettings', updatesMap);
    }
  }

  Future<String?> evaluateJavascript(String javascriptString) =>
      _channel.invokeMethod<String?>('evaluateJavascript', javascriptString);

  Future<void> addJavascriptChannels(Set<String> javascriptChannelNames) =>
      _channel.invokeMethod<void>(
          'addJavascriptChannels', javascriptChannelNames.toList());

  Future<void> removeJavascriptChannels(Set<String> javascriptChannelNames) =>
      _channel.invokeMethod<void>(
          'removeJavascriptChannels', javascriptChannelNames.toList());

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

const MethodChannel _flChannel = MethodChannel('fl.webview.channel');

/// Manages cookies pertaining to all [WebView]s.
class CookieManager {
  /// Creates a [CookieManager] -- returns the instance if it's already been called.
  factory CookieManager() => _instance ??= CookieManager._();

  CookieManager._();

  static CookieManager? _instance;

  /// Clears all cookies for all [WebView] instances.
  ///
  /// This is a no op on iOS version smaller than 9.
  ///
  /// Returns true if cookies were present before clearing, else false.

  Future<bool> clearCookies() => _flChannel
      .invokeMethod<bool>('clearCookies')
      .then<bool>((bool? result) => result ?? false);
}

enum PresentationStyle {
  modal,
  sheet,
}

typedef MacOSWebViewCallbackUrl = void Function(String url);

class MacOSWebView {
  MacOSWebView({
    this.onOpen,
    this.onClose,
    this.onPageStarted,
    this.onPageFinished,
    this.onWebResourceError,
    required this.url,
    this.javascriptMode = JavascriptMode.disabled,
    this.presentationStyle = PresentationStyle.sheet,
    this.size,
    this.userAgent,
    this.modalTitle = '',
    this.sheetCloseButtonTitle = 'Close',
  }) : assert(defaultTargetPlatform == TargetPlatform.macOS);

  UrlData url;
  final JavascriptMode javascriptMode;
  final PresentationStyle presentationStyle;
  final Size? size;
  final String? userAgent;
  final String modalTitle;
  final String sheetCloseButtonTitle;
  final MacOSWebViewCallbackUrl? onOpen;
  final MacOSWebViewCallbackUrl? onClose;
  final MacOSWebViewCallbackUrl? onPageStarted;
  final MacOSWebViewCallbackUrl? onPageFinished;
  final void Function(WebResourceError error)? onWebResourceError;

  Future<bool?> open({UrlData? url}) async {
    if (url != null) {
      this.url = url;
    }
    _flChannel.setMethodCallHandler(_onMethodCall);
    return await _flChannel.invokeMethod<bool?>('openWebView', {
      'urlData': this.url.toMap(),
      'javascriptMode': javascriptMode.index,
      'presentationStyle': presentationStyle.index,
      'customSize': size != null,
      'width': size?.width,
      'height': size?.height,
      'userAgent': userAgent,
      'modalTitle': modalTitle,
      'sheetCloseButtonTitle': sheetCloseButtonTitle,
    });
  }

  /// Closes WebView
  Future<bool?> close() async {
    _flChannel.setMethodCallHandler(null);
    return await _flChannel.invokeMethod<bool?>('closeWebView');
  }

  Future<void> _onMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onOpen':
        onOpen?.call(url.url);
        return;
      case 'onClose':
        onClose?.call(url.url);
        return;
      case 'onPageStarted':
        onPageStarted?.call(call.arguments['url']);
        return;
      case 'onPageFinished':
        onPageFinished?.call(call.arguments['url']);
        return;
      case 'onWebResourceError':
        onWebResourceError?.call(WebResourceError(
            errorCode: call.arguments['errorCode'],
            description: call.arguments['description'],
            domain: call.arguments['domain'],
            errorType: call.arguments['errorType'] == null
                ? null
                : WebResourceErrorType.values.firstWhere(
                    (type) {
                      return type.toString() ==
                          '$WebResourceErrorType.${call.arguments['errorType']}';
                    },
                  )));
        return;
    }
  }
}
