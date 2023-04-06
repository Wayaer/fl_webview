import 'package:fl_webview/fl_webview.dart';

enum JavascriptMode {
  /// JavaScript execution is disabled.
  disabled,

  /// JavaScript execution is not restricted.
  unrestricted,
}

/// Specifies possible restrictions on automatic media playback.
///
/// This is typically used in [WebView.initialMediaPlaybackPolicy].
enum AutoMediaPlaybackPolicy {
  /// Starting any kind of media playback requires a user action.
  ///
  /// For example: JavaScript code cannot start playing media unless the code was executed
  /// as a result of a user action (like a touch event).
  requireUserActionForAllMediaTypes,

  /// Starting any kind of media playback is always allowed.
  ///
  /// For example: JavaScript code that's triggered when the page is loaded can start playing
  /// video or audio.
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

extension ExtensionStringToUrlData on String {
  UrlData parseUrlData({Map<String, String>? headers}) =>
      UrlData(this, headers: headers);
}

class UrlData {
  UrlData(this.url, {this.headers}) : assert(url.trim().isNotEmpty);

  /// url
  String url;

  /// header
  Map<String, String>? headers;

  Map<String, dynamic> toMap() => {'url': url, 'headers': headers};
}

class HtmlData {
  HtmlData(this.html,
      {this.baseURL, this.mimeType = 'text/html', this.encoding = 'UTF-8'});

  final String html;

  /// Valid on IOS
  final String? baseURL;

  /// Valid on Android
  final String mimeType;
  final String encoding;

  Map<String, String?> toMap() => {
        'html': html,
        'baseURL': baseURL,
        'mimeType': mimeType,
        'encoding': encoding
      };
}

/// A message that was sent by JavaScript code running in a [WebView].
class JavascriptMessage {
  const JavascriptMessage(this.message);

  /// The contents of the message that was sent by the JavaScript code.
  final String message;
}

final RegExp _validChannelNames = RegExp('^[a-zA-Z_][a-zA-Z0-9_]*\$');

/// A named channel for receiving messaged from JavaScript code running inside a web view.
class JavascriptChannel {
  JavascriptChannel({
    required this.name,
    required this.onMessageReceived,
  }) : assert(_validChannelNames.hasMatch(name));

  final String name;

  final JavascriptMessageHandler onMessageReceived;
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

class WebSetting<T> {
  WebSetting.absent()
      : _value = null,
        isPresent = false;

  WebSetting.of(T value)
      : _value = value,
        isPresent = true;

  final T? _value;

  T get value {
    if (!isPresent) {
      throw StateError('Cannot access a value of an absent WebSetting');
    }
    assert(isPresent);
    return _value as T;
  }

  final bool isPresent;

  @override
  bool operator ==(Object other) =>
      other is WebSetting<T> &&
      isPresent == other.isPresent &&
      _value == other._value;

  @override
  int get hashCode => Object.hash(_value, isPresent);
}

class WebSettings {
  WebSettings({
    this.autoMediaPlaybackPolicy = AutoMediaPlaybackPolicy.alwaysAllow,
    this.javascriptMode,
    this.debuggingEnabled = false,
    this.gestureNavigationEnabled,
    this.allowsInlineMediaPlayback,
    this.hasNavigationDelegate = false,
    this.hasProgressTracking = false,
    this.hasContentSizeTracking = false,
    this.hasScrollChangedTracking = false,
    this.useProgressGetContentSize = true,
    required this.userAgent,
  });

  final AutoMediaPlaybackPolicy autoMediaPlaybackPolicy;

  JavascriptMode? javascriptMode;

  bool hasNavigationDelegate;

  bool hasProgressTracking;

  bool hasContentSizeTracking;

  bool useProgressGetContentSize;

  bool hasScrollChangedTracking;

  bool debuggingEnabled;

  bool? allowsInlineMediaPlayback;

  WebSetting<String?> userAgent;

  bool? gestureNavigationEnabled;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'javascriptMode': javascriptMode?.index,
        'debuggingEnabled': debuggingEnabled,
        'gestureNavigationEnabled': gestureNavigationEnabled,
        'allowsInlineMediaPlayback': allowsInlineMediaPlayback,
        'userAgent': userAgent.isPresent ? userAgent.value : null,
        'hasNavigationDelegate': hasNavigationDelegate,
        'hasProgressTracking': hasProgressTracking,
        'hasContentSizeTracking': hasContentSizeTracking,
        'useProgressGetContentSize': useProgressGetContentSize,
        'hasScrollChangedTracking': hasScrollChangedTracking,
        'autoMediaPlaybackPolicy': autoMediaPlaybackPolicy.index,
      };

  WebSettings update(WebSettings newSettings) {
    assert(newSettings.javascriptMode != null);
    if (javascriptMode != newSettings.javascriptMode) {
      javascriptMode = newSettings.javascriptMode;
    }
    if (hasNavigationDelegate != newSettings.hasNavigationDelegate) {
      hasNavigationDelegate = newSettings.hasNavigationDelegate;
    }
    if (hasProgressTracking != newSettings.hasProgressTracking) {
      hasProgressTracking = newSettings.hasProgressTracking;
    }
    if (hasContentSizeTracking != newSettings.hasContentSizeTracking) {
      hasContentSizeTracking = newSettings.hasContentSizeTracking;
    }
    if (hasScrollChangedTracking != newSettings.hasScrollChangedTracking) {
      hasScrollChangedTracking = newSettings.hasScrollChangedTracking;
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

class WebViewParams {
  WebViewParams({
    this.initialUrl,
    this.initialHtml,
    this.webSettings,
    this.javascriptChannelNames = const <String>{},
    this.userAgent,
    this.deleteWindowSharedWorkerForIOS = false,
  });

  final UrlData? initialUrl;

  final HtmlData? initialHtml;

  final WebSettings? webSettings;

  final Set<String> javascriptChannelNames;

  final String? userAgent;

  bool deleteWindowSharedWorkerForIOS;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'initialUrl': initialUrl?.toMap(),
        'initialHtml': initialHtml?.toMap(),
        'settings': webSettings?.toMap(),
        'javascriptChannelNames': javascriptChannelNames.toList(),
        'userAgent': userAgent,
        'deleteWindowSharedWorkerForIOS': deleteWindowSharedWorkerForIOS
      };
}
