import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:freighting/session/session_manager.dart';
import 'refresh_handler.dart';
import '../files/file_open_handler.dart';
import 'youtube_handler.dart';

class WebViewNavigation extends StatefulWidget {
  const WebViewNavigation({super.key});

  @override
  State<WebViewNavigation> createState() => _WebViewNavigationState();
}

class _WebViewNavigationState extends State<WebViewNavigation> {
  InAppWebViewController? webViewController;
  PullToRefreshController? pullToRefreshController;
  double progress = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    pullToRefreshController = RefreshHandler.createRefreshController(null);
  }

  Future<bool> handleBackNavigation() async {
    if (await webViewController?.canGoBack() ?? false) {
      await webViewController?.goBack();
      return false;
    }
    return true;
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
        body: Column(
          children: [
            progress < 1.0
                ? LinearProgressIndicator(value: progress)
                : const SizedBox(),
            Expanded(
              child: InAppWebView(
                initialUrlRequest:
                    URLRequest(url: WebUri("https://app.freighting.in/")),
                initialSettings: InAppWebViewSettings(
                  useHybridComposition: true,
                  allowsInlineMediaPlayback: true,
                ),
                pullToRefreshController: pullToRefreshController,
                onWebViewCreated: (controller) async {
                  webViewController = controller;
                  pullToRefreshController =
                      RefreshHandler.createRefreshController(controller);
                  await restoreSession(controller); // ✅ Restore saved cookies
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

                  // ✅ Auto-login if session is lost
                  await autofillLogin(controller);

                  // ✅ Account switch handler (simulates logout & prompt new login)
                  await controller.evaluateJavascript(source: '''
                    window.handleAccountSwitch = function(flutterApp) {
                      flutterApp.postMessage(JSON.stringify({ type: 'account_switch' }));
                    };
                    document.querySelectorAll('a.account').forEach(account => {
                      account.addEventListener('click', function(event) {
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
                onPermissionRequest: (controller, request) async {
                  return PermissionResponse(
                    resources: request.resources,
                    action: PermissionResponseAction.GRANT,
                  );
                },
                onConsoleMessage: (controller, consoleMessage) async {
                  try {
                    final msg = consoleMessage.message;
                    if (msg.contains('account_switch')) {
                      await clearSession(); // 🔴 Clear cookies & creds
                      controller
                          .reload(); // 🔄 Reload to allow user to pick a new account
                    }
                  } catch (e) {
                    debugPrint("Error handling console message: $e");
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    if (webViewController != null) {
      saveSession(webViewController!); // ✅ Save session on close
    }
    super.dispose();
  }
}
