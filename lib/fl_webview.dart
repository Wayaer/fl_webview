import 'dart:async';

import 'package:fl_webview/src/method_channel.dart';
import 'package:fl_webview/src/web_view.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'platform_interface.dart';

typedef WebViewCreatedCallback = void Function(WebViewController controller);

enum JavascriptMode {
  /// JavaScript execution is disabled.
  disabled,

  /// JavaScript execution is not restricted.
  unrestricted,
}

/// A message that was sent by JavaScript code running in a [WebView].
class JavascriptMessage {
  const JavascriptMessage(this.message);

  /// The contents of the message that was sent by the JavaScript code.
  final String message;
}

/// Callback type for handling messages sent from Javascript running in a web view.
typedef JavascriptMessageHandler = void Function(JavascriptMessage message);

/// Information about a navigation action that is about to be executed.
class NavigationRequest {
  NavigationRequest._({required this.url, required this.isForMainFrame});

  /// The URL that will be loaded if the navigation is executed.
  final String url;

  /// Whether the navigation request is to be loaded as the main frame.
  final bool isForMainFrame;

  @override
  String toString() {
    return '$runtimeType(url: $url, isForMainFrame: $isForMainFrame)';
  }
}

/// A decision on how to handle a navigation request.
enum NavigationDecision {
  /// Prevent the navigation from taking place.
  prevent,

  /// Allow the navigation to take place.
  navigate,
}

typedef NavigationDelegate = FutureOr<NavigationDecision> Function(
    NavigationRequest navigation);

/// Signature for when a [WebView] has started loading a page.
typedef PageStartedCallback = void Function(String url);

/// Signature for when a [WebView] has finished loading a page.
typedef PageFinishedCallback = void Function(String url);

/// Signature for when a [WebView] is loading a page.
typedef PageLoadingCallback = void Function(int progress);

typedef ContentSizeCallback = void Function(Size size);

/// Signature for when a [WebView] has failed to load a resource.
typedef WebResourceErrorCallback = void Function(WebResourceError error);

/// Specifies possible restrictions on automatic media playback.
///
/// This is typically used in [WebView.initialMediaPlaybackPolicy].
// The method channel implementation is marshalling this enum to the value's index, so the order
// is important.
enum AutoMediaPlaybackPolicy {
  /// Starting any kind of media playback requires a user action.
  ///
  /// For example: JavaScript code cannot start playing media unless the code was executed
  /// as a result of a user action (like a touch event).
  require_user_action_for_all_media_types,

  /// Starting any kind of media playback is always allowed.
  ///
  /// For example: JavaScript code that's triggered when the page is loaded can start playing
  /// video or audio.
  always_allow,
}

final RegExp _validChannelNames = RegExp('^[a-zA-Z_][a-zA-Z0-9_]*\$');

/// A named channel for receiving messaged from JavaScript code running inside a web view.
class JavascriptChannel {
  /// Constructs a Javascript channel.
  ///
  /// The parameters `name` and `onMessageReceived` must not be null.
  JavascriptChannel({
    required this.name,
    required this.onMessageReceived,
  }) : assert(_validChannelNames.hasMatch(name));

  /// The channel's name.
  ///
  /// Passing this channel object as part of a [WebView.javascriptChannels] adds a channel object to
  /// the Javascript window object's property named `name`.
  ///
  /// The name must start with a letter or underscore(_), followed by any combination of those
  /// characters plus digits.
  ///
  /// Note that any JavaScript existing `window` property with this name will be overriden.
  ///
  /// See also [WebView.javascriptChannels] for more details on the channel registration mechanism.
  final String name;

  /// A callback that's invoked when a message is received through the channel.
  final JavascriptMessageHandler onMessageReceived;
}

class FlWebView extends StatefulWidget {
  const FlWebView({
    Key? key,
    this.onWebViewCreated,
    this.initialUrl,
    this.javascriptMode = JavascriptMode.disabled,
    this.javascriptChannels,
    this.navigationDelegate,
    this.gestureRecognizers,
    this.onPageStarted,
    this.onPageFinished,
    this.onProgress,
    this.onWebResourceError,
    this.debuggingEnabled = false,
    this.gestureNavigationEnabled = false,
    this.userAgent,
    this.initialMediaPlaybackPolicy =
        AutoMediaPlaybackPolicy.require_user_action_for_all_media_types,
    this.allowsInlineMediaPlayback = false,
    this.onSizeChanged,
  }) : super(key: key);

  /// If not null invoked once the web view is created.
  final WebViewCreatedCallback? onWebViewCreated;

