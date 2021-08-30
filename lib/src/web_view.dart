import 'package:fl_webview/fl_webview.dart';
import 'package:fl_webview/platform_interface.dart';
import 'package:fl_webview/src/method_channel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

typedef WebViewPlatformCreatedCallback = void Function(
    FlWebViewMethodChannel? webController);

abstract class WebViewPlatform {
  Widget build({
    required BuildContext context,
    required CreationParams creationParams,
    required WebViewCallbacksHandler webViewPlatformCallbacksHandler,
    WebViewPlatformCreatedCallback? onWebViewPlatformCreated,
    Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers,
  });
}

class AndroidWebView extends WebViewPlatform {
  @override
  Widget build({
    required BuildContext context,
    required CreationParams creationParams,
    required WebViewCallbacksHandler webViewPlatformCallbacksHandler,
    WebViewPlatformCreatedCallback? onWebViewPlatformCreated,
    Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers,
  }) =>
      PlatformViewLink(
          viewType: 'fl.webview',
          surfaceFactory:
              (BuildContext context, PlatformViewController controller) =>
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
                creationParams: creationParams.toMap(),
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

class CupertinoWebView implements WebViewPlatform {
  @override
  Widget build({
    required BuildContext context,
    required CreationParams creationParams,
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
          creationParams: creationParams.toMap(),
          creationParamsCodec: const StandardMessageCodec());
}
