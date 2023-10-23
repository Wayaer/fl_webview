import 'package:example/extended_web_view.dart';
import 'package:example/html_webview.dart';
import 'package:example/url_webview.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fl_webview/fl_webview.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_waya/flutter_waya.dart';
import 'package:flutter_curiosity/flutter_curiosity.dart';
import 'package:permission_handler/permission_handler.dart';

const String url = 'https://juejin.cn/post/7212622837063811109';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Curiosity().desktop.focus().then((value) {
    Curiosity().desktop.setSizeTo6P1();
  });
  runApp(MaterialApp(
      navigatorKey: GlobalWayUI().navigatorKey,
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      debugShowCheckedModeBanner: false,
      home: const App(),
      title: 'FlWebview'));
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text('FlWebView Example')),
        body: Universal(
            expand: true,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ElevatedText(
                  text: 'Fixed height with WebView',
                  onPressed: () => push(const FixedHeightFlWebView())),
              const SizedBox(height: 10),
              ElevatedText(
                  text: 'WebView With ScrollView',
                  onPressed: () =>
                      push(const ExtendedFlWebViewWithScrollViewPage())),
              const SizedBox(height: 10),
              ElevatedText(text: 'Html Text with WebView', onPressed: getHtml),
              ElevatedText(
                  text: 'Html Text Adapt height with WebView',
                  onPressed: () => getHtml(true)),
              ElevatedText(
                  text: 'Select file',
                  onPressed: () async {
                    final String data =
                        await rootBundle.loadString('assets/select_file.html');
                    push(HtmlTextFlWebView(data, title: 'Select file'));
                  }),
              ElevatedText(
                  text: 'Permission request',
                  onPressed: () async {
                    final String data = await rootBundle
                        .loadString('assets/permission_request.html');
                    push(HtmlTextFlWebView(data, title: 'Permission request'));
                  }),
            ]));
  }

  Future<void> getHtml([bool adaptHeight = false]) async {
    final String data = await rootBundle.loadString('assets/text.html');
    if (adaptHeight) {
      push(AdaptHtmlTextFlWebView(data));
    } else {
      push(HtmlTextFlWebView(data));
    }
  }
}

class BaseFlWebView extends FlWebView {
  BaseFlWebView({
    super.key,
    required super.load,
    super.webSettings,
    FlWebViewDelegate? delegate,
    WebViewCreatedCallback? onWebViewCreated,
  }) : super(
          progressBar: FlProgressBar(color: Colors.red),
          delegate: FlWebViewDelegate(
              onPageStarted: (FlWebViewController controller, url) {
            'onPageStarted : $url'.log();
            delegate?.onPageStarted?.call(controller, url);
          }, onPageFinished: (FlWebViewController controller, url) {
            'onPageFinished : $url'.log();
            2.seconds.delayed(() {
              controller.getWebViewSize();
            });
            delegate?.onPageFinished?.call(controller, url);
          }, onProgress: (FlWebViewController controller, int progress) {
            'onProgress ：$progress'.log();
            delegate?.onProgress?.call(controller, progress);
          }, onSizeChanged:
                  (FlWebViewController controller, WebViewSize webViewSize) {
            'onSizeChanged : ${webViewSize.frameSize} --- ${webViewSize.contentSize}'
                .log();
            delegate?.onSizeChanged?.call(controller, webViewSize);
          }, onScrollChanged: (FlWebViewController controller,
                  WebViewSize webViewSize,
                  Offset offset,
                  ScrollPositioned positioned) {
            'onScrollChanged : ${webViewSize.frameSize} --- ${webViewSize.contentSize} --- $offset --- $positioned'
                .log();
            delegate?.onScrollChanged
                ?.call(controller, webViewSize, offset, positioned);
          }, onNavigationRequest:
                  (FlWebViewController controller, NavigationRequest request) {
            'onNavigationRequest : url=${request.url} --- isForMainFrame=${request.isForMainFrame}'
                .log();
            return delegate?.onNavigationRequest?.call(controller, request) ??
                true;
          }, onUrlChanged: (FlWebViewController controller, url) {
            'onUrlChanged : $url'.log();
            delegate?.onUrlChanged?.call(controller, url);
          }, onShowFileChooser: (_, params) async {
            'onShowFileChooser : ${params.toMap()}'.log();
            FileType fileType = FileType.any;
            if (params.acceptTypes.toString().contains('image')) {
              fileType = FileType.image;
            }
            if (params.acceptTypes.toString().contains('video')) {
              fileType = FileType.video;
            }
            if (params.acceptTypes.toString().contains('file')) {
              fileType = FileType.any;
            }
            FilePickerResult? result = await FilePicker.platform.pickFiles(
                type: fileType,
                allowMultiple: params.mode == FileChooserMode.openMultiple);
            final list = result?.files
                .where((item) => item.path != null)
                .builder((item) => item.path!);
            return list ?? [];
          }, onGeolocationPermissionsShowPrompt: (_, origin) async {
            'onGeolocationPermissionsShowPrompt : $origin'.log();
            return await getPermission(Permission.locationWhenInUse);
          }, onPermissionRequest: (_, List<String>? resources) {
            'onPermissionRequest : $resources'.log();
            return true;
          }, onPermissionRequestCanceled: (_, List<String>? resources) {
            'onPermissionRequestCanceled : $resources'.log();
          }),
          onWebViewCreated: (FlWebViewController controller) async {
            String userAgentString = 'userAgentString';
            final value = await controller.getNavigatorUserAgent();
            'navigator.userAgent :  $value'.log();
            userAgentString = '$value = $userAgentString';
            final userAgent = await controller.setUserAgent(userAgentString);
            'set userAgent:  $userAgent'.log();
            onWebViewCreated?.call(controller);
          },
        );
}

class ElevatedText extends StatelessWidget {
  const ElevatedText({super.key, required this.text, required this.onPressed});

  final String text;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final button = ElevatedButton(onPressed: onPressed, child: Text(text));
    if (!isMacOS) return button;
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6), child: button);
  }
}

Future<bool> getPermission(Permission permission) async {
  if (!isMobile) return false;
  final status = await permission.request();
  return status.isGranted;
}
