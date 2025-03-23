import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class RefreshHandler {
  static PullToRefreshController createRefreshController(InAppWebViewController? controller) {
    return PullToRefreshController(
      options: PullToRefreshOptions(
        color: Colors.white, // Spinner color
        backgroundColor: Colors.blue, // Background color
      ),
      onRefresh: () async {
        if (controller != null) {
          await controller.reload();
        }
      },
    );
  }

  static void stopRefreshing(PullToRefreshController? refreshController) {
    refreshController?.endRefreshing();
  }
}
