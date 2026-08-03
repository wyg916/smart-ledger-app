import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/data/local/app_database.dart';

void main() {
  test('opens, queries, and closes an in-memory Drift database', () async {
    final database = AppDatabase(NativeDatabase.memory());

    expect(await database.ping(), 1);

    await database.close();
  });
}
