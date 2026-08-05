import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:smart_ledger/core/config/app_environment.dart';
import 'package:smart_ledger/core/time/ledger_time.dart';
import 'package:smart_ledger/features/auth/data/auth_api_client.dart';
import 'package:smart_ledger/features/auth/data/auth_platform_gateway.dart';
import 'package:smart_ledger/features/auth/data/auth_session_store.dart';
import 'package:smart_ledger/features/auth/data/local_data_isolation_service.dart';
import 'package:smart_ledger/features/auth/domain/auth_session.dart';
import 'package:smart_ledger/features/auth/presentation/auth_controller.dart';
import 'package:smart_ledger/features/identity/presentation/identity_providers.dart';

final authSessionStoreProvider = Provider<AuthSessionStore>((ref) {
  if (Platform.environment['FLUTTER_TEST'] == 'true') {
    return InMemoryAuthSessionStore(AuthSession.syntheticTest());
  }
  return const SecureAuthSessionStore(FlutterSecureStorage());
});

final authHttpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final authApiClientProvider = Provider<AuthApiClient>(
  (ref) => HttpAuthApiClient(ref.watch(authHttpClientProvider), apiBaseUrl),
);

final authPlatformGatewayProvider = Provider<AuthPlatformGateway>((ref) {
  final environment = ref.watch(appEnvironmentProvider);
  if (Platform.environment['FLUTTER_TEST'] == 'true' ||
      environment != AppEnvironment.production) {
    return const FakeAuthPlatformGateway();
  }
  return const MethodChannelAuthPlatformGateway();
});

final localDataIsolationServiceProvider = Provider<LocalDataIsolationService>(
  (ref) => const LocalDataIsolationService(),
);

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    final isTest = Platform.environment['FLUTTER_TEST'] == 'true';
    final controller = AuthController(
      ref.watch(authSessionStoreProvider),
      ref.watch(authApiClientProvider),
      ref.watch(authPlatformGatewayProvider),
      ref.watch(anonymousIdentityServiceProvider),
      ref.watch(localDataIsolationServiceProvider),
      timeZone: const DeviceLedgerTimeZone(),
      skipRemoteRestore: isTest,
      skipBindingCheck: isTest,
    );
    unawaited(controller.initialize());
    return controller;
  },
);

final authenticatedAccessTokenProvider = Provider<String?>(
  (ref) => ref.watch(authControllerProvider).session?.accessToken,
);

final authenticatedUserIdProvider = Provider<String?>(
  (ref) => ref.watch(authControllerProvider).session?.userId,
);
