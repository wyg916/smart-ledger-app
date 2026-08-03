import 'package:drift/drift.dart';
import 'package:smart_ledger/core/database/app_database.dart';
import 'package:smart_ledger/core/database/entity_id.dart';
import 'package:smart_ledger/core/database/local_ledger_bootstrapper.dart';
import 'package:smart_ledger/core/errors/ledger_exception.dart';
import 'package:smart_ledger/core/money/money.dart';
import 'package:smart_ledger/core/time/ledger_time.dart';
import 'package:smart_ledger/features/budgets/domain/ledger_budget.dart';

final class DriftBudgetRepository implements BudgetRepository {
  const DriftBudgetRepository(this._database, this._clock, this._ids);

  final AppDatabase _database;
  final LedgerClock _clock;
  final EntityIdGenerator _ids;

  @override
  Stream<List<LedgerBudget>> watchMonth(LedgerMonth month) async* {
    final ledger = await _defaultLedger();
    final range = monthRangeInTimeZone(month, ledger.timeZoneId);
    yield* _database
        .customSelect(
          '''
          SELECT b.*, c.name AS category_name, c.enabled AS category_enabled,
            COALESCE(SUM(CASE
              WHEN t.transaction_type = 'expense'
                AND t.deleted_at_ms IS NULL
                AND t.occurred_at_utc_ms >= ?
                AND t.occurred_at_utc_ms < ?
                AND (b.scope_type = 'total' OR t.category_id = b.category_id)
              THEN t.amount_minor ELSE 0 END), 0) AS used_minor
          FROM budgets b
          LEFT JOIN categories c ON c.id = b.category_id
          LEFT JOIN transactions t ON t.ledger_id = b.ledger_id
          WHERE b.ledger_id = ? AND b.year_month = ?
            AND b.deleted_at_ms IS NULL
          GROUP BY b.id
          ORDER BY CASE b.scope_type WHEN 'total' THEN 0 ELSE 1 END,
            c.sort_order ASC, c.created_at_ms ASC, b.id ASC
          ''',
          variables: [
            Variable.withInt(range.start.millisecondsSinceEpoch),
            Variable.withInt(range.endExclusive.millisecondsSinceEpoch),
            Variable.withString(defaultLedgerId),
            Variable.withString(month.toString()),
          ],
          readsFrom: {
            _database.budgets,
            _database.categories,
            _database.ledgerTransactions,
          },
        )
        .watch()
        .map((rows) => rows.map(_map).toList(growable: false));
  }

  @override
  Future<LedgerBudget?> getById(String id) async {
    final row =
        await (_database.select(_database.budgets)
              ..where((item) => item.id.equals(id) & item.deletedAtMs.isNull()))
            .getSingleOrNull();
    if (row == null) return null;
    final range = monthRangeInTimeZone(
      LedgerMonth.parse(row.yearMonth),
      row.timeZoneId,
    );
    final result = await _database
        .customSelect(
          '''
          SELECT b.*, c.name AS category_name, c.enabled AS category_enabled,
            COALESCE(SUM(CASE
              WHEN t.transaction_type = 'expense' AND t.deleted_at_ms IS NULL
                AND t.occurred_at_utc_ms >= ? AND t.occurred_at_utc_ms < ?
                AND (b.scope_type = 'total' OR t.category_id = b.category_id)
              THEN t.amount_minor ELSE 0 END), 0) AS used_minor
          FROM budgets b
          LEFT JOIN categories c ON c.id = b.category_id
          LEFT JOIN transactions t ON t.ledger_id = b.ledger_id
          WHERE b.id = ? AND b.deleted_at_ms IS NULL
          GROUP BY b.id
          ''',
          variables: [
            Variable.withInt(range.start.millisecondsSinceEpoch),
            Variable.withInt(range.endExclusive.millisecondsSinceEpoch),
            Variable.withString(id),
          ],
          readsFrom: {
            _database.budgets,
            _database.categories,
            _database.ledgerTransactions,
          },
        )
        .getSingleOrNull();
    return result == null ? null : _map(result);
  }

  @override
  Future<String> create({
    required BudgetScope scope,
    required LedgerMonth month,
    required int amountMinor,
    String? categoryId,
  }) async {
    Money.fromMinor(amountMinor);
    if (amountMinor < 0) {
      throw const LedgerException('BUDGET_AMOUNT_INVALID', '预算金额不能小于零');
    }
    final ledger = await _defaultLedger();
    final category = await _validateScope(scope, categoryId);
    await _ensureUnique(scope, month, categoryId);
    final id = _ids.next();
    final now = _clock.nowUtc().millisecondsSinceEpoch;
    await _database
        .into(_database.budgets)
        .insert(
          BudgetsCompanion.insert(
            id: id,
            ledgerId: defaultLedgerId,
            name: scope == BudgetScope.total ? '月度总预算' : category!.name,
            scopeType: scope.name,
            categoryId: Value(categoryId),
            yearMonth: month.toString(),
            amountMinor: amountMinor,
            currencyCode: ledger.currencyCode,
            timeZoneId: ledger.timeZoneId,
            startDateLocal: month.firstLocalDate,
            endDateLocal: month.nextFirstLocalDate,
            createdAtMs: now,
            updatedAtMs: now,
          ),
        );
    return id;
  }

