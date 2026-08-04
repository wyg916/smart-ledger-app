import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/core/database/app_database.dart';
import 'package:smart_ledger/core/database/local_ledger_bootstrapper.dart';
import 'package:smart_ledger/core/time/ledger_time.dart';
import 'package:smart_ledger/features/accounts/data/drift_account_repository.dart';
import 'package:smart_ledger/features/accounts/domain/ledger_account.dart';
import 'package:smart_ledger/features/categories/data/drift_category_repository.dart';
import 'package:smart_ledger/features/categories/domain/ledger_category.dart';
import 'package:smart_ledger/features/transactions/data/drift_transaction_repository.dart';
import 'package:smart_ledger/features/transactions/domain/ledger_transaction.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

import '../../support/ledger_test_harness.dart';

void main() {
  test(
    'schema 2 to 4 preserves all P1B facts and creates new tables empty',
    () async {
      final directory = await Directory.systemTemp.createTemp('schema-2-to-3-');
      final file = File('${directory.path}/ledger.sqlite');
      final clock = MutableTestClock(DateTime.utc(2026, 8, 3, 8));
      final ids = CountingUuidGenerator();
      final source = AppDatabase(NativeDatabase(file));
      await LocalLedgerBootstrapper(
        source,
        clock,
        const FixedLedgerTimeZone('Asia/Shanghai'),
      ).initialize();
      final accounts = DriftAccountRepository(source, clock, ids);
      final categories = DriftCategoryRepository(source, clock, ids);
      final transactions = DriftTransactionRepository(source, clock, ids);
      final accountId = await accounts.create(
        name: '迁移账户',
        type: AccountType.bank,
        openingBalanceMinor: 12345,
      );
      final expenseId = await categories.create(
        name: '迁移支出',
        type: CategoryType.expense,
      );
      final incomeId = await categories.create(
        name: '迁移收入',
        type: CategoryType.income,
      );
      final keptId = await transactions.create(
        type: LedgerTransactionType.income,
        accountId: accountId,
        categoryId: incomeId,
        amountMinor: 5000,
        occurredAtUtc: DateTime.utc(2026, 8, 3),
        timeZoneId: 'Asia/Shanghai',
      );
      final deletedId = await transactions.create(
        type: LedgerTransactionType.expense,
        accountId: accountId,
        categoryId: expenseId,
        amountMinor: 700,
        occurredAtUtc: DateTime.utc(2026, 8, 3),
        timeZoneId: 'Asia/Shanghai',
      );
      await transactions.delete(deletedId);
      final beforeCounts = await _counts(source);
      final beforeBalance = (await accounts.getById(
        accountId,
      ))!.currentBalanceMinor;
      final keptBefore = await (source.select(
        source.ledgerTransactions,
      )..where((row) => row.id.equals(keptId))).getSingle();
      final deletedBefore = await (source.select(
        source.ledgerTransactions,
      )..where((row) => row.id.equals(deletedId))).getSingle();
      await source.close();

      final raw = sqlite.sqlite3.open(file.path);
      raw.execute('DROP TABLE budgets');
      raw.execute('PRAGMA user_version = 2');
      raw.close();

      final upgraded = AppDatabase(NativeDatabase(file));
      expect(await upgraded.ping(), 1);
      expect(await _counts(upgraded), beforeCounts);
      final upgradedAccounts = DriftAccountRepository(upgraded, clock, ids);
      expect(
        (await upgradedAccounts.getById(accountId))!.currentBalanceMinor,
        beforeBalance,
      );
      final keptAfter = await (upgraded.select(
        upgraded.ledgerTransactions,
      )..where((row) => row.id.equals(keptId))).getSingle();
      final deletedAfter = await (upgraded.select(
        upgraded.ledgerTransactions,
      )..where((row) => row.id.equals(deletedId))).getSingle();
      expect(keptAfter.amountMinor, keptBefore.amountMinor);
      expect(keptAfter.version, keptBefore.version);
      expect(keptAfter.deletedAtMs, keptBefore.deletedAtMs);
      expect(deletedAfter.amountMinor, deletedBefore.amountMinor);
      expect(deletedAfter.version, deletedBefore.version);
      expect(deletedAfter.deletedAtMs, deletedBefore.deletedAtMs);
      expect(await upgraded.select(upgraded.budgets).get(), isEmpty);
      expect(
        await upgraded.select(upgraded.analyticsEventQueue).get(),
        isEmpty,
      );
      expect(
        await upgraded.customSelect('PRAGMA foreign_key_check').get(),
        isEmpty,
      );
      final version = await upgraded
          .customSelect('PRAGMA user_version')
          .getSingle();
      expect(version.read<int>('user_version'), 4);
      await upgraded.close();
      await directory.delete(recursive: true);
    },
  );

  test(
    'schema 3 to 4 preserves ledger facts and creates an empty analytics queue',
    () async {
      final directory = await Directory.systemTemp.createTemp('schema-3-to-4-');
      final file = File('${directory.path}/ledger.sqlite');
      final clock = MutableTestClock(DateTime.utc(2026, 8, 3, 8));
      final ids = CountingUuidGenerator();
      final source = AppDatabase(NativeDatabase(file));
      await LocalLedgerBootstrapper(
        source,
        clock,
        const FixedLedgerTimeZone('Asia/Shanghai'),
      ).initialize();
      final categories = DriftCategoryRepository(source, clock, ids);
      final transactions = DriftTransactionRepository(source, clock, ids);
      final categoryId = await categories.create(
        name: 'P1D 迁移分类',
        type: CategoryType.expense,
      );
      final transactionId = await transactions.create(
        type: LedgerTransactionType.expense,
        accountId: defaultAccountId,
        categoryId: categoryId,
        amountMinor: 1234,
        occurredAtUtc: DateTime.utc(2026, 8, 3),
        timeZoneId: 'Asia/Shanghai',
      );
      await source.close();

      final raw = sqlite.sqlite3.open(file.path);
      raw.execute('DROP TABLE analytics_event_queue');
      raw.execute('PRAGMA user_version = 3');
      raw.close();

      final upgraded = AppDatabase(NativeDatabase(file));
      expect(
        (await upgraded.select(upgraded.ledgerTransactions).get()).map(
          (row) => row.id,
        ),
        contains(transactionId),
      );
      expect(
        await upgraded.select(upgraded.analyticsEventQueue).get(),
        isEmpty,
      );
      final version = await upgraded
          .customSelect('PRAGMA user_version')
          .getSingle();
      expect(version.read<int>('user_version'), 4);
      expect(
        await upgraded.customSelect('PRAGMA foreign_key_check').get(),
        isEmpty,
      );
      await upgraded.close();
      await directory.delete(recursive: true);
    },
  );
}

Future<(int, int, int)> _counts(AppDatabase database) async {
  final accounts = await database.select(database.accounts).get();
  final categories = await database.select(database.categories).get();
  final transactions = await database.select(database.ledgerTransactions).get();
  return (accounts.length, categories.length, transactions.length);
}
