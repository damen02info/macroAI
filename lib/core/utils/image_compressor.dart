import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';

class ImageCompressor {
  static Future<File> compress(File image) async {
    final targetPath =
        '${image.parent.path}/compressed_${image.uri.pathSegments.last}';

    final compressed = await FlutterImageCompress.compressAndGetFile(
      image.path,
      targetPath,
      minWidth: 1024,
      minHeight: 1024,
      quality: 80,
      keepExif: false,
    );

    if (compressed == null) {
      throw Exception('Error al comprimir la imagen');
    }

    return File(compressed.path);
  }
}