import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:smart_ledger/core/config/app_environment.dart';
import 'package:smart_ledger/features/ai/data/ai_api_client.dart';
import 'package:smart_ledger/features/ai/data/image_processing_service.dart';
import 'package:smart_ledger/features/ai/domain/ai_models.dart';
import 'package:smart_ledger/features/auth/presentation/auth_providers.dart';

final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final aiApiClientProvider = Provider<AiApiClient>((ref) {
  return HttpAiApiClient(
    ref.watch(httpClientProvider),
    apiBaseUrl,
    () => ref.read(authenticatedAccessTokenProvider),
  );
});

final imageProcessingServiceProvider = Provider<ImageProcessingService>(
  (ref) => ImageProcessingService(ImagePicker()),
);

final aiQuotaProvider = FutureProvider<AiQuotaStatus>(
  (ref) => ref.watch(aiApiClientProvider).quota(),
);
