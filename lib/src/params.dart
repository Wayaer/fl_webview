import 'dart:async';

import 'package:fl_webview/src/platform_view.dart';
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
  const WebSettings({
    this.autoMediaPlaybackPolicy = AutoMediaPlaybackPolicy.alwaysAllow,
    this.javascriptMode = JavascriptMode.disabled,
    this.enabledDebugging = false,
    this.gestureNavigationEnabled = false,
    this.allowsInlineMediaPlayback = false,
    this.enabledNavigationDelegate = false,
    this.enableContentSizeTracking = false,
    this.enabledProgressTracking = false,
    this.enabledScrollChanged = false,
    this.useProgressGetContentSize = true,
    this.userAgent,
  });

  final AutoMediaPlaybackPolicy autoMediaPlaybackPolicy;

  final JavascriptMode javascriptMode;

  final bool enabledNavigationDelegate;

  final bool enabledProgressTracking;

  /// 是否开启滚动变化回调
  final bool enableContentSizeTracking;

  /// 是否开启滚动变化回调
  final bool enabledScrollChanged;

  final String? userAgent;

  /// Supports only android
  /// 开启debug
  final bool enabledDebugging;

  /// Supports only android
  /// 在android中使用onProgress获取ContentSize
  final bool useProgressGetContentSize;

  /// Supports only ios
  final bool gestureNavigationEnabled;

  /// Supports only ios
  final bool allowsInlineMediaPlayback;

  Map<String, dynamic> toMap() => {
        'autoMediaPlaybackPolicy': autoMediaPlaybackPolicy.index,
        'javascriptMode': javascriptMode.index,
        'enabledNavigationDelegate': enabledNavigationDelegate,
        'enabledProgressTracking': enabledProgressTracking,
        'enableContentSizeTracking': enableContentSizeTracking,
        'enabledScrollChanged': enabledScrollChanged,
        'userAgent': userAgent,
        'enabledDebugging': enabledDebugging,
        'useProgressGetContentSize': useProgressGetContentSize,
        'gestureNavigationEnabled': gestureNavigationEnabled,
        'allowsInlineMediaPlayback': allowsInlineMediaPlayback,
      };
}

enum JavascriptMode {
  /// JavaScript execution is disabled.
  disabled,

  /// JavaScript execution is not restricted.
  unrestricted,
}

enum AutoMediaPlaybackPolicy {
  requireUserActionForAllMediaTypes,
  alwaysAllow,
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

class FlWebViewCallbackHandler {
  FlWebViewCallbackHandler({
    this.onPageStarted,
    this.onPageFinished,
    this.onProgress,
    this.onSizeChanged,
    this.onNavigationRequest,
    this.onScrollChanged,
    this.onWebResourceError,
    this.onClosed,
    this.onUrlChange,
  });

  final void Function(String url)? onPageStarted;

  final void Function(String url)? onPageFinished;

  final void Function(int progress)? onProgress;

  final void Function(Size frameSize, Size contentSize)? onSizeChanged;

  final FutureOr<NavigationDecision> Function(NavigationRequest request)?
      onNavigationRequest;

  final void Function(Size frameSize, Size contentSize, Offset offset,
      ScrollPositioned positioned)? onScrollChanged;

  final void Function(String url)? onClosed;

  final void Function(String url)? onUrlChange;

  final void Function(WebResourceError error)? onWebResourceError;
}
