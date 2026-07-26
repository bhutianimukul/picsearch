import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Keeps a private, app-internal copy of scanned screenshots so the detail
/// screen can show a real preview (the source path — an image_picker cache or a
/// gallery asset — isn't guaranteed to persist). Stays on-device.
class ImageVault {
  Future<String> store(String srcPath) async {
    final dir = await getApplicationSupportDirectory();
    final imgDir = Directory('${dir.path}/vault_images');
    if (!await imgDir.exists()) await imgDir.create(recursive: true);
    final ext = srcPath.contains('.') ? srcPath.split('.').last : 'png';
    final dest = '${imgDir.path}/${DateTime.now().microsecondsSinceEpoch}.$ext';
    await File(srcPath).copy(dest);
    return dest;
  }
}
