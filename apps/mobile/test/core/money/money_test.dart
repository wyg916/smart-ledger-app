import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/core/errors/ledger_exception.dart';
import 'package:smart_ledger/core/money/money.dart';

void main() {
  group('Money deterministic parsing and formatting', () {
    test('0.01 yuan is exactly one minor unit', () {
      expect(Money.parsePositive('0.01').minor, 1);
    });

    test('0.10 plus 0.20 is exact', () {
      final result = Money.parsePositive('0.10') + Money.parsePositive('0.20');
      expect(result.minor, 30);
      expect(result.format(), '0.30');
    });

    test('large valid amount is accepted and overflow is rejected', () {
      expect(Money.parsePositive('92233720368547758.07').minor, maxInt64);
      expect(
        () => Money.parsePositive('92233720368547758.08'),
        throwsA(isA<LedgerException>()),
      );
    });

    test('more than two fractional digits are rejected', () {
      expect(
        () => Money.parsePositive('1.001'),
        throwsA(isA<LedgerException>()),
      );
    });

    test('negative zero and invalid strings are rejected for transactions', () {
      for (final value in ['-1.00', '0', '0.00', 'abc', '', '1,00']) {
        expect(
          () => Money.parsePositive(value),
          throwsA(isA<LedgerException>()),
          reason: value,
        );
      }
    });

    test('formatting is stable including Int64 minimum', () {
      expect(Money.fromMinor(1).format(withCurrencySymbol: true), '¥0.01');
      expect(Money.fromMinor(-12345).format(), '-123.45');
      expect(Money.fromMinor(minInt64).format(), '-92233720368547758.08');
    });
  });
}
