import 'dart:async';

import 'package:fl_webview/fl_webview.dart';
import 'package:flutter/material.dart';

final RegExp _validChannelNames = RegExp('^[a-zA-Z_][a-zA-Z0-9_]*\$');

/// A named channel for receiving messaged from JavaScript code running inside a web view.
class JavascriptChannel {
  JavascriptChannel({required this.name, this.onMessageReceived, this.source})
      : assert(_validChannelNames.hasMatch(name));

  JavascriptChannel.old(
      {required this.name, this.onMessageReceived, String? source})
      : assert(_validChannelNames.hasMatch(name)),
        source = source ?? 'window.$name = webkit.messageHandlers.$name;';

  final String name;

  /// 仅支持 ios  和 macos
  final String? source;

  final ValueChanged<String>? onMessageReceived;

  @override
  bool operator ==(Object other) =>
      other is JavascriptChannel && name == other.name;

  @override
  int get hashCode => name.hashCode;

  Map<String, dynamic> toMap() => {'name': name, 'source': source};
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

  factory WebResourceError.fromMap(Map<dynamic, dynamic> map) =>
      WebResourceError(
          errorCode: map['errorCode']! as int,
          description: map['description']! as String,
          failingUrl: map['failingUrl'] as String,
          domain: map['domain'] as String,
          errorType: map['errorType'] == null
              ? null
              : WebResourceErrorType.values.firstWhere(
                  (WebResourceErrorType type) =>
                      type.name == map['errorType']));
}

class WebSettings {
  WebSettings({
    this.javascriptMode = JavascriptMode.unrestricted,
    this.enabledDebugging = false,
    this.gestureNavigationEnabled = false,
    this.allowsInlineMediaPlayback = true,
    this.allowsAutoMediaPlayback = true,
    this.enabledZoom = true,
    this.deleteWindowSharedWorker = true,
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

enum FileChooserMode { open, openMultiple, openFolder, save }

class FileChooserParams {
  FileChooserParams(
      {this.title,
      this.mode,
      this.acceptTypes,
      this.filenameHint,
      this.isCaptureEnabled});

  factory FileChooserParams.fromMap(Map<dynamic, dynamic> map) {
    final mode = map['mode'] as int?;
    FileChooserMode? fileChooserMode;
    if (mode != null && mode < 4) {
      fileChooserMode = FileChooserMode.values[mode];
    }
    return FileChooserParams(
        title: map['title'] as String?,
        mode: fileChooserMode,
        acceptTypes: (map['acceptTypes'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList(),
        filenameHint: map['filenameHint'] as String?,
        isCaptureEnabled: map['isCaptureEnabled'] as bool?);
  }

  /// Returns the title to use for this file selector.
  final String? title;

  /// Returns file chooser mode.
  final FileChooserMode? mode;

  /// Returns an array of acceptable MIME types
  final List<String>? acceptTypes;

  /// The file name of a default selection if specified, or null.
  final String? filenameHint;

  /// Returns preference for a live media captured value
  final bool? isCaptureEnabled;
}

typedef FlWebViewDelegateWithUrlCallback = void Function(
    FlWebViewController controller, String? url);

typedef FlWebViewDelegateWithProgressCallback = void Function(
    FlWebViewController controller, int progress);

typedef FlWebViewDelegateWithSizeCallback = void Function(
    FlWebViewController controller, WebViewSize webViewSize);

typedef FlWebViewDelegateWithScrollChangedCallback = void Function(
    FlWebViewController controller,
    WebViewSize webViewSize,
    Offset offset,
    ScrollPositioned positioned);

typedef FlWebViewDelegateWithNavigationRequest = FutureOr<bool> Function(
    FlWebViewController controller, NavigationRequest request);

typedef FlWebViewDelegateWithPermissionRequest = FutureOr<bool> Function(
    FlWebViewController controller, List<String>? resources);

typedef FlWebViewDelegateWithPermissionRequestCanceled = void Function(
    FlWebViewController controller, List<String>? resources);

typedef FlWebViewDelegateWithWebResourceError = void Function(
    FlWebViewController controller, WebResourceError error);

typedef FlWebViewDelegateWithShowFileChooser = FutureOr<List<String>?> Function(
    FlWebViewController controller, FileChooserParams params);

class FlWebViewDelegate {
  FlWebViewDelegate({
    this.onPageStarted,
    this.onPageFinished,
    this.onProgress,
    this.onSizeChanged,
    this.onNavigationRequest,
    this.onScrollChanged,
    this.onWebResourceError,
    this.onUrlChanged,
    this.onShowFileChooser,
    this.onPermissionRequest,
    this.onPermissionRequestCanceled,
  });

  final FlWebViewDelegateWithUrlCallback? onPageStarted;

  final FlWebViewDelegateWithUrlCallback? onPageFinished;

  final FlWebViewDelegateWithProgressCallback? onProgress;

  final FlWebViewDelegateWithSizeCallback? onSizeChanged;

  final FlWebViewDelegateWithScrollChangedCallback? onScrollChanged;

  final FlWebViewDelegateWithNavigationRequest? onNavigationRequest;

  final FlWebViewDelegateWithUrlCallback? onUrlChanged;

  final FlWebViewDelegateWithWebResourceError? onWebResourceError;

  /// android onShowFileChooser
  final FlWebViewDelegateWithShowFileChooser? onShowFileChooser;

  /// android onPermissionRequest
  final FlWebViewDelegateWithPermissionRequest? onPermissionRequest;

  /// android onPermissionRequestCanceled
  final FlWebViewDelegateWithPermissionRequestCanceled?
      onPermissionRequestCanceled;

  FlWebViewDelegate copyWith({
    FlWebViewDelegateWithUrlCallback? onPageStarted,
    FlWebViewDelegateWithUrlCallback? onPageFinished,
    FlWebViewDelegateWithProgressCallback? onProgress,
    FlWebViewDelegateWithSizeCallback? onSizeChanged,
    FlWebViewDelegateWithScrollChangedCallback? onScrollChanged,
    FlWebViewDelegateWithNavigationRequest? onNavigationRequest,
    FlWebViewDelegateWithUrlCallback? onUrlChanged,
    FlWebViewDelegateWithWebResourceError? onWebResourceError,
    FlWebViewDelegateWithShowFileChooser? onShowFileChooser,
    FlWebViewDelegateWithPermissionRequest? onPermissionRequest,
    FlWebViewDelegateWithPermissionRequestCanceled? onPermissionRequestCanceled,
  }) =>
      FlWebViewDelegate(
        onPageStarted: onPageStarted ?? this.onPageStarted,
        onPageFinished: onPageFinished ?? this.onPageFinished,
        onProgress: onProgress ?? this.onProgress,
        onSizeChanged: onSizeChanged ?? this.onSizeChanged,
        onNavigationRequest: onNavigationRequest ?? this.onNavigationRequest,
        onScrollChanged: onScrollChanged ?? this.onScrollChanged,
        onWebResourceError: onWebResourceError ?? this.onWebResourceError,
        onUrlChanged: onUrlChanged ?? this.onUrlChanged,
        onShowFileChooser: onShowFileChooser ?? this.onShowFileChooser,
        onPermissionRequest: onPermissionRequest ?? this.onPermissionRequest,
        onPermissionRequestCanceled:
            onPermissionRequestCanceled ?? this.onPermissionRequestCanceled,
      );
}

class FlProgressBar {
  FlProgressBar({this.color = Colors.blueAccent, this.height = 1});

  /// color
  final Color color;

  /// height
  final double height;
}
