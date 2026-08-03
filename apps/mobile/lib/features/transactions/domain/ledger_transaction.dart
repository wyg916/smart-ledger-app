enum LedgerTransactionType {
  income,
  expense,
  transfer;

  static LedgerTransactionType fromDatabase(String value) =>
      LedgerTransactionType.values.firstWhere((item) => item.name == value);
}

final class LedgerTransaction {
  const LedgerTransaction({
    required this.id,
    required this.ledgerId,
    required this.type,
    required this.accountId,
    required this.accountName,
    required this.amountMinor,
    required this.occurredAtUtc,
    required this.timeZoneId,
    required this.version,
    this.toAccountId,
    this.toAccountName,
    this.categoryId,
    this.categoryName,
    this.note,
  });

  final String id;
  final String ledgerId;
  final LedgerTransactionType type;
  final String accountId;
  final String accountName;
  final String? toAccountId;
  final String? toAccountName;
  final String? categoryId;
  final String? categoryName;
  final int amountMinor;
  final DateTime occurredAtUtc;
  final String timeZoneId;
  final String? note;
  final int version;
}

final class TransactionFilter {
  const TransactionFilter({
    required this.startUtc,
    required this.endUtcExclusive,
    this.accountId,
    this.categoryId,
  });

  final DateTime startUtc;
  final DateTime endUtcExclusive;
  final String? accountId;
  final String? categoryId;
}

final class LedgerSummary {
  const LedgerSummary({required this.incomeMinor, required this.expenseMinor});

  final int incomeMinor;
  final int expenseMinor;
  int get netMinor => incomeMinor - expenseMinor;
}

abstract interface class TransactionRepository {
  Stream<List<LedgerTransaction>> watch(TransactionFilter filter);

  Future<LedgerTransaction?> getById(String id);

  Future<String> create({
    required LedgerTransactionType type,
    required String accountId,
    String? toAccountId,
    String? categoryId,
    required int amountMinor,
    required DateTime occurredAtUtc,
    required String timeZoneId,
    String? note,
  });

  Future<void> update({
    required String id,
    required LedgerTransactionType type,
    required String accountId,
    String? toAccountId,
    String? categoryId,
    required int amountMinor,
    required DateTime occurredAtUtc,
    required String timeZoneId,
    String? note,
  });

  Future<void> delete(String id);
}

LedgerSummary summarizeTransactions(Iterable<LedgerTransaction> transactions) {
  var income = 0;
  var expense = 0;
  for (final transaction in transactions) {
    switch (transaction.type) {
      case LedgerTransactionType.income:
        income += transaction.amountMinor;
        break;
      case LedgerTransactionType.expense:
        expense += transaction.amountMinor;
        break;
      case LedgerTransactionType.transfer:
        break;
    }
  }
  return LedgerSummary(incomeMinor: income, expenseMinor: expense);
}
