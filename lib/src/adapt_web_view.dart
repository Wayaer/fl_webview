import 'package:fl_webview/fl_webview.dart';
import 'package:flutter/material.dart';

class FlAdaptHeightWevView extends StatefulWidget {
  const FlAdaptHeightWevView({Key? key, required this.child, this.initialSize})
      : super(key: key);
  final FlWebView child;
  final Size? initialSize;

  @override
  _FlAdaptHeightWevViewState createState() => _FlAdaptHeightWevViewState();
}

class _FlAdaptHeightWevViewState extends State<FlAdaptHeightWevView> {
  Size currenrSize = const Size(double.infinity, 50);

  @override
  void initState() {
    super.initState();
    if (widget.initialSize != null) currenrSize = widget.initialSize!;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.fromSize(
        size: currenrSize,
        child: FlWebView(
            onContentSizeChanged: (Size size) {
              widget.child.onContentSizeChanged?.call(size);
              if (currenrSize.height != size.height) {
                currenrSize = Size(currenrSize.width, size.height);
                setState(() {});
              }
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
            allowsInlineMediaPlayback: widget.child.allowsInlineMediaPlayback));
  }
}
