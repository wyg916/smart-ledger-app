import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/core/database/app_database.dart'
    hide LedgerTransaction;
import 'package:smart_ledger/core/database/local_ledger_bootstrapper.dart';
import 'package:smart_ledger/core/errors/ledger_exception.dart';
import 'package:smart_ledger/core/time/ledger_time.dart';
import 'package:smart_ledger/features/accounts/domain/ledger_account.dart';
import 'package:smart_ledger/features/categories/domain/ledger_category.dart';
import 'package:smart_ledger/features/transactions/domain/ledger_transaction.dart';

import '../../support/ledger_test_harness.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late LedgerTestHarness harness;

  setUp(() async {
    harness = await LedgerTestHarness.create();
  });

  tearDown(() => harness.close());

  test(
    'creates schema version 2 with foreign keys and required tables',
    () async {
      expect(harness.database.schemaVersion, AppDatabase.currentSchemaVersion);
      expect(await harness.database.ping(), 1);
      expect(await harness.database.foreignKeysEnabled(), isTrue);
      final tables = await harness.database
          .customSelect("SELECT name FROM sqlite_master WHERE type = 'table'")
          .get();
      final names = tables.map((row) => row.read<String>('name')).toSet();
      expect(
        names,
        containsAll([
          'ledgers',
          'accounts',
          'categories',
          'transactions',
          'app_settings',
        ]),
      );
    },
  );

  test('migrates the empty P1A schema version 1 to schema version 2', () async {
    final directory = await Directory.systemTemp.createTemp(
      'smart-ledger-migration-',
    );
    final file = File('${directory.path}/migration.sqlite');
    final old = AppDatabase(NativeDatabase(file));
    await old.customStatement('DROP TABLE app_settings');
    await old.customStatement('DROP TABLE transactions');
    await old.customStatement('DROP TABLE categories');
    await old.customStatement('DROP TABLE accounts');
    await old.customStatement('DROP TABLE ledgers');
    await old.customStatement('PRAGMA user_version = 1');
    await old.close();

    final upgraded = AppDatabase(NativeDatabase(file));
    expect(await upgraded.ping(), 1);
    final tables = await upgraded
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'transactions'",
        )
        .get();
    expect(tables, hasLength(1));
    await upgraded.close();
    await directory.delete(recursive: true);
  });

  test('foreign keys reject transactions with missing references', () async {
    expect(
      () => harness.database
          .into(harness.database.ledgerTransactions)
          .insert(
            LedgerTransactionsCompanion.insert(
              id: '20000000-0000-4000-8000-000000000001',
              ledgerId: defaultLedgerId,
              transactionType: 'expense',
              accountId: 'missing-account',
              categoryId: const Value('missing-category'),
              amountMinor: 1,
              occurredAtUtcMs: 1,
              timeZoneId: 'Asia/Shanghai',
              createdAtMs: 1,
              updatedAtMs: 1,
            ),
          ),
      throwsA(anything),
    );
  });

  test('account CRUD uses UUID and disabling preserves history', () async {
    final id = await harness.accounts.create(
      name: '现金',
      type: AccountType.cash,
      openingBalanceMinor: 10000,
    );
    expect(id, matches(RegExp(r'^[0-9a-f-]{36}$')));
    await harness.accounts.update(
      id: id,
      name: '日常现金',
      type: AccountType.wallet,
      openingBalanceMinor: 9000,
    );
    var account = await harness.accounts.getById(id);
    expect(account?.name, '日常现金');
    expect(account?.version, 2);
    await harness.accounts.setEnabled(id, false);
    account = await harness.accounts.getById(id);
    expect(account?.enabled, isFalse);
    expect(
      (await harness.accounts.listEnabled()).map((item) => item.id),
      isNot(contains(id)),
    );
  });

  test('category CRUD enforces type and disabling preserves row', () async {
    final id = await harness.categories.create(
      name: '测试餐饮',
      type: CategoryType.expense,
    );
    await harness.categories.update(id: id, name: '测试用餐');
    var category = await harness.categories.getById(id);
    expect(category?.name, '测试用餐');
    expect(category?.type, CategoryType.expense);
    expect(category?.version, 2);
    await harness.categories.setEnabled(id, false);
    category = await harness.categories.getById(id);
    expect(category?.enabled, isFalse);
  });

  test(
    'income and expense CRUD, versioning, filtering, and soft delete are correct',
    () async {
      final expenseCategory = await harness.categories.create(
        name: '虚构支出',
        type: CategoryType.expense,
      );
      final incomeCategory = await harness.categories.create(
        name: '虚构收入',
        type: CategoryType.income,
      );
      final account = await harness.accounts.create(
        name: '测试账户',
        type: AccountType.bank,
        openingBalanceMinor: 0,
      );
      final start = DateTime.utc(2026, 8, 1);
      final end = DateTime.utc(2026, 9, 1);
      final expenseId = await harness.transactions.create(
        type: LedgerTransactionType.expense,
        accountId: account,
        categoryId: expenseCategory,
        amountMinor: 3500,
        occurredAtUtc: start,
        timeZoneId: 'Asia/Shanghai',
        note: '虚构午餐',
      );
      await harness.transactions.create(
        type: LedgerTransactionType.income,
        accountId: account,
        categoryId: incomeCategory,
        amountMinor: 100000,
        occurredAtUtc: end.subtract(const Duration(milliseconds: 1)),
        timeZoneId: 'Asia/Shanghai',
      );
      await harness.transactions.create(
        type: LedgerTransactionType.income,
        accountId: account,
        categoryId: incomeCategory,
        amountMinor: 999,
        occurredAtUtc: end,
        timeZoneId: 'Asia/Shanghai',
      );

      var entries = await harness.transactions
          .watch(
            TransactionFilter(
              startUtc: start,
              endUtcExclusive: end,
              accountId: account,
            ),
          )
          .first;
      expect(entries, hasLength(2));
      expect(summarizeTransactions(entries).incomeMinor, 100000);
      expect(summarizeTransactions(entries).expenseMinor, 3500);

      harness.clock.value = DateTime.utc(2026, 8, 4);
      await harness.transactions.update(
        id: expenseId,
        type: LedgerTransactionType.expense,
        accountId: account,
        categoryId: expenseCategory,
        amountMinor: 4000,
        occurredAtUtc: start,
        timeZoneId: 'Asia/Shanghai',
        note: '已修改',
      );
      expect((await harness.transactions.getById(expenseId))?.version, 2);

      await harness.transactions.delete(expenseId);
      entries = await harness.transactions
          .watch(TransactionFilter(startUtc: start, endUtcExclusive: end))
          .first;
      expect(entries, hasLength(1));
      expect(summarizeTransactions(entries).expenseMinor, 0);
      final deleted = await (harness.database.select(
        harness.database.ledgerTransactions,
      )..where((row) => row.id.equals(expenseId))).getSingle();
      expect(deleted.deletedAtMs, isNotNull);
      expect(deleted.version, 3);
    },
  );

  test(
    'category type and disabled account/category rules are enforced while history remains readable',
    () async {
      final expenseCategory = await harness.categories.create(
        name: '历史支出',
        type: CategoryType.expense,
      );
      final account = await harness.accounts.create(
        name: '历史账户',
        type: AccountType.cash,
        openingBalanceMinor: 0,
      );
      final id = await harness.transactions.create(
        type: LedgerTransactionType.expense,
        accountId: account,
        categoryId: expenseCategory,
        amountMinor: 500,
        occurredAtUtc: DateTime.utc(2026, 8, 3),
        timeZoneId: 'Asia/Shanghai',
      );
      await harness.accounts.setEnabled(account, false);
      await harness.categories.setEnabled(expenseCategory, false);
      expect((await harness.transactions.getById(id))?.accountName, '历史账户');
      expect((await harness.transactions.getById(id))?.categoryName, '历史支出');

      expect(
        () => harness.transactions.create(
          type: LedgerTransactionType.expense,
          accountId: account,
          categoryId: expenseCategory,
          amountMinor: 1,
          occurredAtUtc: DateTime.utc(2026, 8, 3),
          timeZoneId: 'Asia/Shanghai',
        ),
        throwsA(isA<LedgerException>()),
      );
      expect(
        () => harness.transactions.create(
          type: LedgerTransactionType.income,
          accountId: defaultAccountId,
          categoryId: expenseCategory,
          amountMinor: 1,
          occurredAtUtc: DateTime.utc(2026, 8, 3),
          timeZoneId: 'Asia/Shanghai',
        ),
        throwsA(isA<LedgerException>()),
      );
    },
  );

  test(
    'single-row transfer changes both balances and is excluded from summary',
    () async {
      final source = await harness.accounts.create(
        name: '转出账户',
        type: AccountType.cash,
        openingBalanceMinor: 10000,
      );
      final target = await harness.accounts.create(
        name: '转入账户',
        type: AccountType.bank,
        openingBalanceMinor: 0,
      );
      await harness.transactions.create(
        type: LedgerTransactionType.transfer,
        accountId: source,
        toAccountId: target,
        amountMinor: 2500,
        occurredAtUtc: DateTime.utc(2026, 8, 3),
        timeZoneId: 'Asia/Shanghai',
      );
      final entries = await harness.transactions
          .watch(
            TransactionFilter(
              startUtc: DateTime.utc(2026),
              endUtcExclusive: DateTime.utc(2027),
            ),
          )
          .first;
      expect(summarizeTransactions(entries).incomeMinor, 0);
      expect(summarizeTransactions(entries).expenseMinor, 0);
      expect(
        (await harness.accounts.getById(source))?.currentBalanceMinor,
        7500,
      );
      expect(
        (await harness.accounts.getById(target))?.currentBalanceMinor,
        2500,
      );
    },
  );

  test('database close and reopen retains user data', () async {
    final directory = await Directory.systemTemp.createTemp(
      'smart-ledger-persistence-',
    );
    final file = File('${directory.path}/ledger.sqlite');
    final first = AppDatabase(NativeDatabase(file));
    final clock = FixedLedgerClock(DateTime.utc(2026, 8, 3));
    await LocalLedgerBootstrapper(
      first,
      clock,
      const FixedLedgerTimeZone('Asia/Shanghai'),
    ).initialize();
    await first
        .into(first.appSettings)
        .insert(
          AppSettingsCompanion.insert(
            key: 'persistence_test',
            valueType: 'string',
            valueText: const Value('retained'),
            updatedAtMs: 1,
          ),
        );
    await first.close();

    final reopened = AppDatabase(NativeDatabase(file));
    final row = await (reopened.select(
      reopened.appSettings,
    )..where((item) => item.key.equals('persistence_test'))).getSingle();
    expect(row.valueText, 'retained');
    await reopened.close();
    await directory.delete(recursive: true);
  });
}
