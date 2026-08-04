import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image_lib;
import 'package:image_picker/image_picker.dart';
import 'package:smart_ledger/features/ai/data/image_processing_service.dart';

void main() {
  final service = ImageProcessingService(ImagePicker());

  test('reencodes an allowed image and strips it to bounded JPEG data', () {
    final source = image_lib.Image(width: 32, height: 20);
    final bytes = Uint8List.fromList(image_lib.encodePng(source));

    final result = service.process(bytes, 'receipt.png');

    expect(result.mimeType, 'image/jpeg');
    expect(result.filename, 'ledger-image.jpg');
    expect(result.width, 32);
    expect(result.height, 20);
    expect(image_lib.decodeJpg(result.bytes), isNotNull);
  });

  test('rejects unsupported extensions and invalid image content', () {
    expect(
      () => service.process(Uint8List.fromList([1, 2, 3]), 'receipt.gif'),
      throwsFormatException,
    );
    expect(
      () => service.process(Uint8List.fromList([1, 2, 3]), 'receipt.png'),
      throwsFormatException,
    );
  });
}
