import 'dart:async';

import 'package:fl_webview/fl_webview.dart';
import 'package:flutter/material.dart';

extension DurationExtension on Duration {
  ///   final _delay = 3.seconds;
  ///   print('+ wait $_delay');
  ///   await _delay.delayed();
  ///   print('- finish wait $_delay');
  ///   print('+ callback in 700ms');
  Future<T> delayed<T>([FutureOr<T> Function()? callback]) =>
      Future<T>.delayed(this, callback);
}

// extension ExtensionFlWebView on FlWebView {
//   WebViewParams get webViewParams => WebViewParams(
//       initialUrl: initialUrl,
//       initialHtml: initialHtml,
//       webSettings: webSettings,
//       javascriptChannelNames: javascriptChannels.extract,
//       deleteWindowSharedWorkerForIOS: deleteWindowSharedWorkerForIOS,
//       userAgent: userAgent);
//
//   WebSettings get webSettings => WebSettings(
//       javascriptMode: javascriptMode,
//       useProgressGetContentSize: useProgressGetContentSize,
//       autoMediaPlaybackPolicy: initialMediaPlaybackPolicy,
//       gestureNavigationEnabled: gestureNavigationEnabled,
//       allowsInlineMediaPlayback: allowsInlineMediaPlayback,
//       userAgent: WebSetting<String?>.of(userAgent));
// }

extension ExtensionJavascriptChannel on Set<JavascriptChannel>? {
  Set<String> get extract => this == null
      ? <String>{}
      : this!.map((JavascriptChannel channel) => channel.name).toSet();
}

extension ExtensionNum on num {
  Duration get milliseconds => Duration(microseconds: (this * 1000).round());

  Duration get seconds => Duration(milliseconds: (this * 1000).round());
}

void log(value) => debugPrint(value.toString());
