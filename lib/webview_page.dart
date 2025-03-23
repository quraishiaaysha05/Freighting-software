import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'connectivity_handler.dart';
import 'file_open_handler.dart';
import 'refresh_handler.dart';
import 'webview_navigation.dart';
import 'youtube_handler.dart';
import 'file_upload_handler.dart';
import 'session_manager.dart';

class WebViewPage extends StatefulWidget {
  final String url;
  const WebViewPage({super.key, required this.url});

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  InAppWebViewController? webViewController;
  PullToRefreshController? pullToRefreshController;
  double progress = 0;
  bool isLoading = true;
  bool _isConnectivityInitialized = false;

  @override
  void initState() {
    super.initState();
    pullToRefreshController = RefreshHandler.createRefreshController(null);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isConnectivityInitialized) {
      ConnectivityHandler.initialize(context);
      _isConnectivityInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (await webViewController?.canGoBack() ?? false) {
          webViewController?.goBack();
        } else {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              progress < 1.0 ? LinearProgressIndicator(value: progress) : const SizedBox(),
              Expanded(
                child: InAppWebView(
                  initialUrlRequest: URLRequest(url: WebUri(widget.url)),
                  initialSettings: InAppWebViewSettings(
                    useHybridComposition: true,
                    allowsInlineMediaPlayback: true,
                  ),
                  pullToRefreshController: pullToRefreshController,
                  onWebViewCreated: (controller) async {
                    webViewController = controller;
                    pullToRefreshController = RefreshHandler.createRefreshController(controller);

                    await restoreSession(controller); // ✅ Try restoring session cookies
                  },
                  onLoadStart: (controller, url) {
                    setState(() {
                      isLoading = true;
                    });
                  },
                  onLoadStop: (controller, url) async {
                    setState(() {
                      isLoading = false;
                    });
                    RefreshHandler.stopRefreshing(pullToRefreshController);

                    // ✅ Autofill login if session is lost
                    await autofillLogin(controller);
                  },
                  onProgressChanged: (controller, progressValue) {
                    setState(() {
                      progress = progressValue / 100;
                    });
                  },
                  shouldOverrideUrlLoading: (controller, navigationAction) async {
                    Uri? uri = navigationAction.request.url;
                    if (uri != null && uri.path.endsWith(".pdf")) {
                      FileOpenHandler.openFileOrDownload(context, uri.toString());
                      return NavigationActionPolicy.CANCEL;
                    }
                    return handleExternalNavigation(controller, navigationAction);
                  },
                  androidOnPermissionRequest: (controller, origin, resources) async {
                    return handlePermissionRequest(resources);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    if (webViewController != null) {
      saveSession(webViewController!); // ✅ Save session when closing
    }
    super.dispose();
  }
}
