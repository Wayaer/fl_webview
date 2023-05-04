import 'dart:async';

import 'package:fl_webview/fl_webview.dart';
import 'package:fl_webview/src/extension.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

typedef WebViewCreatedCallback = void Function(WebViewController controller);

/// Callback type for handling messages sent from Javascript running in a web view.
typedef JavascriptMessageHandler = void Function(JavascriptMessage message);

typedef NavigationDelegate = FutureOr<NavigationDecision> Function(
    NavigationRequest navigation);

/// Signature for when a [WebView] has started loading a page.
typedef PageStartedCallback = void Function(String url);

/// Signature for when a [WebView] has finished loading a page.
typedef PageFinishedCallback = void Function(String url);

/// Signature for when a [WebView] is loading a page.
typedef PageLoadingCallback = void Function(int progress);

/// Width and height of web content
typedef ContentSizeCallback = void Function(Size frameSize, Size contentSize);

/// Component size, WebView and wkwebview , scroll offset
typedef ScrollChangedCallback = void Function(Size frameSize, Size contentSize,
    Offset offset, ScrollPositioned positioned);

/// Signature for when a [WebView] has failed to load a resource.
typedef WebResourceErrorCallback = void Function(WebResourceError error);

typedef WebViewPlatformCreatedCallback = void Function(
    FlWebViewMethodChannel? webController);

abstract class WebViewPlatform {
  Widget build(
      {required BuildContext context,
      required WebViewParams webViewParams,
      required WebViewCallbacksHandler webViewPlatformCallbacksHandler,
      WebViewPlatformCreatedCallback? onWebViewPlatformCreated,
      Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers});
}

class AndroidWebView extends WebViewPlatform {
  @override
  Widget build({
    required BuildContext context,
    required WebViewParams webViewParams,
    required WebViewCallbacksHandler webViewPlatformCallbacksHandler,
    WebViewPlatformCreatedCallback? onWebViewPlatformCreated,
    Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers,
  }) =>
      PlatformViewLink(
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
                layoutDirection: TextDirection.rtl,
                creationParams: webViewParams.toMap(),
                creationParamsCodec: const StandardMessageCodec())
              ..addOnPlatformViewCreatedListener(params.onPlatformViewCreated)
              ..addOnPlatformViewCreatedListener((int id) {
                if (onWebViewPlatformCreated == null) return;
                final FlWebViewMethodChannel methodChannel =
                    FlWebViewMethodChannel(id, webViewPlatformCallbacksHandler);
                onWebViewPlatformCreated(methodChannel);
              })
              ..create();
          });
}

class IOSWebView implements WebViewPlatform {
  @override
  Widget build({
    required BuildContext context,
    required WebViewParams webViewParams,
    required WebViewCallbacksHandler webViewPlatformCallbacksHandler,
    WebViewPlatformCreatedCallback? onWebViewPlatformCreated,
    Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers,
  }) =>
      UiKitView(
          viewType: 'fl.webview',
          onPlatformViewCreated: (int id) {
            if (onWebViewPlatformCreated == null) {
              return;
            }
            final FlWebViewMethodChannel methodChannel =
                FlWebViewMethodChannel(id, webViewPlatformCallbacksHandler);
            onWebViewPlatformCreated(methodChannel);
          },
          gestureRecognizers: gestureRecognizers,
          creationParams: webViewParams.toMap(),
          creationParamsCodec: const StandardMessageCodec());
}

class FlWebView extends StatefulWidget {
  const FlWebView({
    Key? key,
    this.onWebViewCreated,
    this.initialUrl,
    this.initialHtml,
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
    this.deleteWindowSharedWorkerForIOS = false,
    this.userAgent,
    this.initialMediaPlaybackPolicy =
        AutoMediaPlaybackPolicy.requireUserActionForAllMediaTypes,
    this.allowsInlineMediaPlayback = false,
    this.useProgressGetContentSize = false,
    this.onContentSizeChanged,
    this.onScrollChanged,
    this.macOSWebView,
  })  : assert(initialHtml == null || initialUrl == null,
            'One of them must be used'),
        super(key: key);

  final WebViewCreatedCallback? onWebViewCreated;

  final Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers;

  final UrlData? initialUrl;

