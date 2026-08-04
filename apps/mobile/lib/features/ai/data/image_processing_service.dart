import 'dart:typed_data';

import 'package:image/image.dart' as image_lib;
import 'package:image_picker/image_picker.dart';

final class ProcessedImage {
  const ProcessedImage({
    required this.bytes,
    required this.filename,
    required this.mimeType,
    required this.width,
    required this.height,
  });

  final Uint8List bytes;
  final String filename;
  final String mimeType;
  final int width;
  final int height;
}

final class ImageProcessingService {
  const ImageProcessingService(this._picker);

  static const maxInputBytes = 8 * 1024 * 1024;
  static const maxDimension = 4096;
  static const maxPixels = 16000000;

  final ImagePicker _picker;

  Future<ProcessedImage?> pickAndProcess() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return null;
    return process(await picked.readAsBytes(), picked.name);
  }

  ProcessedImage process(Uint8List bytes, String filename) {
    final extension = filename.split('.').last.toLowerCase();
    if (!const {'png', 'jpg', 'jpeg', 'webp'}.contains(extension)) {
      throw const FormatException('仅支持 PNG、JPEG 或 WebP');
    }
    if (bytes.length > maxInputBytes) {
      throw const FormatException('图片不能超过 8 MiB');
    }
    image_lib.Image? decoded;
    try {
      decoded = image_lib.decodeImage(bytes);
    } on RangeError {
      throw const FormatException('图片内容无效');
    } on StateError {
      throw const FormatException('图片内容无效');
    }
    if (decoded == null) throw const FormatException('图片内容无效');
    if (decoded.width * decoded.height > maxPixels) {
      throw const FormatException('图片像素不能超过 1600 万');
    }
    if (decoded.width > maxDimension || decoded.height > maxDimension) {
      decoded = image_lib.copyResize(
        decoded,
        width: decoded.width >= decoded.height ? maxDimension : null,
        height: decoded.height > decoded.width ? maxDimension : null,
        interpolation: image_lib.Interpolation.average,
      );
    }
    final encoded = Uint8List.fromList(
      image_lib.encodeJpg(decoded, quality: 84),
    );
    if (encoded.length > maxInputBytes) {
      throw const FormatException('压缩后图片仍超过 8 MiB');
    }
    return ProcessedImage(
      bytes: encoded,
      filename: 'ledger-image.jpg',
      mimeType: 'image/jpeg',
      width: decoded.width,
      height: decoded.height,
    );
  }
}
