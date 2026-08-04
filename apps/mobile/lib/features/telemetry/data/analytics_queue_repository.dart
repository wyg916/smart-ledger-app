import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:smart_ledger/core/database/app_database.dart';
import 'package:smart_ledger/core/database/entity_id.dart';
import 'package:smart_ledger/core/time/ledger_time.dart';
import 'package:smart_ledger/features/telemetry/domain/telemetry_event.dart';

final class AnalyticsQueueRepository {
  const AnalyticsQueueRepository(this._database, this._clock, this._ids);

  static const maxQueueSize = 500;
  static const retention = Duration(days: 30);
  static const maxAttempts = 6;

  final AppDatabase _database;
  final LedgerClock _clock;
  final EntityIdGenerator _ids;

  Future<String> enqueue({
    required String name,
    required String sessionId,
    Map<String, Object> properties = const {},
  }) async {
    validateTelemetryEvent(name, properties);
    final now = _clock.nowUtc();
    final id = _ids.next();
    await _database.transaction(() async {
      await prune();
      final count = await _database.analyticsEventQueue.count().getSingle();
      if (count >= maxQueueSize) {
        final oldest =
            await (_database.select(_database.analyticsEventQueue)
                  ..orderBy([(row) => OrderingTerm.asc(row.createdAtMs)])
                  ..limit(1))
                .getSingleOrNull();
        if (oldest != null) {
          await (_database.delete(
            _database.analyticsEventQueue,
          )..where((row) => row.eventId.equals(oldest.eventId))).go();
        }
      }
      await _database
          .into(_database.analyticsEventQueue)
          .insert(
            AnalyticsEventQueueCompanion.insert(
              eventId: id,
              eventName: name,
              sessionId: sessionId,
              occurredAtMs: now.millisecondsSinceEpoch,
              propertiesJson: Value(jsonEncode(properties)),
              createdAtMs: now.millisecondsSinceEpoch,
            ),
          );
    });
    return id;
  }

  Future<List<QueuedTelemetryEvent>> nextBatch({int limit = 50}) async {
    final now = _clock.nowUtc().millisecondsSinceEpoch;
    final rows =
        await (_database.select(_database.analyticsEventQueue)
              ..where(
                (row) =>
                    row.attemptCount.isSmallerThanValue(maxAttempts) &
                    (row.nextRetryAtMs.isNull() |
                        row.nextRetryAtMs.isSmallerOrEqualValue(now)),
              )
              ..orderBy([(row) => OrderingTerm.asc(row.createdAtMs)])
              ..limit(limit.clamp(1, 50)))
            .get();
    return rows
        .map(
          (row) => QueuedTelemetryEvent(
            eventId: row.eventId,
            name: row.eventName,
            sessionId: row.sessionId,
            occurredAtUtc: DateTime.fromMillisecondsSinceEpoch(
              row.occurredAtMs,
              isUtc: true,
            ),
            properties: (jsonDecode(row.propertiesJson) as Map<String, dynamic>)
                .cast<String, Object>(),
            attemptCount: row.attemptCount,
          ),
        )
        .toList(growable: false);
  }

  Future<void> markUploaded(Iterable<String> eventIds) async {
    final ids = eventIds.toList(growable: false);
    if (ids.isEmpty) return;
    await (_database.delete(
      _database.analyticsEventQueue,
    )..where((row) => row.eventId.isIn(ids))).go();
  }

  Future<void> markFailed(Iterable<QueuedTelemetryEvent> events) async {
    final now = _clock.nowUtc();
    for (final event in events) {
      final attempts = event.attemptCount + 1;
      final minutes = 1 << attempts.clamp(0, 6);
      await (_database.update(
        _database.analyticsEventQueue,
      )..where((row) => row.eventId.equals(event.eventId))).write(
        AnalyticsEventQueueCompanion(
          attemptCount: Value(attempts),
          nextRetryAtMs: Value(
            now.add(Duration(minutes: minutes)).millisecondsSinceEpoch,
          ),
        ),
      );
    }
  }

  Future<int> prune() {
    final cutoff = _clock.nowUtc().subtract(retention).millisecondsSinceEpoch;
    return (_database.delete(_database.analyticsEventQueue)..where(
          (row) =>
              row.createdAtMs.isSmallerThanValue(cutoff) |
              row.attemptCount.isBiggerOrEqualValue(maxAttempts),
        ))
        .go();
  }

  Future<int> count() => _database.analyticsEventQueue.count().getSingle();
}
