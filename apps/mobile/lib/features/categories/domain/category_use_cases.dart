import 'package:smart_ledger/features/categories/domain/ledger_category.dart';

final class SaveCategoryUseCase {
  const SaveCategoryUseCase(this._repository);

  final CategoryRepository _repository;

  Future<String> create({required String name, required CategoryType type}) {
    return _repository.create(name: name, type: type);
  }

  Future<void> update({required String id, required String name}) {
    return _repository.update(id: id, name: name);
  }

  Future<void> setEnabled(String id, bool enabled) =>
      _repository.setEnabled(id, enabled);
}