  /// Which gestures should be consumed by the web view.
  ///
  /// It is possible for other gesture recognizers to be competing with the web view on pointer
  /// events, e.g if the web view is inside a [ListView] the [ListView] will want to handle
  /// vertical drags. The web view will claim gestures that are recognized by any of the
  /// recognizers on this list.
  ///
  /// When this set is empty or null, the web view will only handle pointer events for gestures that
  /// were not claimed by any other gesture recognizer.
  final Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers;

  /// The initial URL to load.
  final String? initialUrl;

  /// Whether Javascript execution is enabled.
  final JavascriptMode javascriptMode;

  /// The set of [JavascriptChannel]s available to JavaScript code running in the web view.
  ///
  /// For each [JavascriptChannel] in the set, a channel object is made available for the
  /// JavaScript code in a window property named [JavascriptChannel.name].
  /// The JavaScript code can then call `postMessage` on that object to send a message that will be
  /// passed to [JavascriptChannel.onMessageReceived].
  ///
  /// For example for the following JavascriptChannel:
  ///
  /// ```dart
  /// JavascriptChannel(name: 'Print', onMessageReceived: (JavascriptMessage message) { print(message.message); });
  /// ```
  ///
  /// JavaScript code can call:
  ///
  /// ```javascript
  /// Print.postMessage('Hello');
  /// ```
  ///
  /// To asynchronously invoke the message handler which will print the message to standard output.
  ///
  /// Adding a new JavaScript channel only takes affect after the next page is loaded.
  ///
  /// Set values must not be null. A [JavascriptChannel.name] cannot be the same for multiple
  /// channels in the list.
  ///
  /// A null value is equivalent to an empty set.
  final Set<JavascriptChannel>? javascriptChannels;

  /// A delegate function that decides how to handle navigation actions.
  ///
  /// When a navigation is initiated by the WebView (e.g when a user clicks a link)
  /// this delegate is called and has to decide how to proceed with the navigation.
  ///
  /// See [NavigationDecision] for possible decisions the delegate can take.
  ///
  /// When null all navigation actions are allowed.
  ///
  /// Caveats on Android:
  ///
  ///   * Navigation actions targeted to the main frame can be intercepted,
  ///     navigation actions targeted to subframes are allowed regardless of the value
  ///     returned by this delegate.
  ///   * Setting a navigationDelegate makes the WebView treat all navigations as if they were
  ///     triggered by a user gesture, this disables some of Chromium's security mechanisms.
  ///     A navigationDelegate should only be set when loading trusted content.
  ///   * On Android WebView versions earlier than 67(most devices running at least Android L+ should have
  ///     a later version):
  ///     * When a navigationDelegate is set pages with frames are not properly handled by the
  ///       webview, and frames will be opened in the main frame.
  ///     * When a navigationDelegate is set HTTP requests do not include the HTTP referer header.
  final NavigationDelegate? navigationDelegate;

  /// Controls whether inline playback of HTML5 videos is allowed on iOS.
  ///
  /// This field is ignored on Android because Android allows it by default.
  ///
  /// By default `allowsInlineMediaPlayback` is false.
  final bool allowsInlineMediaPlayback;

  /// Invoked when a page starts loading.
  final PageStartedCallback? onPageStarted;

  /// Invoked when a page has finished loading.
  ///
  /// This is invoked only for the main frame.
  ///
  /// When [onPageFinished] is invoked on Android, the page being rendered may
  /// not be updated yet.
  ///
  /// When invoked on iOS or Android, any Javascript code that is embedded
  /// directly in the HTML has been loaded and code injected with
  /// [WebViewController.evaluateJavascript] can assume this.
  final PageFinishedCallback? onPageFinished;

  /// Invoked when a page is loading.
  final PageLoadingCallback? onProgress;

  final ContentSizeCallback? onSizeChanged;

  /// Invoked when a web resource has failed to load.
  ///
  /// This callback is only called for the main page.
  final WebResourceErrorCallback? onWebResourceError;

  /// Controls whether WebView debugging is enabled.
  ///
  /// Setting this to true enables [WebView debugging on Android](https://developers.google.com/web/tools/chrome-devtools/remote-debugging/).
  ///
  /// WebView debugging is enabled by default in dev builds on iOS.
  ///
  /// To debug WebViews on iOS:
  /// - Enable developer options (Open Safari, go to Preferences -> Advanced and make sure "Show Develop Menu in Menubar" is on.)
  /// - From the Menu-bar (of Safari) select Develop -> iPhone Simulator -> <your webview page>
  ///
  /// By default `debuggingEnabled` is false.
  final bool debuggingEnabled;

