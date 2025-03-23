import 'package:flutter_inappwebview/flutter_inappwebview.dart';

Future<bool> handleBackNavigation(InAppWebViewController controller) async {
  if (await controller.canGoBack()) {
    await controller.goBack();
    return false; // Prevent app exit
  }
  return true; // Exit app
}
