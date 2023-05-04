import 'package:fl_webview/fl_webview.dart';



// extension ExtensionStringToUrlData on String {
//   UrlData parseUrlData({Map<String, String>? headers}) =>
//       UrlData(this, headers: headers);
// }
//
// class UrlData {
//   UrlData(this.url, {this.headers}) : assert(url.trim().isNotEmpty);
//
//   /// url
//   String url;
//
//   /// header
//   Map<String, String>? headers;
//
//   Map<String, dynamic> toMap() => {'url': url, 'headers': headers};
// }
//
// class HtmlData {
//   HtmlData(this.html,
//       {this.baseURL, this.mimeType = 'text/html', this.encoding = 'UTF-8'});
//
//   final String html;
//
//   /// Valid on IOS
//   final String? baseURL;
//
//   /// Valid on Android
//   final String mimeType;
//   final String encoding;
//
//   Map<String, String?> toMap() => {
//         'html': html,
//         'baseURL': baseURL,
//         'mimeType': mimeType,
//         'encoding': encoding
//       };
// }
//


// class WebSettings {
//   WebSettings({
//     this.autoMediaPlaybackPolicy = AutoMediaPlaybackPolicy.alwaysAllow,
//     this.javascriptMode,
//     this.debuggingEnabled = false,
//     this.gestureNavigationEnabled,
//     this.allowsInlineMediaPlayback,
//     this.hasNavigationDelegate = false,
//     this.hasProgressTracking = false,
//     this.hasContentSizeTracking = false,
//     this.hasScrollChangedTracking = false,
//     this.useProgressGetContentSize = true,
//     required this.userAgent,
//   });
//
//   final AutoMediaPlaybackPolicy autoMediaPlaybackPolicy;
//
//   JavascriptMode? javascriptMode;
//
//   bool hasNavigationDelegate;
//
//   bool hasProgressTracking;
//
//   bool hasContentSizeTracking;
//
//   bool useProgressGetContentSize;
//
//   bool hasScrollChangedTracking;
//
//   bool debuggingEnabled;
//
//   bool? allowsInlineMediaPlayback;
//
//   WebSetting<String?> userAgent;
//
//   bool? gestureNavigationEnabled;
//
//   Map<String, dynamic> toMap() => <String, dynamic>{
//         'javascriptMode': javascriptMode?.index,
//         'debuggingEnabled': debuggingEnabled,
//         'gestureNavigationEnabled': gestureNavigationEnabled,
//         'allowsInlineMediaPlayback': allowsInlineMediaPlayback,
//         'userAgent': userAgent.isPresent ? userAgent.value : null,
//         'hasNavigationDelegate': hasNavigationDelegate,
//         'hasProgressTracking': hasProgressTracking,
//         'hasContentSizeTracking': hasContentSizeTracking,
//         'useProgressGetContentSize': useProgressGetContentSize,
//         'hasScrollChangedTracking': hasScrollChangedTracking,
//         'autoMediaPlaybackPolicy': autoMediaPlaybackPolicy.index,
//       };
//
//   WebSettings update(WebSettings newSettings) {
//     assert(newSettings.javascriptMode != null);
//     if (javascriptMode != newSettings.javascriptMode) {
//       javascriptMode = newSettings.javascriptMode;
//     }
//     if (hasNavigationDelegate != newSettings.hasNavigationDelegate) {
//       hasNavigationDelegate = newSettings.hasNavigationDelegate;
//     }
//     if (hasProgressTracking != newSettings.hasProgressTracking) {
//       hasProgressTracking = newSettings.hasProgressTracking;
//     }
//     if (hasContentSizeTracking != newSettings.hasContentSizeTracking) {
//       hasContentSizeTracking = newSettings.hasContentSizeTracking;
//     }
//     if (hasScrollChangedTracking != newSettings.hasScrollChangedTracking) {
//       hasScrollChangedTracking = newSettings.hasScrollChangedTracking;
//     }
//     if (debuggingEnabled != newSettings.debuggingEnabled) {
//       debuggingEnabled = newSettings.debuggingEnabled;
//     }
//     if (userAgent != newSettings.userAgent) {
//       userAgent = newSettings.userAgent;
//     }
//     return this;
//   }
// }
//
// class WebViewParams {
//   WebViewParams({
//     this.initialUrl,
//     this.initialHtml,
//     this.webSettings,
//     this.javascriptChannelNames = const <String>{},
//     this.userAgent,
//     this.deleteWindowSharedWorkerForIOS = false,
//   });
//
//   final UrlData? initialUrl;
//
//   final HtmlData? initialHtml;
//
//   final WebSettings? webSettings;
//
//   final Set<String> javascriptChannelNames;
//
//   final String? userAgent;
//
//   bool deleteWindowSharedWorkerForIOS;
//
//   Map<String, dynamic> toMap() => <String, dynamic>{
//         'initialUrl': initialUrl?.toMap(),
//         'initialHtml': initialHtml?.toMap(),
//         'settings': webSettings?.toMap(),
//         'javascriptChannelNames': javascriptChannelNames.toList(),
//         'userAgent': userAgent,
//         'deleteWindowSharedWorkerForIOS': deleteWindowSharedWorkerForIOS
//       };
// }
