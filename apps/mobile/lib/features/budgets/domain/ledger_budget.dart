import 'package:smart_ledger/core/time/ledger_time.dart';

enum BudgetScope {
  total,
  category;

  static BudgetScope fromDatabase(String value) =>
      BudgetScope.values.firstWhere((item) => item.name == value);
}

final class LedgerBudget {
  const LedgerBudget({
    required this.id,
    required this.ledgerId,
    required this.name,
    required this.scope,
    required this.month,
    required this.amountMinor,
    required this.currencyCode,
    required this.timeZoneId,
    required this.isActive,
    required this.version,
    required this.usedMinor,
    this.categoryId,
    this.categoryName,
    this.categoryEnabled,
  });

  final String id;
  final String ledgerId;
  final String name;
  final BudgetScope scope;
  final String? categoryId;
  final String? categoryName;
  final bool? categoryEnabled;
  final LedgerMonth month;
  final int amountMinor;
  final String currencyCode;
  final String timeZoneId;
  final bool isActive;
  final int version;
  final int usedMinor;

  int get remainingMinor =>
      amountMinor > usedMinor ? amountMinor - usedMinor : 0;
  int get overrunMinor => usedMinor > amountMinor ? usedMinor - amountMinor : 0;
  bool get isOverrun => usedMinor > amountMinor;
  bool get isNearLimit =>
      !isOverrun && amountMinor > 0 && usedMinor * 100 >= amountMinor * 80;
  double get displayUsageRate {
    if (amountMinor == 0) return usedMinor == 0 ? 0 : 1;
    return (usedMinor / amountMinor).clamp(0, 1).toDouble();
  }
}

abstract interface class BudgetRepository {
  Stream<List<LedgerBudget>> watchMonth(LedgerMonth month);

  Future<LedgerBudget?> getById(String id);

  Future<String> create({
    required BudgetScope scope,
    required LedgerMonth month,
    required int amountMinor,
    String? categoryId,
  });

  Future<void> update({required String id, required int amountMinor});

  Future<void> setActive(String id, bool active);

  Future<void> delete(String id);
}
