import 'package:smart_ledger/core/errors/ledger_exception.dart';

String requireName(String value, {required String field}) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw LedgerException('VALIDATION_ERROR', '$field不能为空');
  }
  return normalized;
}

String normalizedName(String value) => value.trim().toLowerCase();

String? normalizedOptionalText(String? value, {int? maxLength}) {
  final normalized = value?.trim();
  if (normalized == null || normalized.isEmpty) return null;
  if (maxLength != null && normalized.runes.length > maxLength) {
    throw LedgerException('VALIDATION_ERROR', '文本不能超过 $maxLength 个字符');
  }
  return normalized;
}

String requireTimeZoneId(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty ||
      (!normalized.contains('/') && normalized != 'UTC')) {
    throw const LedgerException('VALIDATION_ERROR', '必须提供有效的 IANA 时区标识');
  }
  return normalized;
}
