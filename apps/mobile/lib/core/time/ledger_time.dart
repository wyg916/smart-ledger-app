import 'package:flutter_timezone/flutter_timezone.dart';

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
