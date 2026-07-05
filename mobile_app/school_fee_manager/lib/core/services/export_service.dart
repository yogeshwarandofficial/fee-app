import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Handles saving exported bytes to a temp file and sharing/opening it.
class ExportService {
  ExportService._();

  static Future<String> getTemporaryDir() async {
    final dir = await getTemporaryDirectory();
    return dir.path;
  }

  static Future<String> saveFile(String path, List<int> bytes) async {
    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  static Future<void> shareFile(String path) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(path, mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')],
        subject: 'Student Export',
      ),
    );
  }
}
