import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

class WebViewPage extends StatefulWidget {
  final String url;
  const WebViewPage({super.key, required this.url});

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late final WebViewController controller;
  bool canGoBack = false;

  @override
  void initState() {
    super.initState();

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) async {
            bool canGoBackNow = await controller.canGoBack();
            setState(() {
              canGoBack = canGoBackNow;
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.contains("youtube.com") || request.url.contains("youtu.be")) {
              _launchExternalApp(request.url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      
      ..loadRequest(Uri.parse(widget.url));

    _restoreSession(); // Restore cookies & session
  }

  /// 📌 Open YouTube links in YouTube App
  void _launchExternalApp(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      debugPrint("Could not open $url");
    }
  }

  /// 📌 Save Cookies & Session for Persistent Login
  Future<void> _saveSession() async {
    try {
      final cookies = await controller.runJavaScriptReturningResult("document.cookie");
      final prefs = await SharedPreferences.getInstance();
      prefs.setString("cookies", cookies.toString().replaceAll("\"", ""));
    } catch (e) {
      debugPrint("Error saving session: $e");
    }
  }

  /// 📌 Restore Session on App Restart
  Future<void> _restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    String? cookies = prefs.getString("cookies");

    if (cookies != null && cookies.isNotEmpty) {
      await controller.runJavaScript("document.cookie = '$cookies';");
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (await controller.canGoBack()) {
          controller.goBack();
        } else {
          SystemNavigator.pop(); // Exits the app
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: WebViewWidget(controller: controller),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _saveSession(); // Save session before closing
    super.dispose();
  }
}