  /// A Boolean value indicating whether horizontal swipe gestures will trigger back-forward list navigations.
  ///
  /// This only works on iOS.
  ///
  /// By default `gestureNavigationEnabled` is false.
  final bool gestureNavigationEnabled;

  /// The value used for the HTTP User-Agent: request header.
  ///
  /// When null the platform's webview default is used for the User-Agent header.
  ///
  /// When the [WebView] is rebuilt with a different `userAgent`, the page reloads and the request uses the new User Agent.
  ///
  /// When [WebViewController.goBack] is called after changing `userAgent` the previous `userAgent` value is used until the page is reloaded.
  ///
  /// This field is ignored on iOS versions prior to 9 as the platform does not support a custom
  /// user agent.
  ///
  /// By default `userAgent` is null.
  final String? userAgent;

  /// Which restrictions apply on automatic media playback.
  ///
  /// This initial value is applied to the platform's webview upon creation. Any following
  /// changes to this parameter are ignored (as long as the state of the [WebView] is preserved).
  ///
  /// The default policy is [AutoMediaPlaybackPolicy.require_user_action_for_all_media_types].
  final AutoMediaPlaybackPolicy initialMediaPlaybackPolicy;

  @override
  State<StatefulWidget> createState() => _WebViewState();
}

class _WebViewState extends State<FlWebView> {
  final Completer<WebViewController> _controller =
      Completer<WebViewController>();

  late WebViewCallbacksHandler _callbackHandler;
  late WebViewPlatform platform;

  @override
  Widget build(BuildContext context) {
    return platform.build(
        context: context,
        onWebViewPlatformCreated: _onWebViewPlatformCreated,
        webViewPlatformCallbacksHandler: _callbackHandler,
        gestureRecognizers: widget.gestureRecognizers,
        creationParams: widget.creationParams);
  }

  @override
  void initState() {
    super.initState();
    _assertJavascriptChannelNamesAreUnique();
    _callbackHandler = WebViewCallbacksHandler(widget);
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        platform = AndroidWebView();
        break;
      case TargetPlatform.iOS:
        platform = CupertinoWebView();
        break;
      default:
        throw UnsupportedError(
            "Trying to use the default webview implementation for $defaultTargetPlatform but there isn't a default one");
    }
  }

  @override
  void didUpdateWidget(FlWebView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _assertJavascriptChannelNamesAreUnique();
    _controller.future.then((WebViewController controller) {
      _callbackHandler._widget = widget;
      controller._updateWidget(widget);
    });
  }

  void _onWebViewPlatformCreated(FlWebViewMethodChannel? webViewPlatform) {
    final WebViewController controller =
        WebViewController._(widget, webViewPlatform!, _callbackHandler);
    _controller.complete(controller);
    if (widget.onWebViewCreated != null) {
      widget.onWebViewCreated!(controller);
    }
  }

  void _assertJavascriptChannelNamesAreUnique() {
    if (widget.javascriptChannels == null ||
        widget.javascriptChannels!.isEmpty) {
      return;
    }
    assert(_extractChannelNames(widget.javascriptChannels).length ==
        widget.javascriptChannels!.length);
  }
}

extension ExtensionFlWebView on FlWebView {
  CreationParams get creationParams => CreationParams(
        initialUrl: initialUrl,
        webSettings: webSettings,
        javascriptChannelNames: _extractChannelNames(javascriptChannels),
        userAgent: userAgent,
      );

  WebSettings get webSettings => WebSettings(
      javascriptMode: javascriptMode,
      hasNavigationDelegate: navigationDelegate != null,
      hasProgressTracking: onProgress != null,
      hasContentSizeTracking: onSizeChanged != null,
      debuggingEnabled: debuggingEnabled,
      autoMediaPlaybackPolicy: initialMediaPlaybackPolicy,
      gestureNavigationEnabled: gestureNavigationEnabled,
      allowsInlineMediaPlayback: allowsInlineMediaPlayback,
      userAgent: WebSetting<String?>.of(userAgent));
}

Set<String> _extractChannelNames(Set<JavascriptChannel>? channels) {
  final Set<String> channelNames = channels == null
      ? <String>{}
      : channels.map((JavascriptChannel channel) => channel.name).toSet();
  return channelNames;
}

class WebViewCallbacksHandler {
  WebViewCallbacksHandler(this._widget) {
    _updateJavascriptChannelsFromSet(_widget.javascriptChannels);
  }

