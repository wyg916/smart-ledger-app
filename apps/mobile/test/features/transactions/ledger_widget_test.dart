import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/app/app.dart';
import 'package:smart_ledger/core/database/database_providers.dart';
import 'package:smart_ledger/core/database/local_ledger_bootstrapper.dart';
import 'package:smart_ledger/core/time/ledger_time.dart';
import 'package:smart_ledger/features/categories/domain/ledger_category.dart';
import 'package:smart_ledger/features/transactions/domain/ledger_transaction.dart';

import '../../support/ledger_test_harness.dart';

void main() {
  Future<LedgerTestHarness> pumpLedger(WidgetTester tester) async {
    final harness = await LedgerTestHarness.create();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(harness.database),
          ledgerClockProvider.overrideWithValue(harness.clock),
          ledgerTimeZoneProvider.overrideWithValue(
            const FixedLedgerTimeZone('Asia/Shanghai'),
          ),
          entityIdGeneratorProvider.overrideWithValue(harness.ids),
        ],
        child: const SmartLedgerApp(),
      ),
    );
    await tester.pumpAndSettle();
    return harness;
  }

  Future<void> disposeLedger(
    WidgetTester tester,
    LedgerTestHarness harness,
  ) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
    await harness.close();
    await tester.pump(const Duration(milliseconds: 1));
  }

  testWidgets('shows the empty ledger state', (tester) async {
    final harness = await pumpLedger(tester);
    expect(find.byKey(const Key('empty-ledger')), findsOneWidget);
    expect(find.byKey(const Key('income-summary')), findsOneWidget);
    expect(find.text('0.00'), findsNWidgets(3));
    await disposeLedger(tester, harness);
  });

  testWidgets(
    'adds income and expense, refreshes list, and shows exact summary',
    (tester) async {
      final harness = await pumpLedger(tester);

      await tester.tap(find.byKey(const Key('add-transaction')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('收入'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('transaction-amount')),
        '1000.00',
      );
      await tester.tap(find.byKey(const Key('save-transaction')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('add-transaction')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('transaction-amount')),
        '35.50',
      );
      await tester.tap(find.byKey(const Key('save-transaction')));
      await tester.pumpAndSettle();

      expect(find.text('+1000.00'), findsOneWidget);
      expect(find.text('-35.50'), findsOneWidget);
      expect(find.text('1000.00'), findsWidgets);
      expect(find.text('35.50'), findsWidgets);
      expect(find.text('964.50'), findsOneWidget);

      await tester.drag(
        find.byKey(const Key('ledger-list')),
        const Offset(0, 280),
      );
      await tester.pumpAndSettle();
      expect(find.text('+1000.00'), findsOneWidget);
      await disposeLedger(tester, harness);
    },
  );

  testWidgets('rejects invalid amount in the transaction form', (tester) async {
    final harness = await pumpLedger(tester);
    await tester.tap(find.byKey(const Key('add-transaction')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('transaction-amount')), '0');
    await tester.tap(find.byKey(const Key('save-transaction')));
    await tester.pump();
    expect(find.text('金额必须大于零'), findsOneWidget);
    await disposeLedger(tester, harness);
  });

  testWidgets('edits a transaction and increments its displayed version', (
    tester,
  ) async {
    final harness = await pumpLedger(tester);
    final category = await harness.categories.create(
      name: '编辑分类',
      type: CategoryType.expense,
    );
    final id = await harness.transactions.create(
      type: LedgerTransactionType.expense,
      accountId: defaultAccountId,
      categoryId: category,
      amountMinor: 100,
      occurredAtUtc: DateTime.utc(2026, 8, 3),
      timeZoneId: 'Asia/Shanghai',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('transaction-$id')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('edit-transaction')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('transaction-amount')), '2.00');
    await tester.tap(find.byKey(const Key('save-transaction')));
    await tester.pumpAndSettle();
    expect(find.text('¥2.00'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    await disposeLedger(tester, harness);
  });

  testWidgets(
    'requires confirmation and removes a deleted transaction from list and summary',
    (tester) async {
      final harness = await pumpLedger(tester);
      final category = await harness.categories.create(
        name: '删除分类',
        type: CategoryType.expense,
      );
      final id = await harness.transactions.create(
        type: LedgerTransactionType.expense,
        accountId: defaultAccountId,
        categoryId: category,
        amountMinor: 880,
        occurredAtUtc: DateTime.utc(2026, 8, 3),
        timeZoneId: 'Asia/Shanghai',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('transaction-$id')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('detail-delete-transaction')));
      await tester.pumpAndSettle();
      expect(find.text('确认删除？'), findsOneWidget);
      await tester.tap(find.byKey(const Key('confirm-detail-delete')));
      await tester.pumpAndSettle();
      expect(find.byKey(Key('transaction-$id')), findsNothing);
      expect(find.byKey(const Key('empty-ledger')), findsOneWidget);
      expect(find.text('0.00'), findsNWidgets(3));
      await disposeLedger(tester, harness);
    },
  );

  testWidgets(
    'disabled account and category do not appear in new transaction choices',
    (tester) async {
      final harness = await pumpLedger(tester);
      final category = await harness.categories.create(
        name: '禁用分类测试',
        type: CategoryType.expense,
      );
      final account = await harness.accounts.create(
        name: '禁用账户测试',
        type: (await harness.accounts.getById(defaultAccountId))!.type,
        openingBalanceMinor: 0,
      );
      await harness.categories.setEnabled(category, false);
      await harness.accounts.setEnabled(account, false);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('add-transaction')));
      await tester.pumpAndSettle();
      expect(find.text('禁用分类测试'), findsNothing);
      expect(find.text('禁用账户测试'), findsNothing);
      await disposeLedger(tester, harness);
    },
  );

  testWidgets(
    'account and category management create records and allow disabling',
    (tester) async {
      final harness = await pumpLedger(tester);
      await tester.tap(find.byKey(const Key('accounts-action')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('add-account')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('account-name')), '现金钱包');
      await tester.enterText(
        find.byKey(const Key('account-opening-balance')),
        '50.00',
      );
      await tester.tap(find.byKey(const Key('save-account')));
      await tester.pumpAndSettle();
      expect(find.text('现金钱包'), findsOneWidget);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('categories-action')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('add-category')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('category-name')), '测试购物');
      await tester.tap(find.byKey(const Key('save-category')));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('测试购物'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('测试购物'), findsOneWidget);
      await disposeLedger(tester, harness);
    },
  );
}
