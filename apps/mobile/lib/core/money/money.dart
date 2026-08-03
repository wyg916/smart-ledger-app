import 'package:smart_ledger/core/errors/ledger_exception.dart';

const int maxInt64 = 9223372036854775807;
const int minInt64 = -9223372036854775808;

final class Money {
  const Money._(this.minor);

  final int minor;

  factory Money.fromMinor(int value) {
    if (value < minInt64 || value > maxInt64) {
      throw const LedgerException('MONEY_OUT_OF_RANGE', '金额超出 Int64 范围');
    }
    return Money._(value);
  }

  factory Money.parsePositive(String input) {
    final value = _parseMinor(input);
    if (value <= 0) {
      throw const LedgerException('MONEY_NOT_POSITIVE', '金额必须大于零');
    }
    return Money.fromMinor(value);
  }

  factory Money.parseSigned(String input) =>
      Money.fromMinor(_parseMinor(input));

  Money operator +(Money other) =>
      Money.fromMinor(_checked(minor, other.minor, true));

  Money operator -(Money other) =>
      Money.fromMinor(_checked(minor, other.minor, false));

  String format({bool withCurrencySymbol = false}) {
    final absolute = BigInt.from(minor).abs();
    final whole = absolute ~/ BigInt.from(100);
    final fraction = (absolute % BigInt.from(100)).toString().padLeft(2, '0');
    final sign = minor < 0 ? '-' : '';
    final symbol = withCurrencySymbol ? '¥' : '';
    return '$sign$symbol$whole.$fraction';
  }

  static int _parseMinor(String input) {
    final trimmed = input.trim();
    if (!RegExp(r'^[+-]?\d+(?:\.\d{1,2})?$').hasMatch(trimmed)) {
      throw const LedgerException('MONEY_INVALID', '请输入最多两位小数的有效金额');
    }

    var source = trimmed;
    var negative = false;
    if (source.startsWith('-')) {
      negative = true;
      source = source.substring(1);
    } else if (source.startsWith('+')) {
      source = source.substring(1);
    }

    final parts = source.split('.');
    final whole = BigInt.parse(parts.first);
    final fractionText = parts.length == 1 ? '00' : parts[1].padRight(2, '0');
    var result = whole * BigInt.from(100) + BigInt.parse(fractionText);
    if (negative) result = -result;

    if (result < BigInt.from(minInt64) || result > BigInt.from(maxInt64)) {
      throw const LedgerException('MONEY_OUT_OF_RANGE', '金额超出 Int64 范围');
    }
    return result.toInt();
  }

  static int _checked(int left, int right, bool add) {
    final result = add
        ? BigInt.from(left) + BigInt.from(right)
        : BigInt.from(left) - BigInt.from(right);
    if (result < BigInt.from(minInt64) || result > BigInt.from(maxInt64)) {
      throw const LedgerException('MONEY_OUT_OF_RANGE', '金额计算超出 Int64 范围');
    }
    return result.toInt();
  }
}
