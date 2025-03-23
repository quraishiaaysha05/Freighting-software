import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer';

final CookieManager _cookieManager = CookieManager();

/// 📌 Save Cookies & Session for Persistent Login (if supported)
Future<void> saveSession(InAppWebViewController controller) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final cookies = await _cookieManager.getCookies(url: WebUri("https://app.freighting.in"));

    if (cookies.isNotEmpty) {
      String cookieString = cookies.map((cookie) => "${cookie.name}=${cookie.value}").join("; ");
      await prefs.setString("cookies", cookieString);
      log("✅ Session saved: $cookieString");
    }
  } catch (e) {
    log("❌ Error saving session: $e");
  }
}

/// 📌 Restore Session on App Restart (if cookies work)
Future<void> restoreSession(InAppWebViewController controller) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    String? cookies = prefs.getString("cookies");

    if (cookies != null && cookies.isNotEmpty) {
      List<String> cookieList = cookies.split("; ");
      for (String cookie in cookieList) {
        List<String> parts = cookie.split("=");
        if (parts.length == 2) {
          await _cookieManager.setCookie(
            url: WebUri("https://app.freighting.in"),
            name: parts[0].trim(),
            value: parts[1].trim(),
            isSecure: true,
            isHttpOnly: false,
          );
        }
      }
      log("✅ Session restored: $cookies");
    } else {
      log("⚠️ No saved cookies found.");
    }
  } catch (e) {
    log("❌ Error restoring session: $e");
  }
}

/// 📌 Save Login Credentials for Autofill (fallback if cookies don’t work)
Future<void> saveLoginCredentials(String username, String password) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString("username", username);
  await prefs.setString("password", password);
  log("✅ Login credentials saved");
}

/// 📌 Autofill Login Fields (if cookies don't work)
Future<void> autofillLogin(InAppWebViewController controller) async {
  final prefs = await SharedPreferences.getInstance();
  String? username = prefs.getString("username");
  String? password = prefs.getString("password");

  if (username != null && password != null) {
    controller.evaluateJavascript(source: '''
      document.querySelector("input[name='username']").value = "$username";
      document.querySelector("input[name='password']").value = "$password";
      document.querySelector("form").submit();
    ''');
    log("🔄 Autofilled login fields");
  }
}

/// 📌 Clear Cookies & Stored Credentials (for logout)
Future<void> clearSession() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove("cookies");
  await prefs.remove("username");
  await prefs.remove("password");
  await _cookieManager.deleteCookies(url: WebUri("https://app.freighting.in"));
  log("🔴 Session & credentials cleared");
}
