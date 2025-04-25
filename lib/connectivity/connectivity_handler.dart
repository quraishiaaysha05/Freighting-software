import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityHandler {
  static late ValueNotifier<bool> isConnected;

  static void initialize() {
    isConnected = ValueNotifier(true);
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      isConnected.value = result != ConnectivityResult.none;
    });
  }
}
