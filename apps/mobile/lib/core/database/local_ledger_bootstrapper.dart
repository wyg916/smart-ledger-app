import 'package:drift/drift.dart';
import 'package:smart_ledger/core/database/app_database.dart';
import 'package:smart_ledger/core/time/ledger_time.dart';

const defaultLedgerId = '00000000-0000-4000-8000-000000000100';
const defaultAccountId = '00000000-0000-4000-8000-000000000200';

const _defaultCategories = [
  ('00000000-0000-4000-8000-000000000301', 'expense', '餐饮', 'expense_food'),
  (
    '00000000-0000-4000-8000-000000000302',
    'expense',
    '交通',
    'expense_transport',
  ),
  ('00000000-0000-4000-8000-000000000303', 'income', '工资', 'income_salary'),
  ('00000000-0000-4000-8000-000000000304', 'income', '其他收入', 'income_other'),
];

final class LocalLedgerBootstrapper {
  const LocalLedgerBootstrapper(this._database, this._clock, this._timeZone);

  final AppDatabase _database;
  final LedgerClock _clock;
  final LedgerTimeZone _timeZone;

  Future<void> initialize() async {
    final now = _clock.nowUtc().millisecondsSinceEpoch;
    final timeZoneId = await _timeZone.currentIanaId();
    await _database.transaction(() async {
      await _database
          .into(_database.ledgers)
          .insert(
            LedgersCompanion.insert(
              id: defaultLedgerId,
              name: '默认账本',
              currencyCode: const Value('CNY'),
              timeZoneId: timeZoneId,
              isDefault: const Value(true),
              createdAtMs: now,
              updatedAtMs: now,
            ),
            mode: InsertMode.insertOrIgnore,
          );
      await _database
          .into(_database.accounts)
          .insert(
            AccountsCompanion.insert(
              id: defaultAccountId,
              ledgerId: defaultLedgerId,
              name: '默认账户',
              normalizedName: '默认账户',
              accountType: const Value('cash'),
              openingBalanceMinor: const Value(0),
              sortOrder: const Value(0),
              enabled: const Value(true),
              createdAtMs: now,
              updatedAtMs: now,
            ),
            mode: InsertMode.insertOrIgnore,
          );
      for (var index = 0; index < _defaultCategories.length; index++) {
        final category = _defaultCategories[index];
        await _database
            .into(_database.categories)
            .insert(
              CategoriesCompanion.insert(
                id: category.$1,
                ledgerId: defaultLedgerId,
                categoryType: category.$2,
                name: category.$3,
                normalizedName: category.$3.toLowerCase(),
                sortOrder: Value(index),
                enabled: const Value(true),
                systemKey: Value(category.$4),
                createdAtMs: now,
                updatedAtMs: now,
              ),
              mode: InsertMode.insertOrIgnore,
            );
      }
    });
  }
}