  @override
  Future<void> update({required String id, required int amountMinor}) async {
    Money.fromMinor(amountMinor);
    if (amountMinor < 0) {
      throw const LedgerException('BUDGET_AMOUNT_INVALID', '预算金额不能小于零');
    }
    final current = await _activeRow(id);
    await (_database.update(
      _database.budgets,
    )..where((row) => row.id.equals(id))).write(
      BudgetsCompanion(
        amountMinor: Value(amountMinor),
        updatedAtMs: Value(_clock.nowUtc().millisecondsSinceEpoch),
        version: Value(current.version + 1),
        syncStatus: const Value('pending'),
      ),
    );
  }

  @override
  Future<void> setActive(String id, bool active) async {
    final current = await _activeRow(id);
    await (_database.update(
      _database.budgets,
    )..where((row) => row.id.equals(id))).write(
      BudgetsCompanion(
        isActive: Value(active),
        updatedAtMs: Value(_clock.nowUtc().millisecondsSinceEpoch),
        version: Value(current.version + 1),
        syncStatus: const Value('pending'),
      ),
    );
  }

  @override
  Future<void> delete(String id) async {
    final current = await _activeRow(id);
    final now = _clock.nowUtc().millisecondsSinceEpoch;
    await (_database.update(
      _database.budgets,
    )..where((row) => row.id.equals(id))).write(
      BudgetsCompanion(
        deletedAtMs: Value(now),
        updatedAtMs: Value(now),
        version: Value(current.version + 1),
        syncStatus: const Value('pending'),
      ),
    );
  }

  Future<Ledger> _defaultLedger() async {
    final ledger =
        await (_database.select(_database.ledgers)..where(
              (row) =>
                  row.id.equals(defaultLedgerId) & row.deletedAtMs.isNull(),
            ))
            .getSingleOrNull();
    if (ledger == null) {
      throw const LedgerException('LEDGER_NOT_FOUND', '账本不存在');
    }
    monthRangeInTimeZone(const LedgerMonth(2000, 1), ledger.timeZoneId);
    return ledger;
  }

  Future<Category?> _validateScope(
    BudgetScope scope,
    String? categoryId,
  ) async {
    if (scope == BudgetScope.total) {
      if (categoryId != null) {
        throw const LedgerException('BUDGET_SCOPE_INVALID', '总预算不能选择分类');
      }
      return null;
    }
    if (categoryId == null) {
      throw const LedgerException('BUDGET_CATEGORY_REQUIRED', '请选择支出分类');
    }
    final category =
        await (_database.select(_database.categories)..where(
              (row) =>
                  row.id.equals(categoryId) &
                  row.ledgerId.equals(defaultLedgerId) &
                  row.categoryType.equals('expense') &
                  row.enabled.equals(true) &
                  row.deletedAtMs.isNull(),
            ))
            .getSingleOrNull();
    if (category == null) {
      throw const LedgerException('BUDGET_CATEGORY_INVALID', '请选择启用的支出分类');
    }
    return category;
  }

  Future<void> _ensureUnique(
    BudgetScope scope,
    LedgerMonth month,
    String? categoryId,
  ) async {
    final query = _database.select(_database.budgets)
      ..where(
        (row) =>
            row.ledgerId.equals(defaultLedgerId) &
            row.yearMonth.equals(month.toString()) &
            row.scopeType.equals(scope.name) &
            row.deletedAtMs.isNull(),
      );
    if (categoryId == null) {
      query.where((row) => row.categoryId.isNull());
    } else {
      query.where((row) => row.categoryId.equals(categoryId));
    }
    if (await query.getSingleOrNull() != null) {
      throw const LedgerException('BUDGET_ALREADY_EXISTS', '该月份预算已存在');
    }
  }

  Future<Budget> _activeRow(String id) async {
    final row =
        await (_database.select(_database.budgets)
              ..where((item) => item.id.equals(id) & item.deletedAtMs.isNull()))
            .getSingleOrNull();
    if (row == null) {
      throw const LedgerException('BUDGET_NOT_FOUND', '预算不存在');
    }
    return row;
  }

  LedgerBudget _map(QueryRow row) => LedgerBudget(
    id: row.read<String>('id'),
    ledgerId: row.read<String>('ledger_id'),
    name: row.read<String>('name'),
    scope: BudgetScope.fromDatabase(row.read<String>('scope_type')),
    categoryId: row.readNullable<String>('category_id'),
    categoryName: row.readNullable<String>('category_name'),
    categoryEnabled: row.readNullable<int>('category_enabled') == null
        ? null
        : row.read<int>('category_enabled') == 1,
    month: LedgerMonth.parse(row.read<String>('year_month')),
    amountMinor: row.read<int>('amount_minor'),
    currencyCode: row.read<String>('currency_code'),
    timeZoneId: row.read<String>('time_zone_id'),
    isActive: row.read<int>('is_active') == 1,
    version: row.read<int>('version'),
    usedMinor: row.read<int>('used_minor'),
  );
}
