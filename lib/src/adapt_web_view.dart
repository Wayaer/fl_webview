import 'package:fl_webview/fl_webview.dart';
import 'package:flutter/material.dart';

class FlAdaptWevView extends StatefulWidget {
  const FlAdaptWevView({Key? key, required this.child}) : super(key: key);
  final FlWebView child;

  @override
  _FlAdaptWevViewState createState() => _FlAdaptWevViewState();
}

class _FlAdaptWevViewState extends State<FlAdaptWevView> {
  Size currenrSize = const Size(double.infinity, 10);

  @override
  Widget build(BuildContext context) {
    return SizedBox.fromSize(
      size: currenrSize,
      child: FlWebView(
          onSizeChanged: (Size size) {
            if (currenrSize.height != size.height) {
              currenrSize = Size(currenrSize.width, size.height);
              setState(() {});
            }
            widget.child.onSizeChanged?.call(size);
          },
          onWebViewCreated: widget.child.onWebViewCreated,
          initialUrl: widget.child.initialUrl,
          initialData: widget.child.initialData,
          javascriptMode: widget.child.javascriptMode,
          javascriptChannels: widget.child.javascriptChannels,
          navigationDelegate: widget.child.navigationDelegate,
          gestureRecognizers: widget.child.gestureRecognizers,
          onPageStarted: widget.child.onPageStarted,
          onPageFinished: widget.child.onPageFinished,
          onProgress: widget.child.onProgress,
          onWebResourceError: widget.child.onWebResourceError,
          debuggingEnabled: widget.child.debuggingEnabled,
          gestureNavigationEnabled: widget.child.gestureNavigationEnabled,
          userAgent: widget.child.userAgent,
          initialMediaPlaybackPolicy: widget.child.initialMediaPlaybackPolicy,
          allowsInlineMediaPlayback: widget.child.allowsInlineMediaPlayback),
    );
  }
}
