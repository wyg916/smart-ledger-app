import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/app/app.dart';
import 'package:smart_ledger/core/database/database_providers.dart';
import 'package:smart_ledger/core/database/local_ledger_bootstrapper.dart';
import 'package:smart_ledger/core/time/ledger_time.dart';
import 'package:smart_ledger/features/analytics/domain/ledger_analytics.dart';
import 'package:smart_ledger/features/budgets/domain/ledger_budget.dart';
import 'package:smart_ledger/features/categories/domain/ledger_category.dart';
import 'package:smart_ledger/features/transactions/domain/ledger_transaction.dart';

import '../../support/ledger_test_harness.dart';

void main() {
  Future<LedgerTestHarness> pumpApp(
    WidgetTester tester, {
    AnalyticsRepository? analytics,
  }) async {
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
          if (analytics != null)
            analyticsRepositoryProvider.overrideWithValue(analytics),
        ],
        child: const SmartLedgerApp(),
      ),
    );
    await tester.pumpAndSettle();
    return harness;
  }

  Future<void> disposeApp(
    WidgetTester tester,
    LedgerTestHarness harness,
  ) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
    await harness.close();
  }

  testWidgets('budget page shows empty state and creates a total budget', (
    tester,
  ) async {
    final harness = await pumpApp(tester);
    await tester.tap(find.byKey(const Key('budgets-action')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('empty-budgets')), findsOneWidget);
    await tester.tap(find.byKey(const Key('add-budget')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('budget-amount')), '1000.00');
    await tester.tap(find.byKey(const Key('save-budget')));
    await tester.pumpAndSettle();
    expect(find.textContaining('已用 0.00 / 1000.00'), findsOneWidget);
    expect(find.text('正常'), findsOneWidget);
    await disposeApp(tester, harness);
  });

  testWidgets('duplicate budget validation is visible in the form', (
    tester,
  ) async {
    final harness = await pumpApp(tester);
    await harness.budgets.create(
      scope: BudgetScope.total,
      month: const LedgerMonth(2026, 8),
      amountMinor: 100,
    );
    await tester.tap(find.byKey(const Key('budgets-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-budget')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('budget-amount')), '2.00');
    await tester.tap(find.byKey(const Key('save-budget')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('budget-form-error')), findsOneWidget);
    expect(find.text('该月份预算已存在'), findsOneWidget);
    await disposeApp(tester, harness);
  });

  testWidgets('budget detail shows overrun and supports edit and disabling', (
    tester,
  ) async {
    final harness = await pumpApp(tester);
    final category = await harness.categories.create(
      name: 'Widget支出',
      type: CategoryType.expense,
    );
    final budgetId = await harness.budgets.create(
      scope: BudgetScope.total,
      month: const LedgerMonth(2026, 8),
      amountMinor: 100,
    );
    await harness.transactions.create(
      type: LedgerTransactionType.expense,
      accountId: defaultAccountId,
      categoryId: category,
      amountMinor: 150,
      occurredAtUtc: DateTime.utc(2026, 8, 3),
      timeZoneId: 'Asia/Shanghai',
    );
    await tester.tap(find.byKey(const Key('budgets-action')));
    await tester.pumpAndSettle();
    expect(find.textContaining('已超支 0.50'), findsOneWidget);
    await tester.tap(find.byKey(Key('budget-$budgetId')));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.byKey(const Key('budget-overrun')).evaluate().isNotEmpty) break;
    }
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('超支：0.50'), findsOneWidget);
    await tester.tap(find.byKey(const Key('edit-budget')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('budget-amount')), '2.00');
    await tester.tap(find.byKey(const Key('save-budget')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('超支：0.00'), findsOneWidget);
    await tester.tap(find.byKey(const Key('budget-active')));
    await tester.pump(const Duration(milliseconds: 500));
    expect((await harness.budgets.getById(budgetId))!.isActive, isFalse);
    await disposeApp(tester, harness);
  });

  testWidgets(
    'analytics shows empty, populated summaries, trend and month switch',
    (tester) async {
      final harness = await pumpApp(tester);
      await tester.tap(find.byKey(const Key('analytics-action')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('empty-analytics')), findsOneWidget);
      expect(find.byKey(const Key('empty-trend')), findsOneWidget);
      final expense = await harness.categories.create(
        name: 'Widget排行',
        type: CategoryType.expense,
      );
      await harness.transactions.create(
        type: LedgerTransactionType.expense,
        accountId: defaultAccountId,
        categoryId: expense,
        amountMinor: 1234,
        occurredAtUtc: DateTime.utc(2026, 8, 3),
        timeZoneId: 'Asia/Shanghai',
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('analytics-expense')), findsOneWidget);
      expect(find.text('12.34'), findsWidgets);
      expect(find.text('Widget排行'), findsOneWidget);
      await tester.tap(find.byKey(const Key('analytics-next-month')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('empty-analytics')), findsOneWidget);
      await disposeApp(tester, harness);
    },
  );

  testWidgets('analytics error state is explicit', (tester) async {
    final harness = await pumpApp(tester, analytics: _FailingAnalytics());
    await tester.tap(find.byKey(const Key('analytics-action')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('analytics-error')), findsOneWidget);
    await disposeApp(tester, harness);
  });
}

final class _FailingAnalytics implements AnalyticsRepository {
  @override
  Stream<AnalyticsSnapshot> watch(AnalyticsFilter filter) =>
      Stream.error(StateError('synthetic analytics failure'));
}
