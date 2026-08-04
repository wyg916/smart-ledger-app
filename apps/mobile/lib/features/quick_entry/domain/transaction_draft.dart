import 'package:smart_ledger/features/transactions/domain/ledger_transaction.dart';

final class TransactionDraft {
  const TransactionDraft({
    required this.type,
    required this.amountMinor,
    required this.currencyCode,
    required this.categoryCandidate,
    required this.occurredAtUtc,
    required this.timeZoneId,
    required this.note,
    required this.confidence,
    required this.needsConfirmation,
    required this.warnings,
    required this.source,
  });

  final LedgerTransactionType type;
  final int amountMinor;
  final String currencyCode;
  final String? categoryCandidate;
  final DateTime occurredAtUtc;
  final String timeZoneId;
  final String note;
  final double confidence;
  final bool needsConfirmation;
  final List<String> warnings;
  final String source;
}
