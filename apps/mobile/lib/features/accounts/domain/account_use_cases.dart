import 'package:smart_ledger/features/accounts/domain/ledger_account.dart';

final class SaveAccountUseCase {
  const SaveAccountUseCase(this._repository);

  final AccountRepository _repository;

  Future<String> create({
    required String name,
    required AccountType type,
    required int openingBalanceMinor,
  }) {
    return _repository.create(
      name: name,
      type: type,
      openingBalanceMinor: openingBalanceMinor,
    );
  }

  Future<void> update({
    required String id,
    required String name,
    required AccountType type,
    required int openingBalanceMinor,
  }) {
    return _repository.update(
      id: id,
      name: name,
      type: type,
      openingBalanceMinor: openingBalanceMinor,
    );
  }

  Future<void> setEnabled(String id, bool enabled) =>
      _repository.setEnabled(id, enabled);
}
