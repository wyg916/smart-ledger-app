import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/core/database/app_database.dart';
import 'package:smart_ledger/core/database/local_ledger_bootstrapper.dart';
import 'package:smart_ledger/core/time/ledger_time.dart';
import 'package:smart_ledger/features/auth/data/local_data_isolation_service.dart';
import 'package:smart_ledger/features/auth/data/review_sample_data_seeder.dart';

void main() {
  late Directory directory;
  late LocalDataIsolationService isolation;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp(
      'smart-ledger-isolation-',
    );
    isolation = LocalDataIsolationService(() async => directory);
  });

  tearDown(() => directory.delete(recursive: true));

  test(
    'different authenticated users receive opaque separate database files',
    () async {
      final first = await isolation.userDatabase('user-a-phone-value');
      final second = await isolation.userDatabase('user-b-wechat-value');
      expect(first.path, isNot(second.path));
      expect(first.path, isNot(contains('user-a-phone-value')));
      expect(second.path, isNot(contains('user-b-wechat-value')));
      await first.writeAsString('only-user-a');
      await second.writeAsString('only-user-b');
      expect(await first.readAsString(), 'only-user-a');
      expect(await second.readAsString(), 'only-user-b');
    },
  );

  test(
    'Schema 4 legacy bytes are preserved by explicit idempotent binding',
    () async {
      final legacy = File('${directory.path}/smart_ledger.sqlite');
      final schema4Bytes = <int>[83, 81, 76, 105, 116, 101, 4, 0, 9, 8, 7];
      await legacy.writeAsBytes(schema4Bytes);
      expect(await isolation.requiresBindingDecision('user-a'), isTrue);
      await isolation.bindLegacy('user-a');
      final target = await isolation.userDatabase('user-a');
      expect(await target.readAsBytes(), schema4Bytes);
      await legacy.writeAsBytes([99]);
      await isolation.bindLegacy('user-a');
      expect(await target.readAsBytes(), schema4Bytes);
      expect(await isolation.requiresBindingDecision('user-a'), isFalse);
    },
  );

  test(
    'fresh choice leaves legacy data intact and deletion only targets one user',
    () async {
      final legacy = File('${directory.path}/smart_ledger.sqlite');
      await legacy.writeAsString('legacy');
      await isolation.startFresh('user-a');
      final first = await isolation.userDatabase('user-a');
      final second = await isolation.userDatabase('user-b');
      await first.writeAsString('a');
      await second.writeAsString('b');
      await isolation.deleteUserData('user-a');
      expect(first.existsSync(), isFalse);
      expect(second.existsSync(), isTrue);
      expect(await legacy.readAsString(), 'legacy');
    },
  );

  test('review user receives idempotent synthetic local data', () async {
    final database = AppDatabase(NativeDatabase.memory());
    final clock = _FixedClock(DateTime.utc(2026, 8, 4, 8));
    const timeZone = FixedLedgerTimeZone('Asia/Shanghai');
    await LocalLedgerBootstrapper(database, clock, timeZone).initialize();
    final seeder = ReviewSampleDataSeeder(database, clock, timeZone);
    await seeder.initialize();
    await seeder.initialize();
    expect(
      await database.select(database.ledgerTransactions).get(),
      hasLength(3),
    );
    expect(await database.select(database.budgets).get(), hasLength(1));
    expect(
      (await database.select(database.ledgerTransactions).get()).every(
        (row) => row.note?.startsWith('审核合成') ?? false,
      ),
      isTrue,
    );
    await database.close();
  });
}

final class _FixedClock implements LedgerClock {
  const _FixedClock(this.value);
  final DateTime value;

  @override
  DateTime nowUtc() => value;
}
