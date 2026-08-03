final class MonthlyAiRequest {
  const MonthlyAiRequest({
    required this.month,
    required this.currencyCode,
    required this.timeZoneId,
    required this.incomeMinor,
    required this.expenseMinor,
    required this.netMinor,
    required this.incomeComparison,
    required this.expenseComparison,
    required this.dailyTrend,
    required this.incomeCategories,
    required this.expenseCategories,
    required this.accounts,
  });

  final String month;
  final String currencyCode;
  final String timeZoneId;
  final int incomeMinor;
  final int expenseMinor;
  final int netMinor;
  final Map<String, Object?> incomeComparison;
  final Map<String, Object?> expenseComparison;
  final List<Map<String, Object>> dailyTrend;
  final List<Map<String, Object>> incomeCategories;
  final List<Map<String, Object>> expenseCategories;
  final List<Map<String, Object>> accounts;

  Map<String, Object?> toJson() => {
    'month': month,
    'currency_code': currencyCode,
    'time_zone_id': timeZoneId,
    'income_minor': incomeMinor,
    'expense_minor': expenseMinor,
    'net_minor': netMinor,
    'income_comparison': incomeComparison,
    'expense_comparison': expenseComparison,
    'daily_trend': dailyTrend,
    'income_categories': incomeCategories,
    'expense_categories': expenseCategories,
    'accounts': accounts,
  };
}

final class BudgetAiRequest {
  const BudgetAiRequest(this.values);
  final Map<String, Object?> values;
  Map<String, Object?> toJson() => values;
}

final class FinancialPlanAiRequest {
  const FinancialPlanAiRequest(this.values);
  final Map<String, Object?> values;
  Map<String, Object?> toJson() => values;
}
