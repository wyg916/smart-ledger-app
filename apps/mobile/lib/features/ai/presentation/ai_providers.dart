import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:smart_ledger/core/config/app_environment.dart';
import 'package:smart_ledger/features/ai/data/ai_api_client.dart';

final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final aiApiClientProvider = Provider<AiApiClient>((ref) {
  return HttpAiApiClient(ref.watch(httpClientProvider), apiBaseUrl);
});
