import 'package:smart_ledger/core/time/ledger_time.dart';

final class AnalyticsFilter {
  const AnalyticsFilter({required this.month, this.accountId, this.categoryId});

  final LedgerMonth month;
  final String? accountId;
  final String? categoryId;
}

final class MonthMetric {
  const MonthMetric({
    required this.currentMinor,
    required this.previousMinor,
    required this.hasBaseline,
  });

  final int currentMinor;
  final int previousMinor;
  final bool hasBaseline;
  int get deltaMinor => currentMinor - previousMinor;
  double? get displayChangeRate =>
      !hasBaseline || previousMinor == 0 ? null : deltaMinor / previousMinor;
}

final class DailyTrendPoint {
  const DailyTrendPoint({
    required this.localDate,
    required this.incomeMinor,
    required this.expenseMinor,
  });

  final String localDate;
  final int incomeMinor;
  final int expenseMinor;
}

final class CategoryRank {
  const CategoryRank({
    required this.categoryId,
    required this.categoryName,
    required this.amountMinor,
  });

  final String categoryId;
  final String categoryName;
  final int amountMinor;
}

final class AccountBalanceOverview {
  const AccountBalanceOverview({
    required this.accountId,
    required this.accountName,
    required this.balanceMinor,
    required this.enabled,
  });

  final String accountId;
  final String accountName;
  final int balanceMinor;
  final bool enabled;
}

final class AnalyticsSnapshot {
  const AnalyticsSnapshot({
    required this.month,
    required this.currencyCode,
    required this.timeZoneId,
    required this.income,
    required this.expense,
    required this.dailyTrend,
    required this.expenseRanking,
    required this.incomeRanking,
    required this.accounts,
  });

  final LedgerMonth month;
  final String currencyCode;
  final String timeZoneId;
  final MonthMetric income;
  final MonthMetric expense;
  final List<DailyTrendPoint> dailyTrend;
  final List<CategoryRank> expenseRanking;
  final List<CategoryRank> incomeRanking;
  final List<AccountBalanceOverview> accounts;
  int get netMinor => income.currentMinor - expense.currentMinor;
  bool get hasCurrentData =>
      income.currentMinor != 0 || expense.currentMinor != 0;
}

abstract interface class AnalyticsRepository {
  Stream<AnalyticsSnapshot> watch(AnalyticsFilter filter);
}
