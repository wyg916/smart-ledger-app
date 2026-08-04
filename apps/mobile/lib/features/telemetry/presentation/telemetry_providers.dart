import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_ledger/core/config/app_environment.dart';
import 'package:smart_ledger/core/database/database_providers.dart';
import 'package:smart_ledger/features/ai/presentation/ai_providers.dart';
import 'package:smart_ledger/features/identity/presentation/identity_providers.dart';
import 'package:smart_ledger/features/telemetry/data/analytics_queue_repository.dart';
import 'package:smart_ledger/features/telemetry/data/telemetry_api_client.dart';
import 'package:smart_ledger/features/telemetry/domain/telemetry_coordinator.dart';

final analyticsQueueRepositoryProvider = Provider<AnalyticsQueueRepository>(
  (ref) => AnalyticsQueueRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(ledgerClockProvider),
    ref.watch(entityIdGeneratorProvider),
  ),
);

final telemetryApiClientProvider = Provider<TelemetryApiClient>(
  (ref) => HttpTelemetryApiClient(ref.watch(httpClientProvider), apiBaseUrl),
);

final telemetryCoordinatorProvider = FutureProvider<TelemetryRecorder>((
  ref,
) async {
  final identity = await ref.watch(anonymousIdentityProvider.future);
  final coordinator = TelemetryCoordinator(
    ref.watch(analyticsQueueRepositoryProvider),
    ref.watch(telemetryApiClientProvider),
    ref.watch(anonymousIdentityServiceProvider),
    identity,
  );
  await coordinator.start();
  return coordinator;
});

final telemetryPageEventProvider = FutureProvider.autoDispose
    .family<void, String>((ref, name) async {
      final coordinator = await ref.watch(telemetryCoordinatorProvider.future);
      await coordinator.record(name);
    });
