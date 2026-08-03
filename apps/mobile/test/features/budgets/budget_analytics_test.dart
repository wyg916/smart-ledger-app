import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/core/errors/ledger_exception.dart';
import 'package:smart_ledger/core/time/ledger_time.dart';
import 'package:smart_ledger/features/accounts/domain/ledger_account.dart';
import 'package:smart_ledger/features/analytics/domain/ledger_analytics.dart';
import 'package:smart_ledger/features/budgets/domain/ledger_budget.dart';
import 'package:smart_ledger/features/categories/domain/ledger_category.dart';
import 'package:smart_ledger/features/transactions/domain/ledger_transaction.dart';

import '../../support/ledger_test_harness.dart';

void main() {
  late LedgerTestHarness harness;
  const august = LedgerMonth(2026, 8);

  setUp(() async => harness = await LedgerTestHarness.create());
  tearDown(() => harness.close());

  test('total budget CRUD, active state, tombstone and uniqueness', () async {
    final id = await harness.budgets.create(
      scope: BudgetScope.total,
      month: august,
      amountMinor: 10000,
    );
    expect(
      () => harness.budgets.create(
        scope: BudgetScope.total,
        month: august,
        amountMinor: 1,
      ),
      throwsA(
        isA<LedgerException>().having(
          (error) => error.code,
          'code',
          'BUDGET_ALREADY_EXISTS',
        ),
      ),
    );
    await harness.budgets.update(id: id, amountMinor: 12000);
    var budget = await harness.budgets.getById(id);
    expect(budget?.amountMinor, 12000);
    expect(budget?.version, 2);
    await harness.budgets.setActive(id, false);
    budget = await harness.budgets.getById(id);
    expect(budget?.isActive, isFalse);
    expect(budget?.version, 3);
    await harness.budgets.delete(id);
    expect(await harness.budgets.getById(id), isNull);
    final tombstone = await harness.database
        .select(harness.database.budgets)
        .getSingle();
    expect(tombstone.deletedAtMs, isNotNull);
    expect(tombstone.version, 4);
    expect(
      await harness.budgets.create(
        scope: BudgetScope.total,
        month: august,
        amountMinor: 2,
      ),
      isNot(id),
    );
  });

  test(
    'category budgets coexist, reject duplicate/income/disabled category',
    () async {
      final food = await harness.categories.create(
        name: '预算餐饮',
        type: CategoryType.expense,
      );
      final travel = await harness.categories.create(
        name: '预算交通',
        type: CategoryType.expense,
      );
      final salary = await harness.categories.create(
        name: '预算工资',
        type: CategoryType.income,
      );
      await harness.budgets.create(
        scope: BudgetScope.category,
        month: august,
        categoryId: food,
        amountMinor: 1000,
      );
      await harness.budgets.create(
        scope: BudgetScope.category,
        month: august,
        categoryId: travel,
        amountMinor: 2000,
      );
      expect(await harness.budgets.watchMonth(august).first, hasLength(2));
      expect(
        () => harness.budgets.create(
          scope: BudgetScope.category,
          month: august,
          categoryId: food,
          amountMinor: 3,
        ),
        throwsA(isA<LedgerException>()),
      );
      expect(
        () => harness.budgets.create(
          scope: BudgetScope.category,
          month: august,
          categoryId: salary,
          amountMinor: 3,
        ),
        throwsA(isA<LedgerException>()),
      );
      await harness.categories.setEnabled(travel, false);
      expect(
        () => harness.budgets.create(
          scope: BudgetScope.category,
          month: const LedgerMonth(2026, 9),
          categoryId: travel,
          amountMinor: 3,
        ),
        throwsA(isA<LedgerException>()),
      );
      expect(
        (await harness.budgets.watchMonth(august).first)
            .firstWhere((item) => item.categoryId == travel)
            .categoryName,
        '预算交通',
      );
    },
  );

  test(
    'only live expenses consume total and matching category budgets',
    () async {
      final food = await harness.categories.create(
        name: '消费餐饮',
        type: CategoryType.expense,
      );
      final other = await harness.categories.create(
        name: '消费其他',
        type: CategoryType.expense,
      );
      final income = await harness.categories.create(
        name: '消费收入',
        type: CategoryType.income,
      );
      final target = await harness.accounts.create(
        name: '转账目标',
        type: AccountType.bank,
        openingBalanceMinor: 0,
      );
      await harness.budgets.create(
        scope: BudgetScope.total,
        month: august,
        amountMinor: 1000,
      );
      await harness.budgets.create(
        scope: BudgetScope.category,
        month: august,
        categoryId: food,
        amountMinor: 200,
      );
      final foodTx = await _transaction(
        harness,
        LedgerTransactionType.expense,
        food,
        250,
      );
      final deleted = await _transaction(
        harness,
        LedgerTransactionType.expense,
        food,
        50,
      );
      await harness.transactions.delete(deleted);
      await _transaction(harness, LedgerTransactionType.expense, other, 100);
      await _transaction(harness, LedgerTransactionType.income, income, 900);
      await harness.transactions.create(
        type: LedgerTransactionType.transfer,
        accountId: '00000000-0000-4000-8000-000000000200',
        toAccountId: target,
        amountMinor: 400,
        occurredAtUtc: DateTime.utc(2026, 8, 3),
        timeZoneId: 'Asia/Shanghai',
      );
      var budgets = await harness.budgets.watchMonth(august).first;
      final total = budgets.firstWhere(
        (item) => item.scope == BudgetScope.total,
      );
      final category = budgets.firstWhere(
        (item) => item.scope == BudgetScope.category,
      );
      expect(total.usedMinor, 350);
      expect(total.remainingMinor, 650);
      expect(category.usedMinor, 250);
      expect(category.remainingMinor, 0);
      expect(category.overrunMinor, 50);
      expect(category.isOverrun, isTrue);

      await harness.transactions.update(
        id: foodTx,
        type: LedgerTransactionType.expense,
        accountId: '00000000-0000-4000-8000-000000000200',
        categoryId: food,
        amountMinor: 80,
        occurredAtUtc: DateTime.utc(2026, 8, 3),
        timeZoneId: 'Asia/Shanghai',
      );
      budgets = await harness.budgets.watchMonth(august).first;
      expect(
        budgets.firstWhere((item) => item.scope == BudgetScope.total).usedMinor,
        180,
      );
      await harness.transactions.delete(foodTx);
      budgets = await harness.budgets.watchMonth(august).first;
      expect(
        budgets
            .firstWhere((item) => item.scope == BudgetScope.category)
            .usedMinor,
        0,
      );
    },
  );

  test('zero budget never divides and reports deterministic overrun', () async {
    final expense = await harness.categories.create(
      name: '零预算支出',
      type: CategoryType.expense,
    );
    await harness.budgets.create(
      scope: BudgetScope.total,
      month: august,
      amountMinor: 0,
    );
    var budget = (await harness.budgets.watchMonth(august).first).single;
    expect(budget.displayUsageRate, 0);
    expect(budget.overrunMinor, 0);
    await _transaction(harness, LedgerTransactionType.expense, expense, 1);
    budget = (await harness.budgets.watchMonth(august).first).single;
    expect(budget.displayUsageRate, 1);
    expect(budget.overrunMinor, 1);
  });

  test('moving an expense across months updates both budget periods', () async {
    final expense = await harness.categories.create(
      name: '跨月支出',
      type: CategoryType.expense,
    );
    for (final month in [august, const LedgerMonth(2026, 9)]) {
      await harness.budgets.create(
        scope: BudgetScope.total,
        month: month,
        amountMinor: 1000,
      );
    }
    final id = await _transaction(
      harness,
      LedgerTransactionType.expense,
      expense,
      300,
    );
    await harness.transactions.update(
      id: id,
      type: LedgerTransactionType.expense,
      accountId: '00000000-0000-4000-8000-000000000200',
      categoryId: expense,
      amountMinor: 300,
      occurredAtUtc: DateTime.utc(2026, 9, 3),
      timeZoneId: 'Asia/Shanghai',
    );
    expect(
      (await harness.budgets.watchMonth(august).first).single.usedMinor,
      0,
    );
    expect(
      (await harness.budgets.watchMonth(const LedgerMonth(2026, 9)).first)
          .single
          .usedMinor,
      300,
    );
  });

  test(
    'analytics calculates totals, MoM, daily trend and timezone edges',
    () async {
      final expense = await harness.categories.create(
        name: '统计支出',
        type: CategoryType.expense,
      );
      final income = await harness.categories.create(
        name: '统计收入',
        type: CategoryType.income,
      );
      await _transactionAt(
        harness,
        LedgerTransactionType.income,
        income,
        1000,
        DateTime.utc(2026, 7, 31, 15, 59, 59, 999),
      );
      await _transactionAt(
        harness,
        LedgerTransactionType.income,
        income,
        2000,
        DateTime.utc(2026, 7, 31, 16),
      );
      await _transactionAt(
        harness,
        LedgerTransactionType.expense,
        expense,
        300,
        DateTime.utc(2026, 8, 31, 15, 59, 59, 999),
      );
      await _transactionAt(
        harness,
        LedgerTransactionType.expense,
        expense,
        999,
        DateTime.utc(2026, 8, 31, 16),
      );
      final snapshot = await harness.analytics
          .watch(const AnalyticsFilter(month: august))
          .first;
      expect(snapshot.income.currentMinor, 2000);
      expect(snapshot.expense.currentMinor, 300);
      expect(snapshot.netMinor, 1700);
      expect(snapshot.income.previousMinor, 1000);
      expect(snapshot.income.displayChangeRate, 1);
      expect(snapshot.expense.hasBaseline, isFalse);
      expect(snapshot.expense.displayChangeRate, isNull);
      expect(snapshot.dailyTrend.first.incomeMinor, 2000);
      expect(snapshot.dailyTrend.last.expenseMinor, 300);
    },
  );

  test(
    'rank ties are stable, filters work, deleted/transfer excluded and disabled history remains',
    () async {
      final first = await harness.categories.create(
        name: '排行甲',
        type: CategoryType.expense,
      );
      final second = await harness.categories.create(
        name: '排行乙',
        type: CategoryType.expense,
      );
      final otherAccount = await harness.accounts.create(
        name: '筛选账户',
        type: AccountType.cash,
        openingBalanceMinor: 500,
      );
      await _transaction(harness, LedgerTransactionType.expense, first, 100);
      await _transaction(harness, LedgerTransactionType.expense, second, 100);
      final removed = await harness.transactions.create(
        type: LedgerTransactionType.expense,
        accountId: otherAccount,
        categoryId: first,
        amountMinor: 500,
        occurredAtUtc: DateTime.utc(2026, 8, 3),
        timeZoneId: 'Asia/Shanghai',
      );
      await harness.transactions.delete(removed);
      await harness.categories.setEnabled(first, false);
      final all = await harness.analytics
          .watch(const AnalyticsFilter(month: august))
          .first;
      expect(all.expense.currentMinor, 200);
      expect(all.expenseRanking.map((item) => item.categoryName), [
        '排行甲',
        '排行乙',
      ]);
      final filtered = await harness.analytics
          .watch(AnalyticsFilter(month: august, categoryId: second))
          .first;
      expect(filtered.expense.currentMinor, 100);
      final accountFiltered = await harness.analytics
          .watch(AnalyticsFilter(month: august, accountId: otherAccount))
          .first;
      expect(accountFiltered.expense.currentMinor, 0);
      expect(accountFiltered.accounts.single.balanceMinor, 500);
    },
  );
}

Future<String> _transaction(
  LedgerTestHarness harness,
  LedgerTransactionType type,
  String categoryId,
  int amount,
) =>
    _transactionAt(harness, type, categoryId, amount, DateTime.utc(2026, 8, 3));

Future<String> _transactionAt(
  LedgerTestHarness harness,
  LedgerTransactionType type,
  String categoryId,
  int amount,
  DateTime occurred,
) => harness.transactions.create(
  type: type,
  accountId: '00000000-0000-4000-8000-000000000200',
  categoryId: categoryId,
  amountMinor: amount,
  occurredAtUtc: occurred,
  timeZoneId: 'Asia/Shanghai',
);
