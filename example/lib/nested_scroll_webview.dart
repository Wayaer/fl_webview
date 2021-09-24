import 'package:example/main.dart';
import 'package:fl_webview/fl_webview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_waya/flutter_waya.dart';

class NestedScrollViewAndWebView extends StatefulWidget {
  const NestedScrollViewAndWebView({Key? key}) : super(key: key);

  @override
  _NestedScrollViewAndWebViewState createState() =>
      _NestedScrollViewAndWebViewState();
}

class _NestedScrollViewAndWebViewState
    extends State<NestedScrollViewAndWebView> {
  bool canScroll = false;

  @override
  Widget build(BuildContext context) {
    double webHeight = deviceHeight -
        getStatusBarHeight -
        getBottomNavigationBarHeight -
        kToolbarHeight -
        100;
    Widget webview = FlWebView(
        initialUrl: url,
        javascriptMode: JavascriptMode.unrestricted,
        onScrollChanged: (Size frameSize, Size contentSize, Offset offset,
            ScrollPositioned positioned) {
          log(positioned);
          if (positioned == ScrollPositioned.end) {
            canScroll = true;
            setState(() {});
          }
        });
    return ExtendedScaffold(
        appBar: AppBar(title: const Text('NestedScrollWebView Example')),
        body: NestedScrollView(
            physics: const NeverScrollableScrollPhysics(),
            // reverse: true,
            headerSliverBuilder: (_, bool innerBoxIsScrolled) {
              return [
                // ExtendedSliverAppBar(
                //   expandedHeight: webHeight,
                //   background: webview,
                // ),
                // ExtendedSliverPersistentHeader(
                //   child: webview,
                //   pinned: false,
                //   floating: false,
                //   maxHeight: webHeight,
                //   minHeight: 1,
                // )
                // ScrollList.builder(
                //     physics: const NeverScrollableScrollPhysics(),
                //     itemBuilder: (_, int index) => Container(
                //         height: 100,
                //         width: double.infinity,
                //         color: index.isEven
                //             ? Colors.lightBlue
                //             : Colors.amberAccent),
                //     itemCount: 30)
                SliverListGrid(
                    itemBuilder: (_, int index) => Container(
                        height: 100,
                        width: double.infinity,
                        color: index.isEven
                            ? Colors.lightBlue
                            : Colors.amberAccent),
                    itemCount: 2),
              ];
            },
            body: webview));
  }
}
