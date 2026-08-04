import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/core/time/ledger_time.dart';
import 'package:smart_ledger/features/quick_entry/domain/natural_language_parser.dart';
import 'package:smart_ledger/features/transactions/domain/ledger_transaction.dart';

void main() {
  const parser = NaturalLanguageTransactionParser();
  final now = DateTime.utc(2026, 8, 4, 2, 30);

  test(
    'parses a high-confidence local expense and always requires confirmation',
    () {
      final draft = parser.parse(
        text: '今天早餐花了25.50元',
        nowUtc: now,
        timeZoneId: 'Asia/Shanghai',
      );

      expect(draft, isNotNull);
      expect(draft!.type, LedgerTransactionType.expense);
      expect(draft.amountMinor, 2550);
      expect(draft.categoryCandidate, '餐饮');
      expect(draft.source, 'local');
      expect(draft.confidence, greaterThanOrEqualTo(0.8));
      expect(draft.needsConfirmation, isTrue);
    },
  );

  test('recognizes income and resolves yesterday in the ledger timezone', () {
    final draft = parser.parse(
      text: '昨天收到工资1000元',
      nowUtc: now,
      timeZoneId: 'Asia/Shanghai',
    )!;

    expect(draft.type, LedgerTransactionType.income);
    expect(draft.categoryCandidate, '工资');
    expect(localDayForUtc(draft.occurredAtUtc, 'Asia/Shanghai'), '2026-08-03');
  });

  test('marks ambiguous inputs for explicit user review', () {
    final draft = parser.parse(
      text: '2026-13-40 花了20元',
      nowUtc: now,
      timeZoneId: 'Asia/Shanghai',
    )!;

    expect(draft.confidence, lessThan(0.8));
    expect(draft.warnings, contains('日期表达可能有歧义，请核对日期'));
    expect(draft.needsConfirmation, isTrue);
  });

  test('does not invent a draft without a usable amount', () {
    expect(
      parser.parse(text: '今天吃了早餐', nowUtc: now, timeZoneId: 'Asia/Shanghai'),
      isNull,
    );
  });
}
