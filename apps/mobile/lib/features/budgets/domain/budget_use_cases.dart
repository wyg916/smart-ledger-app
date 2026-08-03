import 'package:smart_ledger/core/time/ledger_time.dart';
import 'package:smart_ledger/features/budgets/domain/ledger_budget.dart';

final class SaveBudgetUseCase {
  const SaveBudgetUseCase(this._repository);

  final BudgetRepository _repository;

  Future<String> create({
    required BudgetScope scope,
    required LedgerMonth month,
    required int amountMinor,
    String? categoryId,
  }) => _repository.create(
    scope: scope,
    month: month,
    amountMinor: amountMinor,
    categoryId: categoryId,
  );

  Future<void> update({required String id, required int amountMinor}) =>
      _repository.update(id: id, amountMinor: amountMinor);

  Future<void> setActive(String id, bool active) =>
      _repository.setActive(id, active);

  Future<void> delete(String id) => _repository.delete(id);
}
