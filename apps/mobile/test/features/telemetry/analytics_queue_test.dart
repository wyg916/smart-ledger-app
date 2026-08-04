import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/features/telemetry/data/analytics_queue_repository.dart';

import '../../support/ledger_test_harness.dart';

void main() {
  test('offline queue is strict, batched, retryable, and age-pruned', () async {
    final harness = await LedgerTestHarness.create();
    addTearDown(harness.close);
    final queue = AnalyticsQueueRepository(
      harness.database,
      harness.clock,
      harness.ids,
    );

    await queue.enqueue(
      name: 'transaction_created',
      sessionId: '10000000-0000-4000-8000-000000000099',
      properties: const {'entry_method': 'manual'},
    );
    expect(await queue.count(), 1);
    final batch = await queue.nextBatch();
    expect(batch, hasLength(1));
    expect(batch.single.properties, {'entry_method': 'manual'});

    await queue.markFailed(batch);
    expect(await queue.nextBatch(), isEmpty);
    harness.clock.value = harness.clock.value.add(const Duration(minutes: 3));
    expect(await queue.nextBatch(), hasLength(1));

    expect(
      () => queue.enqueue(
        name: 'raw_note_uploaded',
        sessionId: 'x',
        properties: const {},
      ),
      throwsArgumentError,
    );
    harness.clock.value = harness.clock.value.add(const Duration(days: 31));
    expect(await queue.prune(), 1);
    expect(await queue.count(), 0);
  });
}
