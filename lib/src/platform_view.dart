import 'package:fl_webview/fl_webview.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

typedef WebViewCreatedCallback = void Function(FlWebViewController controller);

class WebViewPlatform extends StatelessWidget {
  const WebViewPlatform(
      {super.key,
      this.layoutDirection = TextDirection.ltr,
      required this.onWebViewPlatformCreated,
      this.creationParamsCodec = const StandardMessageCodec(),
      this.gestureRecognizers,
      required this.webSettings});

  final WebViewCreatedCallback onWebViewPlatformCreated;
  final Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers;
  final TextDirection layoutDirection;
  final MessageCodec<dynamic> creationParamsCodec;
  final WebSettings webSettings;

  @override
  Widget build(BuildContext context) {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return androidView;
      case TargetPlatform.fuchsia:
        break;
      case TargetPlatform.iOS:
        return iosView;
      case TargetPlatform.linux:
        break;
      case TargetPlatform.macOS:
        return iosView;
      case TargetPlatform.windows:
        break;
    }
    return Center(child: Text('Unsupported platforms $defaultTargetPlatform'));
  }

  Widget get androidView => PlatformViewLink(
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
            layoutDirection: layoutDirection,
            creationParams: webSettings.toMap(),
            creationParamsCodec: creationParamsCodec)
          ..addOnPlatformViewCreatedListener(params.onPlatformViewCreated)
          ..addOnPlatformViewCreatedListener((int id) {
            onWebViewPlatformCreated.call(FlWebViewController(id));
          })
          ..create();
      });

  Widget get iosView => UiKitView(
      viewType: 'fl.webview',
      creationParams: webSettings.toMap(),
      layoutDirection: layoutDirection,
      onPlatformViewCreated: (int id) {
        onWebViewPlatformCreated.call(FlWebViewController(id));
      },
      gestureRecognizers: gestureRecognizers,
      creationParamsCodec: creationParamsCodec);
}
