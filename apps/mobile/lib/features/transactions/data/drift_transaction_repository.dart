import 'package:drift/drift.dart';
import 'package:smart_ledger/core/database/app_database.dart'
    hide LedgerTransaction;
import 'package:smart_ledger/core/database/entity_id.dart';
import 'package:smart_ledger/core/database/local_ledger_bootstrapper.dart';
import 'package:smart_ledger/core/errors/ledger_exception.dart';
import 'package:smart_ledger/core/money/money.dart';
import 'package:smart_ledger/core/time/ledger_time.dart';
import 'package:smart_ledger/core/validation/ledger_validation.dart';
import 'package:smart_ledger/features/transactions/domain/ledger_transaction.dart';

final class DriftTransactionRepository implements TransactionRepository {
  const DriftTransactionRepository(this._database, this._clock, this._ids);

  final AppDatabase _database;
  final LedgerClock _clock;
  final EntityIdGenerator _ids;

  @override
  Stream<List<LedgerTransaction>> watch(TransactionFilter filter) {
    final source = _database.alias(_database.accounts, 'source_account');
    final target = _database.alias(_database.accounts, 'target_account');
    final category = _database.alias(
      _database.categories,
      'transaction_category',
    );
    final query = _database.select(_database.ledgerTransactions).join([
      innerJoin(
        source,
        source.id.equalsExp(_database.ledgerTransactions.accountId),
      ),
      leftOuterJoin(
        target,
        target.id.equalsExp(_database.ledgerTransactions.toAccountId),
      ),
      leftOuterJoin(
        category,
        category.id.equalsExp(_database.ledgerTransactions.categoryId),
      ),
    ]);
    var predicate =
        _database.ledgerTransactions.deletedAtMs.isNull() &
        _database.ledgerTransactions.occurredAtUtcMs.isBiggerOrEqualValue(
          filter.startUtc.toUtc().millisecondsSinceEpoch,
        ) &
        _database.ledgerTransactions.occurredAtUtcMs.isSmallerThanValue(
          filter.endUtcExclusive.toUtc().millisecondsSinceEpoch,
        );
    if (filter.accountId case final accountId?) {
      predicate =
          predicate &
          (_database.ledgerTransactions.accountId.equals(accountId) |
              _database.ledgerTransactions.toAccountId.equals(accountId));
    }
    if (filter.categoryId case final categoryId?) {
      predicate =
          predicate &
          _database.ledgerTransactions.categoryId.equals(categoryId);
    }
    query
      ..where(predicate)
      ..orderBy([
        OrderingTerm.desc(_database.ledgerTransactions.occurredAtUtcMs),
        OrderingTerm.desc(_database.ledgerTransactions.createdAtMs),
      ]);
    return query.watch().map(
      (rows) => rows
          .map(
            (row) => _mapJoined(
              row,
              source: source,
              target: target,
              category: category,
            ),
          )
          .toList(growable: false),
    );
  }

  @override
  Future<LedgerTransaction?> getById(String id) async {
    final source = _database.alias(_database.accounts, 'source_account');
    final target = _database.alias(_database.accounts, 'target_account');
    final category = _database.alias(
      _database.categories,
      'transaction_category',
    );
    final query =
        _database.select(_database.ledgerTransactions).join([
          innerJoin(
            source,
            source.id.equalsExp(_database.ledgerTransactions.accountId),
          ),
          leftOuterJoin(
            target,
            target.id.equalsExp(_database.ledgerTransactions.toAccountId),
          ),
          leftOuterJoin(
            category,
            category.id.equalsExp(_database.ledgerTransactions.categoryId),
          ),
        ])..where(
          _database.ledgerTransactions.id.equals(id) &
              _database.ledgerTransactions.deletedAtMs.isNull(),
        );
    final row = await query.getSingleOrNull();
    return row == null
        ? null
        : _mapJoined(row, source: source, target: target, category: category);
  }

  @override
  Future<String> create({
    required LedgerTransactionType type,
    required String accountId,
    String? toAccountId,
    String? categoryId,
    required int amountMinor,
    required DateTime occurredAtUtc,
    required String timeZoneId,
    String? note,
  }) async {
    Money.fromMinor(amountMinor);
    if (amountMinor <= 0) {
      throw const LedgerException('MONEY_NOT_POSITIVE', '金额必须大于零');
    }
    final id = _ids.next();
    final now = _clock.nowUtc().millisecondsSinceEpoch;
    await _database.transaction(() async {
      await _validateReferences(type, accountId, toAccountId, categoryId);
      await _database
          .into(_database.ledgerTransactions)
          .insert(
            LedgerTransactionsCompanion.insert(
              id: id,
              ledgerId: defaultLedgerId,
              transactionType: type.name,
              accountId: accountId,
              toAccountId: Value(
                type == LedgerTransactionType.transfer ? toAccountId : null,
              ),
              categoryId: Value(
                type == LedgerTransactionType.transfer ? null : categoryId,
              ),
              amountMinor: amountMinor,
              occurredAtUtcMs: occurredAtUtc.toUtc().millisecondsSinceEpoch,
              timeZoneId: requireTimeZoneId(timeZoneId),
              note: Value(normalizedOptionalText(note, maxLength: 500)),
              createdAtMs: now,
              updatedAtMs: now,
            ),
          );
    });
    return id;
  }

