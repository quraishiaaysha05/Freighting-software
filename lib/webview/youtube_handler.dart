import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

Future<NavigationActionPolicy> handleExternalNavigation(
    InAppWebViewController controller, NavigationAction navigationAction) async {
  Uri url = navigationAction.request.url!;
  
  if (url.host.contains("youtube.com") || url.host.contains("youtu.be")) {
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
    return NavigationActionPolicy.CANCEL; // Prevent WebView from opening
  }
  
  return NavigationActionPolicy.ALLOW;
}
