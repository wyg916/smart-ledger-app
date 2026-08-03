import 'package:drift/drift.dart';
import 'package:smart_ledger/core/database/app_database.dart';
import 'package:smart_ledger/core/database/entity_id.dart';
import 'package:smart_ledger/core/database/local_ledger_bootstrapper.dart';
import 'package:smart_ledger/core/errors/ledger_exception.dart';
import 'package:smart_ledger/core/money/money.dart';
import 'package:smart_ledger/core/time/ledger_time.dart';
import 'package:smart_ledger/core/validation/ledger_validation.dart';
import 'package:smart_ledger/features/accounts/domain/ledger_account.dart';

final class DriftAccountRepository implements AccountRepository {
  const DriftAccountRepository(this._database, this._clock, this._ids);

  final AppDatabase _database;
  final LedgerClock _clock;
  final EntityIdGenerator _ids;

  @override
  Stream<List<LedgerAccount>> watchAll({bool enabledOnly = false}) {
    final enabledClause = enabledOnly ? 'AND a.enabled = 1' : '';
    return _database
        .customSelect(
          '''
      SELECT a.*,
        a.opening_balance_minor + COALESCE(SUM(
          CASE
            WHEN t.transaction_type = 'income' AND t.account_id = a.id THEN t.amount_minor
            WHEN t.transaction_type = 'expense' AND t.account_id = a.id THEN -t.amount_minor
            WHEN t.transaction_type = 'transfer' AND t.account_id = a.id THEN -t.amount_minor
            WHEN t.transaction_type = 'transfer' AND t.to_account_id = a.id THEN t.amount_minor
            ELSE 0
          END
        ), 0) AS current_balance_minor
      FROM accounts a
      LEFT JOIN transactions t
        ON (t.account_id = a.id OR t.to_account_id = a.id)
       AND t.deleted_at_ms IS NULL
      WHERE a.deleted_at_ms IS NULL $enabledClause
      GROUP BY a.id
      ORDER BY a.sort_order ASC, a.created_at_ms ASC
      ''',
          readsFrom: {_database.accounts, _database.ledgerTransactions},
        )
        .watch()
        .map((rows) => rows.map(_mapRow).toList(growable: false));
  }

  @override
  Future<List<LedgerAccount>> listEnabled() =>
      watchAll(enabledOnly: true).first;

  @override
  Future<LedgerAccount?> getById(String id) async {
    final rows = await _database
        .customSelect(
          '''
      SELECT a.*,
        a.opening_balance_minor + COALESCE(SUM(
          CASE
            WHEN t.transaction_type = 'income' AND t.account_id = a.id THEN t.amount_minor
            WHEN t.transaction_type = 'expense' AND t.account_id = a.id THEN -t.amount_minor
            WHEN t.transaction_type = 'transfer' AND t.account_id = a.id THEN -t.amount_minor
            WHEN t.transaction_type = 'transfer' AND t.to_account_id = a.id THEN t.amount_minor
            ELSE 0
          END
        ), 0) AS current_balance_minor
      FROM accounts a
      LEFT JOIN transactions t
        ON (t.account_id = a.id OR t.to_account_id = a.id)
       AND t.deleted_at_ms IS NULL
      WHERE a.id = ? AND a.deleted_at_ms IS NULL
      GROUP BY a.id
      ''',
          variables: [Variable.withString(id)],
          readsFrom: {_database.accounts, _database.ledgerTransactions},
        )
        .get();
    return rows.isEmpty ? null : _mapRow(rows.single);
  }

  @override
  Future<String> create({
    required String name,
    required AccountType type,
    required int openingBalanceMinor,
  }) async {
    Money.fromMinor(openingBalanceMinor);
    final validName = requireName(name, field: '账户名称');
    await _ensureNameAvailable(validName);
    final id = _ids.next();
    final now = _clock.nowUtc().millisecondsSinceEpoch;
    await _database
        .into(_database.accounts)
        .insert(
          AccountsCompanion.insert(
            id: id,
            ledgerId: defaultLedgerId,
            name: validName,
            normalizedName: normalizedName(validName),
            accountType: Value(type.name),
            openingBalanceMinor: Value(openingBalanceMinor),
            createdAtMs: now,
            updatedAtMs: now,
          ),
        );
    return id;
  }

  @override
  Future<void> update({
    required String id,
    required String name,
    required AccountType type,
    required int openingBalanceMinor,
  }) async {
    Money.fromMinor(openingBalanceMinor);
    final validName = requireName(name, field: '账户名称');
    final current = await (_database.select(
      _database.accounts,
    )..where((row) => row.id.equals(id))).getSingleOrNull();
    if (current == null || current.deletedAtMs != null) {
      throw const LedgerException('ACCOUNT_NOT_FOUND', '账户不存在');
    }
    await _ensureNameAvailable(validName, excludingId: id);
    await (_database.update(
      _database.accounts,
    )..where((row) => row.id.equals(id))).write(
      AccountsCompanion(
        name: Value(validName),
        normalizedName: Value(normalizedName(validName)),
        accountType: Value(type.name),
        openingBalanceMinor: Value(openingBalanceMinor),
        updatedAtMs: Value(_clock.nowUtc().millisecondsSinceEpoch),
        version: Value(current.version + 1),
        syncStatus: const Value('pending'),
      ),
    );
  }

  @override
  Future<void> setEnabled(String id, bool enabled) async {
    final current = await (_database.select(
      _database.accounts,
    )..where((row) => row.id.equals(id))).getSingleOrNull();
    if (current == null || current.deletedAtMs != null) {
      throw const LedgerException('ACCOUNT_NOT_FOUND', '账户不存在');
    }
    await (_database.update(
      _database.accounts,
    )..where((row) => row.id.equals(id))).write(
      AccountsCompanion(
        enabled: Value(enabled),
        updatedAtMs: Value(_clock.nowUtc().millisecondsSinceEpoch),
        version: Value(current.version + 1),
        syncStatus: const Value('pending'),
      ),
    );
  }

  Future<void> _ensureNameAvailable(String name, {String? excludingId}) async {
    final normalized = normalizedName(name);
    final query = _database.select(_database.accounts)
      ..where(
        (row) =>
            row.ledgerId.equals(defaultLedgerId) &
            row.normalizedName.equals(normalized) &
            row.deletedAtMs.isNull(),
      );
    final found = await query.get();
    if (found.any((row) => row.id != excludingId)) {
      throw const LedgerException('ACCOUNT_NAME_EXISTS', '账户名称已存在');
    }
  }

  LedgerAccount _mapRow(QueryRow row) {
    return LedgerAccount(
      id: row.read<String>('id'),
      ledgerId: row.read<String>('ledger_id'),
      name: row.read<String>('name'),
      type: AccountType.fromDatabase(row.read<String>('account_type')),
      openingBalanceMinor: row.read<int>('opening_balance_minor'),
      currentBalanceMinor: row.read<int>('current_balance_minor'),
      enabled: row.read<int>('enabled') == 1,
      version: row.read<int>('version'),
      iconCode: row.readNullable<String>('icon_code'),
    );
  }
}