  @override
  Future<void> update({
    required String id,
    required LedgerTransactionType type,
    required String accountId,
    String? toAccountId,
    String? categoryId,
    required int amountMinor,
    required DateTime occurredAtUtc,
    required String timeZoneId,
    String? note,
  }) async {
    Money.fromMinor(amountMinor);
    if (amountMinor <= 0) {
      throw const LedgerException('MONEY_NOT_POSITIVE', '金额必须大于零');
    }
    await _database.transaction(() async {
      final current = await (_database.select(
        _database.ledgerTransactions,
      )..where((row) => row.id.equals(id))).getSingleOrNull();
      if (current == null || current.deletedAtMs != null) {
        throw const LedgerException('TRANSACTION_NOT_FOUND', '交易不存在');
      }
      await _validateReferences(type, accountId, toAccountId, categoryId);
      await (_database.update(
        _database.ledgerTransactions,
      )..where((row) => row.id.equals(id))).write(
        LedgerTransactionsCompanion(
          transactionType: Value(type.name),
          accountId: Value(accountId),
          toAccountId: Value(
            type == LedgerTransactionType.transfer ? toAccountId : null,
          ),
          categoryId: Value(
            type == LedgerTransactionType.transfer ? null : categoryId,
          ),
          amountMinor: Value(amountMinor),
          occurredAtUtcMs: Value(occurredAtUtc.toUtc().millisecondsSinceEpoch),
          timeZoneId: Value(requireTimeZoneId(timeZoneId)),
          note: Value(normalizedOptionalText(note, maxLength: 500)),
          updatedAtMs: Value(_clock.nowUtc().millisecondsSinceEpoch),
          version: Value(current.version + 1),
          syncStatus: const Value('pending'),
        ),
      );
    });
  }

  @override
  Future<void> delete(String id) async {
    final current = await (_database.select(
      _database.ledgerTransactions,
    )..where((row) => row.id.equals(id))).getSingleOrNull();
    if (current == null || current.deletedAtMs != null) {
      throw const LedgerException('TRANSACTION_NOT_FOUND', '交易不存在');
    }
    final now = _clock.nowUtc().millisecondsSinceEpoch;
    await (_database.update(
      _database.ledgerTransactions,
    )..where((row) => row.id.equals(id))).write(
      LedgerTransactionsCompanion(
        deletedAtMs: Value(now),
        updatedAtMs: Value(now),
        version: Value(current.version + 1),
        syncStatus: const Value('pending'),
      ),
    );
  }

  Future<void> _validateReferences(
    LedgerTransactionType type,
    String accountId,
    String? toAccountId,
    String? categoryId,
  ) async {
    final account =
        await (_database.select(_database.accounts)..where(
              (row) => row.id.equals(accountId) & row.deletedAtMs.isNull(),
            ))
            .getSingleOrNull();
    if (account == null || !account.enabled) {
      throw const LedgerException('ACCOUNT_DISABLED', '请选择有效账户');
    }
    if (type == LedgerTransactionType.transfer) {
      if (toAccountId == null || toAccountId == accountId) {
        throw const LedgerException(
          'TRANSFER_ACCOUNT_INVALID',
          '转账目标账户必须与来源账户不同',
        );
      }
      final target =
          await (_database.select(_database.accounts)..where(
                (row) => row.id.equals(toAccountId) & row.deletedAtMs.isNull(),
              ))
              .getSingleOrNull();
      if (target == null ||
          !target.enabled ||
          target.ledgerId != account.ledgerId) {
        throw const LedgerException(
          'TRANSFER_ACCOUNT_INVALID',
          '请选择同账本的有效目标账户',
        );
      }
      if (categoryId != null) {
        throw const LedgerException('TRANSFER_CATEGORY_INVALID', '转账不能选择收支分类');
      }
      return;
    }
    if (categoryId == null) {
      throw const LedgerException('CATEGORY_REQUIRED', '请选择分类');
    }
    final category =
        await (_database.select(_database.categories)..where(
              (row) => row.id.equals(categoryId) & row.deletedAtMs.isNull(),
            ))
            .getSingleOrNull();
    if (category == null || !category.enabled) {
      throw const LedgerException('CATEGORY_DISABLED', '请选择有效分类');
    }
    if (category.categoryType != type.name) {
      throw const LedgerException('CATEGORY_TYPE_MISMATCH', '分类类型与交易类型不一致');
    }
  }

  LedgerTransaction _mapJoined(
    TypedResult row, {
    required $AccountsTable source,
    required $AccountsTable target,
    required $CategoriesTable category,
  }) {
    final transaction = row.readTable(_database.ledgerTransactions);
    final sourceAccount = row.readTable(source);
    final targetAccount = row.readTableOrNull(target);
    final transactionCategory = row.readTableOrNull(category);
    return LedgerTransaction(
      id: transaction.id,
      ledgerId: transaction.ledgerId,
      type: LedgerTransactionType.fromDatabase(transaction.transactionType),
      accountId: transaction.accountId,
      accountName: sourceAccount.name,
      toAccountId: transaction.toAccountId,
      toAccountName: targetAccount?.name,
      categoryId: transaction.categoryId,
      categoryName: transactionCategory?.name,
      amountMinor: transaction.amountMinor,
      occurredAtUtc: fromUtcEpochMilliseconds(transaction.occurredAtUtcMs),
      timeZoneId: transaction.timeZoneId,
      note: transaction.note,
      version: transaction.version,
    );
  }
}
