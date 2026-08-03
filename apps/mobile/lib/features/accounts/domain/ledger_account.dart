enum AccountType {
  cash,
  bank,
  wallet,
  other;

  static AccountType fromDatabase(String value) =>
      AccountType.values.firstWhere(
        (item) => item.name == value,
        orElse: () => AccountType.other,
      );
}

final class LedgerAccount {
  const LedgerAccount({
    required this.id,
    required this.ledgerId,
    required this.name,
    required this.type,
    required this.openingBalanceMinor,
    required this.currentBalanceMinor,
    required this.enabled,
    required this.version,
    this.iconCode,
  });

  final String id;
  final String ledgerId;
  final String name;
  final AccountType type;
  final int openingBalanceMinor;
  final int currentBalanceMinor;
  final bool enabled;
  final int version;
  final String? iconCode;
}

abstract interface class AccountRepository {
  Stream<List<LedgerAccount>> watchAll({bool enabledOnly = false});

  Future<List<LedgerAccount>> listEnabled();

  Future<LedgerAccount?> getById(String id);

  Future<String> create({
    required String name,
    required AccountType type,
    required int openingBalanceMinor,
  });

  Future<void> update({
    required String id,
    required String name,
    required AccountType type,
    required int openingBalanceMinor,
  });

  Future<void> setEnabled(String id, bool enabled);
}
