import 'package:flutter/material.dart';
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
Future<void> saveLoginCredentials(BuildContext context, String username, String password, {bool promptForUpdate = true}) async {
  final prefs = await SharedPreferences.getInstance();
  String? storedUsername = prefs.getString("username");
  String? storedPassword = prefs.getString("password");

  if (storedUsername != null && storedPassword != null && storedUsername != username) {
    // Ask the user if they want to update the credentials
    if (promptForUpdate) {
      bool shouldUpdate = await _showUpdateCredentialsDialog(context);
      if (shouldUpdate) {
        await prefs.setString("username", username);
        await prefs.setString("password", password);
        log("✅ Credentials updated: $username");
      }
    }
  } else {
    // Save new credentials
    await prefs.setString("username", username);
    await prefs.setString("password", password);
    log("✅ New credentials saved: $username");
  }
}

Future<bool> _showUpdateCredentialsDialog(BuildContext context) async {
  return await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Update Credentials"),
        content: const Text("Do you want to update the saved credentials?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Yes"),
          ),
        ],
      );
    },
  ) ?? false;
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

  // Clear all cookies
  final cookies = await _cookieManager.getCookies(url: WebUri("https://app.freighting.in"));
  for (var cookie in cookies) {
    await _cookieManager.deleteCookie(
      url: WebUri("https://app.freighting.in"),
      name: cookie.name,
    );
  }

  log("🔴 Session & credentials cleared");
}
