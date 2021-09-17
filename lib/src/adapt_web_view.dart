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
            allowsInlineMediaPlayback: widget.child.allowsInlineMediaPlayback));
  }
}

typedef FlWebViewScrollTop = void Function();
typedef FlWebViewScrollBottom = void Function();

class FlFixedHeightWebView extends StatelessWidget {
  const FlFixedHeightWebView(
      {Key? key,
      required this.height,
      this.onScrollTop,
      this.onScrollBottom,
      required this.child})
      : super(key: key);
  final FlWebView child;
  final double height;
  final FlWebViewScrollTop? onScrollTop;
  final FlWebViewScrollTop? onScrollBottom;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: double.infinity,
        height: height,
        child: FlWebView(
          onWebViewCreated: child.onWebViewCreated,
          initialUrl: child.initialUrl,
          initialData: child.initialData,
          javascriptMode: child.javascriptMode,
          javascriptChannels: child.javascriptChannels,
          navigationDelegate: child.navigationDelegate,
          gestureRecognizers: child.gestureRecognizers,
          onPageStarted: child.onPageStarted,
          onPageFinished: child.onPageFinished,
          onProgress: child.onProgress,
          onWebResourceError: child.onWebResourceError,
          debuggingEnabled: child.debuggingEnabled,
          gestureNavigationEnabled: child.gestureNavigationEnabled,
          userAgent: child.userAgent,
          initialMediaPlaybackPolicy: child.initialMediaPlaybackPolicy,
          allowsInlineMediaPlayback: child.allowsInlineMediaPlayback,
          onSizeChanged: child.onSizeChanged,
          onScrollChanged:
              (Size size, Offset offset, ScrollPositioned positioned) {
            print(
                '${size.toString()}===${positioned.toString()}===${offset.toString()}');
            child.onScrollChanged?.call(size, offset, positioned);
          },
        ));
  }
}
