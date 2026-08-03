import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

class Ledgers extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get currencyCode => text().withDefault(const Constant('CNY'))();
  TextColumn get timeZoneId => text()();
  BoolColumn get isDefault => boolean().withDefault(const Constant(true))();
  TextColumn get settingsJson => text().nullable()();
  IntColumn get createdAtMs => integer()();
  IntColumn get updatedAtMs => integer()();
  IntColumn get deletedAtMs => integer().nullable()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get lastModifiedDeviceId => text().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  IntColumn get legacyId => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Accounts extends Table {
  TextColumn get id => text()();
  TextColumn get ledgerId =>
      text().references(Ledgers, #id, onDelete: KeyAction.restrict)();
  TextColumn get name => text()();
  TextColumn get normalizedName => text()();
  TextColumn get accountType => text().withDefault(const Constant('cash'))();
  IntColumn get openingBalanceMinor =>
      integer().withDefault(const Constant(0))();
  TextColumn get iconCode => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  IntColumn get createdAtMs => integer()();
  IntColumn get updatedAtMs => integer()();
  IntColumn get deletedAtMs => integer().nullable()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get lastModifiedDeviceId => text().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  IntColumn get legacyId => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {ledgerId, normalizedName},
  ];
}

class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get ledgerId =>
      text().references(Ledgers, #id, onDelete: KeyAction.restrict)();
  TextColumn get categoryType => text()();
  TextColumn get name => text()();
  TextColumn get normalizedName => text()();
  TextColumn get iconCode => text().nullable()();
  TextColumn get colorToken => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  TextColumn get systemKey => text().nullable()();
  IntColumn get createdAtMs => integer()();
  IntColumn get updatedAtMs => integer()();
  IntColumn get deletedAtMs => integer().nullable()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get lastModifiedDeviceId => text().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  IntColumn get legacyId => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {ledgerId, categoryType, normalizedName},
    {ledgerId, systemKey},
  ];
}

class LedgerTransactions extends Table {
  @override
  String get tableName => 'transactions';

  TextColumn get id => text()();
  TextColumn get ledgerId =>
      text().references(Ledgers, #id, onDelete: KeyAction.restrict)();
  TextColumn get transactionType => text()();
  @ReferenceName('sourceTransactions')
  TextColumn get accountId =>
      text().references(Accounts, #id, onDelete: KeyAction.restrict)();
  @ReferenceName('targetTransactions')
  TextColumn get toAccountId => text().nullable().references(
    Accounts,
    #id,
    onDelete: KeyAction.restrict,
  )();
  TextColumn get categoryId => text().nullable().references(
    Categories,
    #id,
    onDelete: KeyAction.restrict,
  )();
  IntColumn get amountMinor => integer()();
  IntColumn get occurredAtUtcMs => integer()();
  TextColumn get timeZoneId => text()();
  TextColumn get note => text().nullable()();
  TextColumn get merchant => text().nullable()();
  TextColumn get sourceType => text().withDefault(const Constant('manual'))();
  TextColumn get transferGroupId => text().nullable()();
  IntColumn get createdAtMs => integer()();
  IntColumn get updatedAtMs => integer()();
  IntColumn get deletedAtMs => integer().nullable()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get lastModifiedDeviceId => text().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
  IntColumn get legacyId => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get valueType => text()();
  TextColumn get valueText => text().nullable()();
  IntColumn get updatedAtMs => integer()();
  TextColumn get syncScope => text().withDefault(const Constant('device'))();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

@DriftDatabase(
  tables: [Ledgers, Accounts, Categories, LedgerTransactions, AppSettings],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  AppDatabase.defaults() : super(_openConnection());

  static const int currentSchemaVersion = 2;

  @override
  int get schemaVersion => currentSchemaVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
    },
    onUpgrade: (migrator, from, to) async {
      if (from == 1 && to >= 2) {
        await migrator.createAll();
        return;
      }
      throw StateError('Unsupported database migration $from -> $to');
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      await _ensureIndexesAndConstraints();
    },
  );

  Future<int> ping() async {
    final row = await customSelect('SELECT 1 AS value').getSingle();
    return row.read<int>('value');
  }

  Future<bool> foreignKeysEnabled() async {
    final row = await customSelect('PRAGMA foreign_keys').getSingle();
    return row.read<int>('foreign_keys') == 1;
  }

  Future<void> _ensureIndexesAndConstraints() async {
    const statements = [
      'CREATE INDEX IF NOT EXISTS idx_transactions_ledger_occurred '
          'ON transactions (ledger_id, occurred_at_utc_ms DESC) WHERE deleted_at_ms IS NULL',
      'CREATE INDEX IF NOT EXISTS idx_transactions_ledger_category_occurred '
          'ON transactions (ledger_id, category_id, occurred_at_utc_ms)',
      'CREATE INDEX IF NOT EXISTS idx_transactions_ledger_account_occurred '
          'ON transactions (ledger_id, account_id, occurred_at_utc_ms)',
      'CREATE INDEX IF NOT EXISTS idx_transactions_ledger_updated '
          'ON transactions (ledger_id, updated_at_ms)',
      'CREATE INDEX IF NOT EXISTS idx_categories_ledger_type_sort '
          'ON categories (ledger_id, category_type, sort_order)',
      'CREATE INDEX IF NOT EXISTS idx_accounts_ledger_sort '
          'ON accounts (ledger_id, sort_order)',
      '''CREATE TRIGGER IF NOT EXISTS validate_transaction_insert
         BEFORE INSERT ON transactions
         WHEN NEW.amount_minor <= 0
           OR NEW.transaction_type NOT IN ('income', 'expense', 'transfer')
           OR (NEW.transaction_type IN ('income', 'expense') AND
               (NEW.category_id IS NULL OR NEW.to_account_id IS NOT NULL))
           OR (NEW.transaction_type = 'transfer' AND
               (NEW.category_id IS NOT NULL OR NEW.to_account_id IS NULL OR NEW.account_id = NEW.to_account_id))
         BEGIN SELECT RAISE(ABORT, 'invalid transaction'); END''',
      '''CREATE TRIGGER IF NOT EXISTS validate_transaction_update
         BEFORE UPDATE ON transactions
         WHEN NEW.amount_minor <= 0
           OR NEW.transaction_type NOT IN ('income', 'expense', 'transfer')
           OR (NEW.transaction_type IN ('income', 'expense') AND
               (NEW.category_id IS NULL OR NEW.to_account_id IS NOT NULL))
           OR (NEW.transaction_type = 'transfer' AND
               (NEW.category_id IS NOT NULL OR NEW.to_account_id IS NULL OR NEW.account_id = NEW.to_account_id))
         BEGIN SELECT RAISE(ABORT, 'invalid transaction'); END''',
    ];
    for (final statement in statements) {
      await customStatement(statement);
    }
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(path.join(directory.path, 'smart_ledger.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
