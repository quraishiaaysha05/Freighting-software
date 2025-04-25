import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class FileOpenHandler {
  static Future<void> openFileOrDownload(BuildContext context, String url) async {
    Uri uri = Uri.parse(url);
    String fileName = uri.pathSegments.last;

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // Show a downloading message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Downloading file...")),
      );

      // Download the file
      final directory = await getApplicationDocumentsDirectory();
      final filePath = "${directory.path}/$fileName";
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        File file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Download Complete!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to Download!")),
        );
      }
    }
  }
}
