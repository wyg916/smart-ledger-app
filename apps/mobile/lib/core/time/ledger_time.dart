import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

abstract interface class LedgerClock {
  DateTime nowUtc();
}

final class SystemLedgerClock implements LedgerClock {
  const SystemLedgerClock();

  @override
  DateTime nowUtc() => DateTime.now().toUtc();
}

abstract interface class LedgerTimeZone {
  Future<String> currentIanaId();
}

final class DeviceLedgerTimeZone implements LedgerTimeZone {
  const DeviceLedgerTimeZone();

  @override
  Future<String> currentIanaId() async {
    final info = await FlutterTimezone.getLocalTimezone();
    return info.identifier;
  }
}

final class FixedLedgerClock implements LedgerClock {
  const FixedLedgerClock(this.value);

  final DateTime value;

  @override
  DateTime nowUtc() => value.toUtc();
}

final class FixedLedgerTimeZone implements LedgerTimeZone {
  const FixedLedgerTimeZone(this.value);

  final String value;

  @override
  Future<String> currentIanaId() async => value;
}

int toUtcEpochMilliseconds(DateTime value) =>
    value.toUtc().millisecondsSinceEpoch;

DateTime fromUtcEpochMilliseconds(int value) =>
    DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);

final class LedgerMonth {
  const LedgerMonth(this.year, this.month)
    : assert(month >= DateTime.january && month <= DateTime.december);

  factory LedgerMonth.parse(String value) {
    final match = RegExp(r'^(\d{4})-(\d{2})$').firstMatch(value);
    if (match == null) throw FormatException('Invalid year-month: $value');
    final result = LedgerMonth(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
    );
    if (result.month < 1 || result.month > 12) {
      throw FormatException('Invalid year-month: $value');
    }
    return result;
  }

  final int year;
  final int month;

  LedgerMonth get previous =>
      month == 1 ? LedgerMonth(year - 1, 12) : LedgerMonth(year, month - 1);

  LedgerMonth get next =>
      month == 12 ? LedgerMonth(year + 1, 1) : LedgerMonth(year, month + 1);

  int get daysInMonth =>
      DateTime.utc(year, month + 1).subtract(const Duration(days: 1)).day;

  String get firstLocalDate => '${toString()}-01';
  String get nextFirstLocalDate => '${next.toString()}-01';

  @override
  String toString() => '$year-${month.toString().padLeft(2, '0')}';

  @override
  bool operator ==(Object other) =>
      other is LedgerMonth && other.year == year && other.month == month;

  @override
  int get hashCode => Object.hash(year, month);
}

final class UtcMonthRange {
  const UtcMonthRange({required this.start, required this.endExclusive});

  final DateTime start;
  final DateTime endExclusive;
}

final class UtcDayRange {
  const UtcDayRange({
    required this.start,
    required this.endExclusive,
    required this.localDate,
  });

  final DateTime start;
  final DateTime endExclusive;
  final DateTime localDate;
}

bool _timeZonesInitialized = false;

UtcMonthRange monthRangeInTimeZone(LedgerMonth month, String timeZoneId) {
  if (!_timeZonesInitialized) {
    tz_data.initializeTimeZones();
    _timeZonesInitialized = true;
  }
  final location = tz.getLocation(timeZoneId);
  final start = tz.TZDateTime(location, month.year, month.month);
  final end = tz.TZDateTime(location, month.next.year, month.next.month);
  return UtcMonthRange(start: start.toUtc(), endExclusive: end.toUtc());
}

String localDayForUtc(DateTime utc, String timeZoneId) {
  if (!_timeZonesInitialized) {
    tz_data.initializeTimeZones();
    _timeZonesInitialized = true;
  }
  final local = tz.TZDateTime.from(utc.toUtc(), tz.getLocation(timeZoneId));
  return '${local.year.toString().padLeft(4, '0')}-'
      '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';
}

DateTime localDateForUtc(DateTime utc, String timeZoneId) {
  if (!_timeZonesInitialized) {
    tz_data.initializeTimeZones();
    _timeZonesInitialized = true;
  }
  final local = tz.TZDateTime.from(utc.toUtc(), tz.getLocation(timeZoneId));
  return DateTime(local.year, local.month, local.day);
}

UtcDayRange dayRangeInTimeZone(DateTime localDate, String timeZoneId) {
  if (!_timeZonesInitialized) {
    tz_data.initializeTimeZones();
    _timeZonesInitialized = true;
  }
  final location = tz.getLocation(timeZoneId);
  final start = tz.TZDateTime(
    location,
    localDate.year,
    localDate.month,
    localDate.day,
  );
  final end = tz.TZDateTime(
    location,
    localDate.year,
    localDate.month,
    localDate.day + 1,
  );
  return UtcDayRange(
    start: start.toUtc(),
    endExclusive: end.toUtc(),
    localDate: DateTime(start.year, start.month, start.day),
  );
}
