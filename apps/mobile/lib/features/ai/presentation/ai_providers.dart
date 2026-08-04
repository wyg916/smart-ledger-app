import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:smart_ledger/core/config/app_environment.dart';
import 'package:smart_ledger/features/ai/data/ai_api_client.dart';
import 'package:smart_ledger/features/ai/data/image_processing_service.dart';

final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final aiApiClientProvider = Provider<AiApiClient>((ref) {
  return HttpAiApiClient(ref.watch(httpClientProvider), apiBaseUrl);
});

final imageProcessingServiceProvider = Provider<ImageProcessingService>(
  (ref) => ImageProcessingService(ImagePicker()),
);
