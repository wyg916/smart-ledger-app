enum CategoryType {
  income,
  expense;

  static CategoryType fromDatabase(String value) =>
      CategoryType.values.firstWhere((item) => item.name == value);
}

final class LedgerCategory {
  const LedgerCategory({
    required this.id,
    required this.ledgerId,
    required this.name,
    required this.type,
    required this.enabled,
    required this.version,
    this.iconCode,
    this.systemKey,
  });

  final String id;
  final String ledgerId;
  final String name;
  final CategoryType type;
  final bool enabled;
  final int version;
  final String? iconCode;
  final String? systemKey;
}

abstract interface class CategoryRepository {
  Stream<List<LedgerCategory>> watchAll({
    CategoryType? type,
    bool enabledOnly = false,
  });

  Future<List<LedgerCategory>> listEnabled(CategoryType type);

  Stream<List<LedgerCategory>> watchQuick({
    required CategoryType type,
    required DateTime windowStartUtc,
    int limit = 6,
  });

  Future<LedgerCategory?> getById(String id);

  Future<String> create({required String name, required CategoryType type});

  Future<void> update({required String id, required String name});

  Future<void> setEnabled(String id, bool enabled);
}
