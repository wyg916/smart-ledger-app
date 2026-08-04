import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/app/app.dart';
import 'package:smart_ledger/core/database/database_providers.dart';
import 'package:smart_ledger/core/time/ledger_time.dart';
import 'package:smart_ledger/features/telemetry/domain/telemetry_coordinator.dart';
import 'package:smart_ledger/features/telemetry/presentation/telemetry_providers.dart';

import '../../support/ledger_test_harness.dart';

void main() {
  testWidgets(
    'natural language draft never writes before explicit confirmation',
    (tester) async {
      final harness = await LedgerTestHarness.create();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(harness.database),
            ledgerClockProvider.overrideWithValue(harness.clock),
            ledgerTimeZoneProvider.overrideWithValue(
              const FixedLedgerTimeZone('Asia/Shanghai'),
            ),
            entityIdGeneratorProvider.overrideWithValue(harness.ids),
            telemetryCoordinatorProvider.overrideWith(
              (ref) async => const _NoopTelemetryRecorder(),
            ),
          ],
          child: const SmartLedgerApp(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('natural-entry-input')),
        '今天早餐花了25元',
      );
      await tester.tap(find.byKey(const Key('natural-entry-submit')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(
        find.byKey(const Key('natural-entry-confirmation')),
        findsOneWidget,
      );
      expect(
        await harness.database
            .select(harness.database.ledgerTransactions)
            .get(),
        isEmpty,
      );

      await tester.tap(find.byKey(const Key('confirm-natural-entry')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        await harness.database
            .select(harness.database.ledgerTransactions)
            .get(),
        hasLength(1),
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 1));
      await harness.close();
    },
  );
}

final class _NoopTelemetryRecorder implements TelemetryRecorder {
  const _NoopTelemetryRecorder();

  @override
  Future<void> flush() async {}

  @override
  Future<void> end() async {}

  @override
  Future<void> record(
    String name, {
    Map<String, Object> properties = const {},
  }) async {}

  @override
  Future<void> start() async {}
}
