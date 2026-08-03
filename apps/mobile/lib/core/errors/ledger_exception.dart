class LedgerException implements Exception {
  const LedgerException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => message;
}