  final HtmlData? initialHtml;

  final JavascriptMode javascriptMode;

  final Set<JavascriptChannel>? javascriptChannels;

  final NavigationDelegate? navigationDelegate;

  final bool allowsInlineMediaPlayback;

  final PageStartedCallback? onPageStarted;

  final PageFinishedCallback? onPageFinished;

  final PageLoadingCallback? onProgress;

  final ContentSizeCallback? onContentSizeChanged;
  final bool useProgressGetContentSize;

  final ScrollChangedCallback? onScrollChanged;

  final WebResourceErrorCallback? onWebResourceError;

  final bool debuggingEnabled;

  final bool gestureNavigationEnabled;

  final bool deleteWindowSharedWorkerForIOS;

  final String? userAgent;

  final AutoMediaPlaybackPolicy initialMediaPlaybackPolicy;

  final MacOSWebView? macOSWebView;

  @override
  State<StatefulWidget> createState() => _WebViewState();
}

bool get _isMobile =>
    defaultTargetPlatform == TargetPlatform.android ||
    defaultTargetPlatform == TargetPlatform.iOS;

class _WebViewState extends State<FlWebView> {
  final Completer<WebViewController> controller =
      Completer<WebViewController>();

  WebViewCallbacksHandler? callbackHandler;
  WebViewPlatform? platform;

  @override
  void initState() {
    super.initState();
    if (_isMobile) {
      assertJavascriptChannelNamesAreUnique();
      callbackHandler = WebViewCallbacksHandler(widget);
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        platform = AndroidWebView();
        break;
      case TargetPlatform.iOS:
        platform = IOSWebView();
        break;
      case TargetPlatform.macOS:
        if (widget.initialUrl != null) {
          widget.macOSWebView?.open(url: widget.initialUrl);
        }
        break;
      default:
        throw UnsupportedError(
            "Trying to use the default webview implementation for $defaultTargetPlatform but there isn't a default one");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isMobile) {
      return Center(
          child: Text(defaultTargetPlatform == TargetPlatform.macOS
              ? 'Please see the new window'
              : 'Unsupported platforms $defaultTargetPlatform'));
    }
    return platform!.build(
        context: context,
        onWebViewPlatformCreated: _onWebViewPlatformCreated,
        webViewPlatformCallbacksHandler: callbackHandler!,
        gestureRecognizers: widget.gestureRecognizers,
        webViewParams: widget.webViewParams);
  }

  @override
  void didUpdateWidget(FlWebView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isMobile) return;
    assertJavascriptChannelNamesAreUnique();
    controller.future.then((WebViewController controller) {
      callbackHandler!._widget = widget;
      controller._updateWidget(widget);
    });
  }

  void _onWebViewPlatformCreated(FlWebViewMethodChannel? webViewPlatform) {
    final webViewController =
        WebViewController._(widget, webViewPlatform!, callbackHandler!);
    controller.complete(webViewController);
    widget.onWebViewCreated?.call(webViewController);
  }

  void assertJavascriptChannelNamesAreUnique() {
    if (widget.javascriptChannels == null ||
        widget.javascriptChannels!.isEmpty) {
      return;
    }
    assert(widget.javascriptChannels.extract.length ==
        widget.javascriptChannels!.length);
  }
}

/// Information about a navigation action that is about to be executed.
class NavigationRequest {
  NavigationRequest._({required this.url, required this.isForMainFrame});

  /// The URL that will be loaded if the navigation is executed.
  final String url;

  /// Whether the navigation request is to be loaded as the main frame.
  final bool isForMainFrame;

  @override
  String toString() =>
      '$runtimeType(url: $url, isForMainFrame: $isForMainFrame)';
}

class WebViewCallbacksHandler {
  WebViewCallbacksHandler(this._widget) {
    _updateJavascriptChannelsFromSet(_widget.javascriptChannels);
  }

  FlWebView _widget;

  final Map<String, JavascriptChannel> _javascriptChannels =
      <String, JavascriptChannel>{};

  void onJavaScriptChannelMessage(String channel, String message) {
    _javascriptChannels[channel]!.onMessageReceived(JavascriptMessage(message));
  }

