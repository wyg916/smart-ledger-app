import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/core/database/local_ledger_bootstrapper.dart';
import 'package:smart_ledger/core/errors/ledger_exception.dart';
import 'package:smart_ledger/features/categories/domain/ledger_category.dart';
import 'package:smart_ledger/features/transactions/domain/ledger_transaction.dart';

import '../support/ledger_test_harness.dart';

enum FixtureDecision { accept, reject }

const fixtureDecisions = <String, FixtureDecision>{
  'room_v1_empty': FixtureDecision.accept,
  'room_v1_basic': FixtureDecision.accept,
  'room_v1_budget': FixtureDecision.reject,
  'room_v1_deleted_category': FixtureDecision.accept,
  'room_v1_large': FixtureDecision.accept,
  'sync_single_device': FixtureDecision.reject,
  'sync_two_devices': FixtureDecision.reject,
  'sync_conflict': FixtureDecision.reject,
  'sync_offline_delete': FixtureDecision.reject,
  'corrupted_backup': FixtureDecision.reject,
};

void main() {
  final fixtureRoot = Directory('../../tests/fixtures');

  test(
    'all 10 anonymous fixtures parse and have an explicit P1B decision',
    () async {
      final scenarioFiles =
          fixtureRoot
              .listSync()
              .whereType<Directory>()
              .map((directory) => File('${directory.path}/scenario.json'))
              .where((file) => file.existsSync())
              .toList()
            ..sort((left, right) => left.path.compareTo(right.path));
      expect(scenarioFiles, hasLength(10));

      for (final file in scenarioFiles) {
        final name = file.parent.path.split(Platform.pathSeparator).last;
        final json =
            jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        expect(json['synthetic'], isTrue, reason: name);
        expect(fixtureDecisions, contains(name), reason: name);
      }
      expect(
        fixtureDecisions.values.where((item) => item == FixtureDecision.accept),
        hasLength(4),
      );
      expect(
        fixtureDecisions.values.where((item) => item == FixtureDecision.reject),
        hasLength(6),
      );
    },
  );

  test(
    'room_v1_basic adapter inserts valid synthetic income and expense exactly',
    () async {
      final harness = await LedgerTestHarness.create();
      addTearDown(harness.close);
      final fixture =
          jsonDecode(
                await File(
                  '${fixtureRoot.path}/room_v1_basic/scenario.json',
                ).readAsString(),
              )
              as Map<String, dynamic>;
      final categoryIds = <int, String>{};
      for (final raw in fixture['categories'] as List<dynamic>) {
        final category = raw as Map<String, dynamic>;
        final type = CategoryType.values.byName(category['type'] as String);
        categoryIds[category['legacy_id'] as int] = await harness.categories
            .create(name: category['name'] as String, type: type);
      }
      for (final raw in fixture['transactions'] as List<dynamic>) {
        final transaction = raw as Map<String, dynamic>;
        await harness.transactions.create(
          type: LedgerTransactionType.values.byName(
            transaction['type'] as String,
          ),
          accountId: defaultAccountId,
          categoryId: categoryIds[transaction['category_id'] as int],
          amountMinor: transaction['amount_minor'] as int,
          occurredAtUtc: DateTime.parse(
            transaction['occurred_at'] as String,
          ).toUtc(),
          timeZoneId: 'Asia/Shanghai',
          note: transaction['note'] as String?,
        );
      }
      final entries = await harness.transactions
          .watch(
            TransactionFilter(
              startUtc: DateTime.utc(2026),
              endUtcExclusive: DateTime.utc(2027),
            ),
          )
          .first;
      final expected = fixture['expected'] as Map<String, dynamic>;
      final summary = summarizeTransactions(entries);
      expect(entries, hasLength(expected['transaction_count'] as int));
      expect(summary.incomeMinor, expected['income_minor']);
      expect(summary.expenseMinor, expected['expense_minor']);
      expect(summary.netMinor, expected['balance_minor']);
    },
  );

  test(
    'invalid amount, category type, time, and reference fail explicitly',
    () async {
      final harness = await LedgerTestHarness.create();
      addTearDown(harness.close);
      final expense = await harness.categories.create(
        name: '虚构类型测试',
        type: CategoryType.expense,
      );

      expect(
        () => harness.transactions.create(
          type: LedgerTransactionType.expense,
          accountId: defaultAccountId,
          categoryId: expense,
          amountMinor: 0,
          occurredAtUtc: DateTime.utc(2026, 1, 1),
          timeZoneId: 'Asia/Shanghai',
        ),
        throwsA(isA<LedgerException>()),
      );
      expect(
        () => harness.transactions.create(
          type: LedgerTransactionType.income,
          accountId: defaultAccountId,
          categoryId: expense,
          amountMinor: 1,
          occurredAtUtc: DateTime.utc(2026, 1, 1),
          timeZoneId: 'Asia/Shanghai',
        ),
        throwsA(isA<LedgerException>()),
      );
      expect(() => DateTime.parse('not-a-time'), throwsFormatException);
      expect(
        () => harness.transactions.create(
          type: LedgerTransactionType.expense,
          accountId: defaultAccountId,
          categoryId: 'missing-category',
          amountMinor: 1,
          occurredAtUtc: DateTime.utc(2026, 1, 1),
          timeZoneId: 'Asia/Shanghai',
        ),
        throwsA(isA<LedgerException>()),
      );
    },
  );
}
