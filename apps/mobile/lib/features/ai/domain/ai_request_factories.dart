import 'package:smart_ledger/features/ai/domain/ai_requests.dart';
import 'package:smart_ledger/features/analytics/domain/ledger_analytics.dart';
import 'package:smart_ledger/features/budgets/domain/ledger_budget.dart';

MonthlyAiRequest monthlyAiRequest(AnalyticsSnapshot snapshot) {
  Map<String, Object?> comparison(MonthMetric metric) => {
    'previous_minor': metric.previousMinor,
    'delta_minor': metric.deltaMinor,
    'change_basis_points': metric.hasBaseline && metric.previousMinor != 0
        ? metric.deltaMinor * 10000 ~/ metric.previousMinor
        : null,
    'has_baseline': metric.hasBaseline,
  };
  return MonthlyAiRequest(
    month: snapshot.month.toString(),
    currencyCode: snapshot.currencyCode,
    timeZoneId: snapshot.timeZoneId,
    incomeMinor: snapshot.income.currentMinor,
    expenseMinor: snapshot.expense.currentMinor,
    netMinor: snapshot.netMinor,
    incomeComparison: comparison(snapshot.income),
    expenseComparison: comparison(snapshot.expense),
    dailyTrend: snapshot.dailyTrend
        .map(
          (item) => <String, Object>{
            'local_date': item.localDate,
            'income_minor': item.incomeMinor,
            'expense_minor': item.expenseMinor,
          },
        )
        .take(31)
        .toList(growable: false),
    incomeCategories: snapshot.incomeRanking
        .map(
          (item) => <String, Object>{
            'name': item.categoryName,
            'amount_minor': item.amountMinor,
          },
        )
        .take(10)
        .toList(growable: false),
    expenseCategories: snapshot.expenseRanking
        .map(
          (item) => <String, Object>{
            'name': item.categoryName,
            'amount_minor': item.amountMinor,
          },
        )
        .take(10)
        .toList(growable: false),
    accounts: snapshot.accounts
        .map(
          (item) => <String, Object>{
            'name': item.accountName,
            'balance_minor': item.balanceMinor,
          },
        )
        .take(20)
        .toList(growable: false),
  );
}

BudgetAiRequest budgetAiRequest(
  AnalyticsSnapshot snapshot,
  List<LedgerBudget> budgets, {
  required int daysRemaining,
}) {
  final total = budgets
      .where((item) => item.scope == BudgetScope.total)
      .firstOrNull;
  final totalBudget = total?.amountMinor ?? 0;
  final used = total?.usedMinor ?? 0;
  return BudgetAiRequest({
    'month': snapshot.month.toString(),
    'currency_code': snapshot.currencyCode,
    'total_budget_minor': totalBudget,
    'used_minor': used,
    'remaining_minor': total?.remainingMinor ?? 0,
    'overrun_minor': total?.overrunMinor ?? 0,
    'usage_basis_points': totalBudget == 0
        ? (used == 0 ? 0 : 10000)
        : used * 10000 ~/ totalBudget,
    'category_budgets': budgets
        .where((item) => item.scope == BudgetScope.category)
        .map(
          (item) => <String, Object>{
            'name': item.categoryName ?? item.name,
            'budget_minor': item.amountMinor,
            'used_minor': item.usedMinor,
            'remaining_minor': item.remainingMinor,
            'overrun_minor': item.overrunMinor,
          },
        )
        .take(10)
        .toList(growable: false),
    'days_remaining': daysRemaining.clamp(0, 31),
  });
}

FinancialPlanAiRequest financialPlanAiRequest({
  required String goalName,
  required int targetMinor,
  required int deadlineMonths,
  required int currentMinor,
  required int monthlyContributionMinor,
  required String riskPreference,
  String currencyCode = 'CNY',
}) {
  final remaining = targetMinor > currentMinor ? targetMinor - currentMinor : 0;
  final requiredMonthly = (remaining + deadlineMonths - 1) ~/ deadlineMonths;
  return FinancialPlanAiRequest({
    'goal_name': goalName,
    'target_minor': targetMinor,
    'deadline_months': deadlineMonths,
    'current_minor': currentMinor,
    'monthly_contribution_minor': monthlyContributionMinor,
    'risk_preference': riskPreference,
    'monthly_gap_minor': requiredMonthly - monthlyContributionMinor,
    'currency_code': currencyCode,
  });
}
