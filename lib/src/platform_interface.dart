import 'package:fl_webview/fl_webview.dart';
import 'package:flutter/widgets.dart';

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

/// A single setting for configuring a WebViewPlatform which may be absent.
class WebSetting<T> {
  /// Constructs an absent setting instance.
  ///
  /// The [isPresent] field for the instance will be false.
  ///
  /// Accessing [value] for an absent instance will throw.
  WebSetting.absent()
      : _value = null,
        isPresent = false;

  /// Constructs a setting of the given `value`.
  ///
  /// The [isPresent] field for the instance will be true.
  WebSetting.of(T value)
      : _value = value,
        isPresent = true;

  final T? _value;

  /// The setting's value.
  ///
  /// Throws if [WebSetting.isPresent] is false.
  T get value {
    if (!isPresent) {
      throw StateError('Cannot access a value of an absent WebSetting');
    }
    assert(isPresent);
    // The intention of this getter is to return T whether it is nullable or
    // not whereas _value is of type T? since _value can be null even when
    // T is not nullable (when isPresent == false).
    //
    // We promote _value to T using `as T` instead of `!` operator to handle
    // the case when _value is legitimately null (and T is a nullable type).
    // `!` operator would always throw if _value is null.
    return _value as T;
  }

  /// True when this web setting instance contains a value.
  ///
  /// When false the [WebSetting.value] getter throws.
  final bool isPresent;

  @override
  bool operator ==(Object other) =>
      other is WebSetting<T> &&
      isPresent == other.isPresent &&
      _value == other._value;

  @override
  int get hashCode => hashValues(_value, isPresent);
}

/// Settings for configuring a WebViewPlatform.
///
/// Initial settings are passed as part of [CreationParams], settings updates are sent with
/// [WebViewPlatform#updateSettings].
///
/// The `userAgent` parameter must not be null.
class WebSettings {
  /// Construct an instance with initial settings. Future setting changes can be
  /// sent with [WebviewPlatform#updateSettings].
  ///
  /// The `userAgent` parameter must not be null.
  WebSettings({
    this.autoMediaPlaybackPolicy = AutoMediaPlaybackPolicy.alwaysAllow,
    this.javascriptMode,
    this.hasNavigationDelegate,
    this.hasProgressTracking,
    this.debuggingEnabled,
    this.gestureNavigationEnabled,
    this.allowsInlineMediaPlayback,
    this.hasContentSizeTracking,
    required this.userAgent,
  });

  /// Which restrictions apply on automatic media playback.
  final AutoMediaPlaybackPolicy autoMediaPlaybackPolicy;

  /// The JavaScript execution mode to be used by the webview.
  JavascriptMode? javascriptMode;

  /// Whether the [WebView] has a [NavigationDelegate] set.
  bool? hasNavigationDelegate;

  /// Whether the [WebView] should track page loading progress.
  /// See also: [WebViewCallbacksHandler.onProgress] to get the progress.
  bool? hasProgressTracking;

  bool? hasContentSizeTracking;

  /// Whether to enable the platform's webview content debugging tools.
  ///
  /// See also: [WebView.debuggingEnabled].
  bool? debuggingEnabled;

  /// Whether to play HTML5 videos inline or use the native full-screen controller on iOS.
  ///
  /// This will have no effect on Android.
  bool? allowsInlineMediaPlayback;

  /// The value used for the HTTP `User-Agent:` request header.
  ///
  /// If [userAgent.value] is null the platform's default user agent should be used.
  ///
  /// An absent value ([userAgent.isPresent] is false) represents no change to this setting from the
  /// last time it was set.
  ///
  /// See also [WebView.userAgent].
  WebSetting<String?> userAgent;

  /// Whether to allow swipe based navigation in iOS.
  ///
  /// See also: [WebView.gestureNavigationEnabled]
  bool? gestureNavigationEnabled;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'jsMode': javascriptMode?.index,
        'debuggingEnabled': debuggingEnabled,
        'gestureNavigationEnabled': gestureNavigationEnabled,
        'allowsInlineMediaPlayback': allowsInlineMediaPlayback,
        'userAgent': userAgent.isPresent ? userAgent.value : null,
        'hasNavigationDelegate': hasNavigationDelegate,
        'hasProgressTracking': hasProgressTracking,
        'hasContentSizeTracking': hasContentSizeTracking,
        'autoMediaPlaybackPolicy': autoMediaPlaybackPolicy.index,
      };

  WebSettings update(WebSettings newSettings) {
    assert(newSettings.javascriptMode != null);
    assert(newSettings.hasNavigationDelegate != null);
    assert(newSettings.debuggingEnabled != null);
    if (javascriptMode != newSettings.javascriptMode) {
      javascriptMode = newSettings.javascriptMode;
    }
    if (hasNavigationDelegate != newSettings.hasNavigationDelegate) {
      hasNavigationDelegate = newSettings.hasNavigationDelegate;
    }
    if (hasProgressTracking != newSettings.hasProgressTracking) {
      hasProgressTracking = newSettings.hasProgressTracking;
    }
    if (debuggingEnabled != newSettings.debuggingEnabled) {
      debuggingEnabled = newSettings.debuggingEnabled;
    }
    if (userAgent != newSettings.userAgent) {
      userAgent = newSettings.userAgent;
    }
    return this;
  }
}

/// Configuration to use when creating a new [WebViewPlatformController].
///
/// The `autoMediaPlaybackPolicy` parameter must not be null.
class CreationParams {
  /// Constructs an instance to use when creating a new
  /// [WebViewPlatformController].
  ///
  /// The `autoMediaPlaybackPolicy` parameter must not be null.
  CreationParams({
    this.initialUrl,
    this.initialData,
    this.webSettings,
    this.javascriptChannelNames = const <String>{},
    this.userAgent,
  });

  /// The initialUrl to load in the webview.
  ///
  /// When null the webview will be created without loading any page.
  final String? initialUrl;

  /// The initialData to load in the webview.
  ///
  /// When null the webview will be created without loading any page.
  final HtmlData? initialData;

  /// The initial [WebSettings] for the new webview.
  ///
  /// This can later be updated with [WebViewPlatformController.updateSettings].
  final WebSettings? webSettings;

  /// The initial set of JavaScript channels that are configured for this webview.
  ///
  /// For each value in this set the platform's webview should make sure that a corresponding
  /// property with a postMessage method is set on `window`. For example for a JavaScript channel
  /// named `Foo` it should be possible for JavaScript code executing in the webview to do
  ///
  /// ```javascript
  /// Foo.postMessage('hello');
  /// ```
  // to PlatformWebView.
  final Set<String> javascriptChannelNames;

  /// The value used for the HTTP User-Agent: request header.
  ///
  /// When null the platform's webview default is used for the User-Agent header.
  final String? userAgent;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'initialUrl': initialUrl,
        'initialData': initialData?.toMap(),
        'settings': webSettings?.toMap(),
        'javascriptChannelNames': javascriptChannelNames.toList(),
        'userAgent': userAgent
      };
}
