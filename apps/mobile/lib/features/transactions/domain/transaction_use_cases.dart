import 'package:smart_ledger/features/transactions/domain/ledger_transaction.dart';

final class SaveTransactionUseCase {
  const SaveTransactionUseCase(this._repository);

  final TransactionRepository _repository;

  Future<String> create({
    required LedgerTransactionType type,
    required String accountId,
    String? toAccountId,
    String? categoryId,
    required int amountMinor,
    required DateTime occurredAtUtc,
    required String timeZoneId,
    String? note,
    String sourceType = 'manual',
  }) {
    return _repository.create(
      type: type,
      accountId: accountId,
      toAccountId: toAccountId,
      categoryId: categoryId,
      amountMinor: amountMinor,
      occurredAtUtc: occurredAtUtc,
      timeZoneId: timeZoneId,
      note: note,
      sourceType: sourceType,
    );
  }

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
  }) {
    return _repository.update(
      id: id,
      type: type,
      accountId: accountId,
      toAccountId: toAccountId,
      categoryId: categoryId,
      amountMinor: amountMinor,
      occurredAtUtc: occurredAtUtc,
      timeZoneId: timeZoneId,
      note: note,
    );
  }

  Future<void> delete(String id) => _repository.delete(id);
}
