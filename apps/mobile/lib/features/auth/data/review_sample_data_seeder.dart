import 'package:drift/drift.dart';
import 'package:smart_ledger/core/database/app_database.dart';
import 'package:smart_ledger/core/database/local_ledger_bootstrapper.dart';
import 'package:smart_ledger/core/time/ledger_time.dart';

final class ReviewSampleDataSeeder {
  const ReviewSampleDataSeeder(this._database, this._clock, this._timeZone);

  static const _marker = 'review_sample_seed_v1';
  final AppDatabase _database;
  final LedgerClock _clock;
  final LedgerTimeZone _timeZone;

  Future<void> initialize() async {
    final existing = await (_database.select(
      _database.appSettings,
    )..where((row) => row.key.equals(_marker))).getSingleOrNull();
    if (existing != null) return;

    final now = _clock.nowUtc();
    final nowMs = now.millisecondsSinceEpoch;
    final timeZoneId = await _timeZone.currentIanaId();
    final month = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final nextMonth = now.month == 12
        ? '${now.year + 1}-01-01'
        : '${now.year}-${(now.month + 1).toString().padLeft(2, '0')}-01';

    await _database.transaction(() async {
      final samples = [
        (
          '00000000-0000-4000-8000-000000000901',
          'income',
          '00000000-0000-4000-8000-000000000303',
          800000,
          8,
          '审核合成工资',
        ),
        (
          '00000000-0000-4000-8000-000000000902',
          'expense',
          '00000000-0000-4000-8000-000000000301',
          2850,
          2,
          '审核合成餐饮',
        ),
        (
          '00000000-0000-4000-8000-000000000903',
          'expense',
          '00000000-0000-4000-8000-000000000302',
          1299,
          1,
          '审核合成交通',
        ),
      ];
      for (final sample in samples) {
        await _database
            .into(_database.ledgerTransactions)
            .insert(
              LedgerTransactionsCompanion.insert(
                id: sample.$1,
                ledgerId: defaultLedgerId,
                transactionType: sample.$2,
                accountId: defaultAccountId,
                categoryId: Value(sample.$3),
                amountMinor: sample.$4,
                occurredAtUtcMs: now
                    .subtract(Duration(days: sample.$5))
                    .millisecondsSinceEpoch,
                timeZoneId: timeZoneId,
                note: Value(sample.$6),
                sourceType: const Value('manual'),
                createdAtMs: nowMs,
                updatedAtMs: nowMs,
              ),
              mode: InsertMode.insertOrIgnore,
            );
      }
      await _database
          .into(_database.budgets)
          .insert(
            BudgetsCompanion.insert(
              id: '00000000-0000-4000-8000-000000000904',
              ledgerId: defaultLedgerId,
              name: '审核合成月度预算',
              scopeType: 'total',
              yearMonth: month,
              amountMinor: 500000,
              currencyCode: 'CNY',
              timeZoneId: timeZoneId,
              startDateLocal: '$month-01',
              endDateLocal: nextMonth,
              createdAtMs: nowMs,
              updatedAtMs: nowMs,
            ),
            mode: InsertMode.insertOrIgnore,
          );
      await _database
          .into(_database.appSettings)
          .insert(
            AppSettingsCompanion.insert(
              key: _marker,
              valueType: 'bool',
              valueText: const Value('true'),
              updatedAtMs: nowMs,
              syncScope: const Value('device'),
            ),
            mode: InsertMode.insertOrReplace,
          );
    });
  }
}
