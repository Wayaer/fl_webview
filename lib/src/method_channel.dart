// import 'dart:async';
//
// import 'package:fl_webview/fl_webview.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/services.dart';
//
//
// enum PresentationStyle {
//   modal,
//   sheet,
// }
//
// typedef MacOSWebViewCallbackUrl = void Function(String url);
//
// class MacOSWebView {
//   MacOSWebView({
//     this.onOpen,
//     this.onClose,
//     this.onPageStarted,
//     this.onPageFinished,
//     this.onWebResourceError,
//     required this.url,
//     this.javascriptMode = JavascriptMode.disabled,
//     this.presentationStyle = PresentationStyle.sheet,
//     this.size,
//     this.userAgent,
//     this.modalTitle = '',
//     this.sheetCloseButtonTitle = 'Close',
//   }) : assert(defaultTargetPlatform == TargetPlatform.macOS);
//
//   UrlData url;
//   final JavascriptMode javascriptMode;
//   final PresentationStyle presentationStyle;
//   final Size? size;
//   final String? userAgent;
//   final String modalTitle;
//   final String sheetCloseButtonTitle;
//   final MacOSWebViewCallbackUrl? onOpen;
//   final MacOSWebViewCallbackUrl? onClose;
//   final MacOSWebViewCallbackUrl? onPageStarted;
//   final MacOSWebViewCallbackUrl? onPageFinished;
//   final void Function(WebResourceError error)? onWebResourceError;
//
//   Future<bool?> open({UrlData? url}) async {
//     if (url != null) {
//       this.url = url;
//     }
//     _flChannel.setMethodCallHandler(_onMethodCall);
//     return await _flChannel.invokeMethod<bool?>('openWebView', {
//       'urlData': this.url.toMap(),
//       'javascriptMode': javascriptMode.index,
//       'presentationStyle': presentationStyle.index,
//       'customSize': size != null,
//       'width': size?.width,
//       'height': size?.height,
//       'userAgent': userAgent,
//       'modalTitle': modalTitle,
//       'sheetCloseButtonTitle': sheetCloseButtonTitle,
//     });
//   }
//
//   /// Closes WebView
//   Future<bool?> close() async {
//     _flChannel.setMethodCallHandler(null);
//     return await _flChannel.invokeMethod<bool?>('closeWebView');
//   }
//
//   Future<void> _onMethodCall(MethodCall call) async {
//     switch (call.method) {
//       case 'onOpen':
//         onOpen?.call(url.url);
//         return;
//       case 'onClose':
//         onClose?.call(url.url);
//         return;
//       case 'onPageStarted':
//         onPageStarted?.call(call.arguments['url']);
//         return;
//       case 'onPageFinished':
//         onPageFinished?.call(call.arguments['url']);
//         return;
//       case 'onWebResourceError':
//         onWebResourceError?.call(WebResourceError(
//             errorCode: call.arguments['errorCode'],
//             description: call.arguments['description'],
//             domain: call.arguments['domain'],
//             errorType: call.arguments['errorType'] == null
//                 ? null
//                 : WebResourceErrorType.values.firstWhere(
//                     (type) {
//                       return type.toString() ==
//                           '$WebResourceErrorType.${call.arguments['errorType']}';
//                     },
//                   )));
//         return;
//     }
//   }
// }
