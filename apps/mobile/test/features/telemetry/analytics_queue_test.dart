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
      userId: '10000000-0000-4000-8000-000000000101',
      identityScope: 'authenticated',
      schemaVersion: 2,
      properties: const {'entry_method': 'manual'},
    );
    expect(await queue.count(), 1);
    final batch = await queue.nextBatch();
    expect(batch, hasLength(1));
    expect(batch.single.properties, {'entry_method': 'manual'});
    expect(batch.single.userId, '10000000-0000-4000-8000-000000000101');
    expect(batch.single.identityScope, 'authenticated');
    expect(batch.single.schemaVersion, 2);
    expect(batch.single.toJson()['user_id'], batch.single.userId);

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

  test('pre-auth events never invent a user id', () async {
    final harness = await LedgerTestHarness.create();
    addTearDown(harness.close);
    final queue = AnalyticsQueueRepository(
      harness.database,
      harness.clock,
      harness.ids,
    );
    await queue.enqueue(
      name: 'login_page_viewed',
      sessionId: '10000000-0000-4000-8000-000000000199',
      identityScope: 'pre_auth',
      schemaVersion: 2,
    );
    final event = (await queue.nextBatch()).single;
    expect(event.userId, isNull);
    expect(event.toJson(), isNot(contains('user_id')));
    expect(event.identityScope, 'pre_auth');
  });
}
