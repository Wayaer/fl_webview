import 'dart:async';

import 'package:flutter/material.dart';

final RegExp _validChannelNames = RegExp('^[a-zA-Z_][a-zA-Z0-9_]*\$');

/// A named channel for receiving messaged from JavaScript code running inside a web view.
class JavascriptChannel {
  JavascriptChannel({
    required this.name,
    required this.onMessageReceived,
  }) : assert(_validChannelNames.hasMatch(name));

  final String name;

  final void Function(String message) onMessageReceived;

  @override
  bool operator ==(Object other) =>
      other is JavascriptChannel && name == other.name;

  @override
  int get hashCode => name.hashCode;
}

class NavigationRequest {
  NavigationRequest({required this.url, required this.isForMainFrame});

  /// The URL that will be loaded if the navigation is executed.
  final String url;

  /// Whether the navigation request is to be loaded as the main frame.
  final bool isForMainFrame;

  @override
  String toString() =>
      '$runtimeType(url: $url, isForMainFrame: $isForMainFrame)';
}

/// A decision on how to handle a navigation request.
enum NavigationDecision {
  /// Prevent the navigation from taking place.
  prevent,

  /// Allow the navigation to take place.
  navigate,
}

/// Possible error type categorizations used by [WebResourceError].
enum WebResourceErrorType {
  /// User authentication failed on server.
  authentication,

  /// Malformed URL.
  badUrl,

  /// Failed to connect to the server.
  connect,

  /// Failed to perform SSL handshake.
  failedSslHandshake,

  /// Generic file error.
  file,

  /// File not found.
  fileNotFound,

  /// Server or proxy hostname lookup failed.
  hostLookup,

  /// Failed to read or write to the server.
  io,

  /// User authentication failed on proxy.
  proxyAuthentication,

  /// Too many redirects.
  redirectLoop,

  /// Connection timed out.
  timeout,

  /// Too many requests during this load.
  tooManyRequests,

  /// Generic error.
  unknown,

  /// Resource load was canceled by Safe Browsing.
  unsafeResource,

  /// Unsupported authentication scheme (not basic or digest).
  unsupportedAuthScheme,

  /// Unsupported URI scheme.
  unsupportedScheme,

  /// The web content process was terminated.
  webContentProcessTerminated,

  /// The web view was invalidated.
  webViewInvalidated,

  /// A JavaScript exception occurred.
  javaScriptExceptionOccurred,

  /// The result of JavaScript execution could not be returned.
  javaScriptResultTypeIsUnsupported,
}

/// Error returned in `WebView.onWebResourceError` when a web resource loading error has occurred.
class WebResourceError {
  /// Creates a new [WebResourceError]
  ///
  /// A user should not need to instantiate this class, but will receive one in
  /// [WebResourceErrorCallback].
  WebResourceError({
    required this.errorCode,
    required this.description,
    this.domain,
    this.errorType,
    this.failingUrl,
  });

  /// Raw code of the error from the respective platform.
  ///
  /// On Android, the error code will be a constant from a
  /// [WebViewClient](https://developer.android.com/reference/android/webkit/WebViewClient#summary) and
  /// will have a corresponding [errorType].
  ///
  /// On iOS, the error code will be a constant from `NSError.code` in
  /// Objective-C. See
  /// https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ErrorHandlingCocoa/ErrorObjectsDomains/ErrorObjectsDomains.html
  /// for more information on error handling on iOS. Some possible error codes
  /// can be found at https://developer.apple.com/documentation/webkit/wkerrorcode?language=objc.
  final int errorCode;

  /// The domain of where to find the error code.
  ///
  /// This field is only available on iOS and represents a "domain" from where
  /// the [errorCode] is from. This value is taken directly from an `NSError`
  /// in Objective-C. See
  /// https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ErrorHandlingCocoa/ErrorObjectsDomains/ErrorObjectsDomains.html
  /// for more information on error handling on iOS.
  final String? domain;

  /// Description of the error that can be used to communicate the problem to the user.
  final String description;

  /// The type this error can be categorized as.
  ///
  /// This will never be `null` on Android, but can be `null` on iOS.
  final WebResourceErrorType? errorType;

  /// Gets the URL for which the resource request was made.
  ///
  /// This value is not provided on iOS. Alternatively, you can keep track of
  /// the last values provided to [WebViewPlatformController.loadUrl].
  final String? failingUrl;
}

