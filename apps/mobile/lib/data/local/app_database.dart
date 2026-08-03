import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  AppDatabase.defaults() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  Future<int> ping() async {
    final row = await customSelect('SELECT 1 AS value').getSingle();
    return row.read<int>('value');
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(path.join(directory.path, 'smart_ledger.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