  FutureOr<bool> onNavigationRequest(
      {required String url, required bool isForMainFrame}) async {
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

  void onContentSizeChanged(Size frameSize, Size contentSize) {
    if (_widget.onContentSizeChanged != null) {
      _widget.onContentSizeChanged!(frameSize, contentSize);
    }
  }

  void onScrollChanged(
      Size frameSize, Size contentSize, Offset offSet, int position) {
    if (_widget.onScrollChanged != null) {
      _widget.onScrollChanged!(
          frameSize, contentSize, offSet, ScrollPositioned.values[position]);
    }
  }
}

class WebViewController {
  WebViewController._(
      this._flWebView, this._methodChannel, this._callbackHandler) {
    _settings = _flWebView.webSettings;
  }

  final FlWebViewMethodChannel _methodChannel;

  final WebViewCallbacksHandler _callbackHandler;

  late WebSettings _settings;

  FlWebView _flWebView;

  Future<void> loadUrl(UrlData urlData) async {
    try {
      final Uri uri = Uri.parse(urlData.url);
      if (uri.scheme.isEmpty) {
        throw ArgumentError('Missing scheme in URL string: "${urlData.url}"');
      }
    } on FormatException catch (e) {
      throw ArgumentError(e);
    }
    return _methodChannel.loadUrl(urlData);
  }

  /// Accessor to the current URL that the WebView is displaying.
  ///
  /// If [WebView.initialUrl] was never specified, returns `null`.
  /// Note that this operation is asynchronous, and it is possible that the
  /// current URL changes again by the time this function returns (in other
  /// words, by the time this future completes, the WebView may be displaying a
  /// different URL).
  Future<String?> currentUrl() => _methodChannel.currentUrl();

  /// Checks whether there's a back history item.
  ///
  /// Note that this operation is asynchronous, and it is possible that the "canGoBack" state has
  /// changed by the time the future completed.
  Future<bool?> canGoBack() => _methodChannel.canGoBack();

  Future<bool?> canGoForward() => _methodChannel.canGoForward();

  Future<void> goBack() => _methodChannel.goBack();

  /// Goes forward in the history of this WebView.
  ///
  /// If there is no forward history item this is a no-op.
  Future<void> goForward() => _methodChannel.goForward();

  /// Reloads the current URL.
  Future<void> reload() => _methodChannel.reload();

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

  Future<void> _updateWidget(FlWebView flWebView) async {
    _flWebView = flWebView;
    _settings.update(flWebView.webSettings);
    await _methodChannel.updateSettings(_settings);
    await _updateJavascriptChannels(flWebView.javascriptChannels);
  }

  Future<void> _updateJavascriptChannels(
      Set<JavascriptChannel>? newChannels) async {
    final Set<String> currentChannels =
        _callbackHandler._javascriptChannels.keys.toSet();
    final Set<String> newChannelNames = newChannels.extract;
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
  Future<String?> evaluateJavascript(String javascriptString) {
    if (_settings.javascriptMode == JavascriptMode.disabled) {
      return Future<String>.error(FlutterError(
          'JavaScript mode must be enabled/unrestricted when calling evaluateJavascript.'));
    }
    return _methodChannel.evaluateJavascript(javascriptString);
  }

  /// Returns the title of the currently loaded page.
  Future<String?> getTitle() => _methodChannel.getTitle();

  /// Sets the WebView's content scroll position.
  ///
  /// The parameters `x` and `y` specify the scroll position in WebView pixels.
  Future<void> scrollTo(int x, int y) => _methodChannel.scrollTo(x, y);

  /// Move the scrolled position of this view.
  ///
  /// The parameters `x` and `y` specify the amount of WebView pixels to scroll by horizontally and vertically respectively.
  Future<void> scrollBy(int x, int y) => _methodChannel.scrollBy(x, y);

  /// Return the horizontal scroll position, in WebView pixels, of this view.
  ///
  /// Scroll position is measured from left.
  Future<int> getScrollX() => _methodChannel.getScrollX();

  /// Return the vertical scroll position, in WebView pixels, of this view.
  ///
  /// Scroll position is measured from top.
  Future<int> getScrollY() => _methodChannel.getScrollY();

  Future<bool?> scrollEnabled(bool enabled) =>
      _methodChannel.scrollEnabled(enabled);
}