class WebSettings {
  WebSettings({
    this.javascriptMode = JavascriptMode.disabled,
    this.enabledDebugging = false,
    this.gestureNavigationEnabled = false,
    this.allowsInlineMediaPlayback = true,
    this.allowsAutoMediaPlayback = true,
    this.enabledZoom = true,
    this.deleteWindowSharedWorker = false,
    this.userAgent,
  });

  /// navigationDelegate
  bool enabledNavigationDelegate = false;

  /// 加载进度变化回调
  bool enabledProgressChanged = false;

  /// 是否开启webview变化回调
  bool enableSizeChanged = false;

  /// 是否开启滚动变化回调
  bool enabledScrollChanged = false;

  ///
  final bool allowsAutoMediaPlayback;

  final JavascriptMode javascriptMode;

  final String? userAgent;

  final bool enabledZoom;

  /// Supports only android
  /// 开启debug
  final bool enabledDebugging;

  /// Supports only ios
  final bool gestureNavigationEnabled;

  /// Supports only ios
  final bool allowsInlineMediaPlayback;

  /// Supports only ios
  /// 解决ios16以上部分webview无法加载
  final bool deleteWindowSharedWorker;

  Map<String, dynamic> toMap() => {
        'enabledNavigationDelegate': enabledNavigationDelegate,
        'enabledProgressChanged': enabledProgressChanged,
        'enableSizeChanged': enableSizeChanged,
        'enabledScrollChanged': enabledScrollChanged,
        'javascriptMode': javascriptMode.index,
        'allowsAutoMediaPlayback': allowsAutoMediaPlayback,
        'userAgent': userAgent,
        'enabledDebugging': enabledDebugging,
        'gestureNavigationEnabled': gestureNavigationEnabled,
        'allowsInlineMediaPlayback': allowsInlineMediaPlayback,
        'deleteWindowSharedWorker': deleteWindowSharedWorker,
        'enabledZoom': enabledZoom,
      };
}

enum JavascriptMode {
  /// JavaScript execution is disabled.
  disabled,

  /// JavaScript execution is not restricted.
  unrestricted,
}

/// Scroll Positioned
enum ScrollPositioned {
  /// At the very top
  start,

  /// On the roll
  scrolling,

  /// At the very bottom
  end,
}

class WebViewSize {
  WebViewSize.formMap(Map<dynamic, dynamic> map)
      : frameSize = Size(
            (map['width'] as double?) ?? 0, (map['height'] as double?) ?? 0),
        contentSize = Size((map['contentWidth'] as double?) ?? 0,
            (map['contentHeight'] as double?) ?? 0);

  final Size frameSize;
  final Size contentSize;
}

typedef FlWebViewDelegateWithUrl = void Function(String url);

typedef FlWebViewDelegateWithUrlAndSize = void Function(
    String url, WebViewSize webViewSize);

typedef FlWebViewDelegateWithProgress = void Function(int progress);

typedef FlWebViewDelegateWithSize = void Function(WebViewSize webViewSize);

typedef FlWebViewDelegateWithScrollChanged = void Function(
    WebViewSize webViewSize, Offset offset, ScrollPositioned positioned);

typedef FlWebViewDelegateWithNavigationRequest = FutureOr<NavigationDecision>
    Function(NavigationRequest request);

class FlWebViewDelegate {
  FlWebViewDelegate({
    this.onPageStarted,
    this.onPageFinished,
    this.onProgress,
    this.onSizeChanged,
    this.onNavigationRequest,
    this.onScrollChanged,
    this.onWebResourceError,
    this.onClosed,
    this.onUrlChanged,
  });

  final FlWebViewDelegateWithUrl? onPageStarted;

  final FlWebViewDelegateWithUrl? onPageFinished;

  final FlWebViewDelegateWithProgress? onProgress;

  final FlWebViewDelegateWithSize? onSizeChanged;

  final FlWebViewDelegateWithScrollChanged? onScrollChanged;

  final FlWebViewDelegateWithNavigationRequest? onNavigationRequest;

  final FlWebViewDelegateWithUrl? onClosed;

  final FlWebViewDelegateWithUrl? onUrlChanged;

  final void Function(WebResourceError error)? onWebResourceError;
}
