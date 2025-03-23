import 'package:flutter_inappwebview/flutter_inappwebview.dart';

Future<PermissionRequestResponse> handlePermissionRequest(
    List<String> resources) async {
  return PermissionRequestResponse(
    resources: resources,
    action: PermissionRequestResponseAction.GRANT,
  );
}