  FlWebView _widget;

  // Maps a channel name to a channel.
  final Map<String, JavascriptChannel> _javascriptChannels =
      <String, JavascriptChannel>{};

  void onJavaScriptChannelMessage(String channel, String message) {
    _javascriptChannels[channel]!.onMessageReceived(JavascriptMessage(message));
  }

  FutureOr<bool> onNavigationRequest({
    required String url,
    required bool isForMainFrame,
  }) async {
    final NavigationRequest request =
        NavigationRequest._(url: url, isForMainFrame: isForMainFrame);
    final bool allowNavigation = _widget.navigationDelegate == null ||
        await _widget.navigationDelegate!(request) ==
            NavigationDecision.navigate;
    return allowNavigation;
  }

  void onPageStarted(String url) {
    if (_widget.onPageStarted != null) {
      _widget.onPageStarted!(url);
    }
  }

  void onPageFinished(String url) {
    if (_widget.onPageFinished != null) {
      _widget.onPageFinished!(url);
    }
  }

  void onProgress(int progress) {
    if (_widget.onProgress != null) {
      _widget.onProgress!(progress);
    }
  }

  void onWebResourceError(WebResourceError error) {
    if (_widget.onWebResourceError != null) {
      _widget.onWebResourceError!(error);
    }
  }

  void _updateJavascriptChannelsFromSet(Set<JavascriptChannel>? channels) {
    _javascriptChannels.clear();
    if (channels == null) {
      return;
    }
    for (final JavascriptChannel channel in channels) {
      _javascriptChannels[channel.name] = channel;
    }
  }

  void onSizeChanged(Size size) {
    if (_widget.onSizeChanged != null) {
      _widget.onSizeChanged!(size);
    }
  }
}

/// Controls a [WebView].
///
/// A [WebViewController] instance can be obtained by setting the [WebView.onWebViewCreated]
/// callback for a [WebView] widget.
class WebViewController {
  WebViewController._(
    this._widget,
    this._methodChannel,
    this._callbackHandler,
  ) {
    _settings = _widget.webSettings;
  }

  final FlWebViewMethodChannel _methodChannel;

  final WebViewCallbacksHandler _callbackHandler;

  late WebSettings _settings;

  FlWebView _widget;

  /// Loads the specified URL.
  ///
  /// If `headers` is not null and the URL is an HTTP URL, the key value paris in `headers` will
  /// be added as key value pairs of HTTP headers for the request.
  ///
  /// `url` must not be null.
  ///
  /// Throws an ArgumentError if `url` is not a valid URL string.
  Future<void> loadUrl(
    String url, {
    Map<String, String>? headers,
  }) async {
    try {
      final Uri uri = Uri.parse(url);
      if (uri.scheme.isEmpty) {
        throw ArgumentError('Missing scheme in URL string: "$url"');
      }
    } on FormatException catch (e) {
      throw ArgumentError(e);
    }
    return _methodChannel.loadUrl(url, headers);
  }

  /// Accessor to the current URL that the WebView is displaying.
  ///
  /// If [WebView.initialUrl] was never specified, returns `null`.
  /// Note that this operation is asynchronous, and it is possible that the
  /// current URL changes again by the time this function returns (in other
  /// words, by the time this future completes, the WebView may be displaying a
  /// different URL).
  Future<String?> currentUrl() {
    return _methodChannel.currentUrl();
  }

  /// Checks whether there's a back history item.
  ///
  /// Note that this operation is asynchronous, and it is possible that the "canGoBack" state has
  /// changed by the time the future completed.
  Future<bool?> canGoBack() {
    return _methodChannel.canGoBack();
  }

  /// Checks whether there's a forward history item.
  ///
  /// Note that this operation is asynchronous, and it is possible that the "canGoForward" state has
  /// changed by the time the future completed.
  Future<bool?> canGoForward() {
    return _methodChannel.canGoForward();
  }

  /// Goes back in the history of this WebView.
  ///
  /// If there is no back history item this is a no-op.
  Future<void> goBack() {
    return _methodChannel.goBack();
  }

  /// Goes forward in the history of this WebView.
  ///
  /// If there is no forward history item this is a no-op.
  Future<void> goForward() {
    return _methodChannel.goForward();
  }

  /// Reloads the current URL.
  Future<void> reload() {
    return _methodChannel.reload();
  }

