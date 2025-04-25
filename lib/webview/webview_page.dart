// webview_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../connectivity/connectivity_handler.dart';
import '../files/file_open_handler.dart';
import 'refresh_handler.dart';
import 'youtube_handler.dart';
import '../files/file_upload_handler.dart';
import '../session/session_manager.dart';
import '../extras/no_internet_popup.dart';

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
  bool _isTryingAgain = false;

  @override
  void initState() {
    super.initState();
    pullToRefreshController = RefreshHandler.createRefreshController(null);
    _monitorConnectivity();
  }

  void _monitorConnectivity() async {
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      // Update state when connectivity changes
      setState(() {
        ConnectivityHandler.isConnected.value = result != ConnectivityResult.none;
      });
    });
  }

  Future<void> _tryAgain() async {
    setState(() {
      _isTryingAgain = true;
    });

    final result = await Connectivity().checkConnectivity();
    final isConnected = result != ConnectivityResult.none;

    // Wait for a moment before checking again
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      ConnectivityHandler.isConnected.value = isConnected;
      _isTryingAgain = false;
    });
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
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  progress < 1.0
                      ? LinearProgressIndicator(
                          value: progress,
                          backgroundColor: const Color(0xFFB5B5B5),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF3794C8)),
                        )
                      : const SizedBox(),
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
                        pullToRefreshController =
                            RefreshHandler.createRefreshController(controller);
                        await restoreSession(controller);
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

                        await autofillLogin(controller);

                        await controller.evaluateJavascript(source: '''
                          document.querySelectorAll('a.account').forEach((accountElement) => {
                            accountElement.addEventListener('click', function(event) {
                              handleAccountSwitch(window.flutter_inappwebview);
                            });
                          });
                        ''');

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
            
            // Display "No Internet" overlay if no connection is available
            ValueListenableBuilder<bool>(
              valueListenable: ConnectivityHandler.isConnected,
              builder: (context, isConnected, child) {
                return !isConnected
                    ? Container(
                        color: Colors.black54,
                        alignment: Alignment.center,
                        child: NoInternetScreen(
                          onTryAgain: _isTryingAgain ? null : _tryAgain,
                          isLoading: _isTryingAgain,
                        ),
                      )
                    : SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    if (webViewController != null) {
      saveSession(webViewController!);
    }
    super.dispose();
  }
}
