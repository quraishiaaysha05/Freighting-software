import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityHandler {
  static final Connectivity _connectivity = Connectivity();
  static bool isConnected = true;
  static BuildContext? _context;
  static ScaffoldMessengerState? _scaffoldMessenger;

  static void initialize(BuildContext context) {
    _context = context;
    _scaffoldMessenger = ScaffoldMessenger.of(context);
    _connectivity.onConnectivityChanged.listen((result) {
      bool newStatus = result != ConnectivityResult.none;
      if (newStatus != isConnected) {
        isConnected = newStatus;
        _handleConnectivityChange();
      }
    });
  }

  static void _handleConnectivityChange() {
    if (!isConnected) {
      // Show Persistent Red Snackbar
      _scaffoldMessenger!.showSnackBar(
        SnackBar(
          content: const Text("No Internet Connection"),
          backgroundColor: Colors.red,
          duration: const Duration(days: 1),
        ),
      );
    } else {
      // Remove Snackbar when internet is back
      _scaffoldMessenger!.hideCurrentSnackBar();
    }
  }
}