  /// Clears all caches used by the [WebView].
  ///
  /// The following caches are cleared:
  ///	1. Browser HTTP Cache.
  ///	2. [Cache API](https://developers.google.com/web/fundamentals/instant-and-offline/web-storage/cache-api) caches.
  ///    These are not yet supported in iOS WkWebView. Service workers tend to use this cache.
  ///	3. Application cache.
  ///	4. Local Storage.
  ///
  /// Note: Calling this method also triggers a reload.
  Future<void> clearCache() async {
    await _methodChannel.clearCache();
    return reload();
  }

  Future<void> _updateWidget(FlWebView widget) async {
    _widget = widget;
    _settings.update(widget.webSettings);
    await _methodChannel.updateSettings(_settings);
    await _updateJavascriptChannels(widget.javascriptChannels);
  }

  Future<void> _updateJavascriptChannels(
      Set<JavascriptChannel>? newChannels) async {
    final Set<String> currentChannels =
        _callbackHandler._javascriptChannels.keys.toSet();
    final Set<String> newChannelNames = _extractChannelNames(newChannels);
    final Set<String> channelsToAdd =
        newChannelNames.difference(currentChannels);
    final Set<String> channelsToRemove =
        currentChannels.difference(newChannelNames);
    if (channelsToRemove.isNotEmpty) {
      await _methodChannel.removeJavascriptChannels(channelsToRemove);
    }
    if (channelsToAdd.isNotEmpty) {
      await _methodChannel.addJavascriptChannels(channelsToAdd);
    }
    _callbackHandler._updateJavascriptChannelsFromSet(newChannels);
  }

  /// Evaluates a JavaScript expression in the context of the current page.
  ///
  /// On Android returns the evaluation result as a JSON formatted string.
  ///
  /// On iOS depending on the value type the return value would be one of:
  ///
  ///  - For primitive JavaScript types: the value string formatted (e.g JavaScript 100 returns '100').
  ///  - For JavaScript arrays of supported types: a string formatted NSArray(e.g '(1,2,3), note that the string for NSArray is formatted and might contain newlines and extra spaces.').
  ///  - Other non-primitive types are not supported on iOS and will complete the Future with an error.
  ///
  /// The Future completes with an error if a JavaScript error occurred, or on iOS, if the type of the
  /// evaluated expression is not supported as described above.
  ///
  /// When evaluating Javascript in a [WebView], it is best practice to wait for
  /// the [WebView.onPageFinished] callback. This guarantees all the Javascript
  /// embedded in the main frame HTML has been loaded.
  Future<String> evaluateJavascript(String javascriptString) {
    if (_settings.javascriptMode == JavascriptMode.disabled) {
      return Future<String>.error(FlutterError(
          'JavaScript mode must be enabled/unrestricted when calling evaluateJavascript.'));
    }
    return _methodChannel.evaluateJavascript(javascriptString);
  }

  /// Returns the title of the currently loaded page.
  Future<String?> getTitle() {
    return _methodChannel.getTitle();
  }

  /// Sets the WebView's content scroll position.
  ///
  /// The parameters `x` and `y` specify the scroll position in WebView pixels.
  Future<void> scrollTo(int x, int y) {
    return _methodChannel.scrollTo(x, y);
  }

  /// Move the scrolled position of this view.
  ///
  /// The parameters `x` and `y` specify the amount of WebView pixels to scroll by horizontally and vertically respectively.
  Future<void> scrollBy(int x, int y) {
    return _methodChannel.scrollBy(x, y);
  }

  /// Return the horizontal scroll position, in WebView pixels, of this view.
  ///
  /// Scroll position is measured from left.
  Future<int> getScrollX() {
    return _methodChannel.getScrollX();
  }

  /// Return the vertical scroll position, in WebView pixels, of this view.
  ///
  /// Scroll position is measured from top.
  Future<int> getScrollY() {
    return _methodChannel.getScrollY();
  }

  Future<int> getContentSize() {
    return _methodChannel.getScrollY();
  }
}

/// Manages cookies pertaining to all [WebView]s.
class CookieManager {
  /// Creates a [CookieManager] -- returns the instance if it's already been called.
  factory CookieManager() {
    return _instance ??= CookieManager._();
  }

  CookieManager._();

  static CookieManager? _instance;

  final MethodChannel _cookieManagerChannel =
      const MethodChannel('fl.webview/cookie_manager');

  /// Clears all cookies for all [WebView] instances.
  ///
  /// This is a no op on iOS version smaller than 9.
  ///
  /// Returns true if cookies were present before clearing, else false.

  Future<bool> clearCookies() => _cookieManagerChannel
      .invokeMethod<bool>('clearCookies')
      .then<bool>((bool? result) => result ?? false);
}
