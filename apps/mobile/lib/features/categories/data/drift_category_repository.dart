import 'package:drift/drift.dart';
import 'package:smart_ledger/core/database/app_database.dart';
import 'package:smart_ledger/core/database/entity_id.dart';
import 'package:smart_ledger/core/database/local_ledger_bootstrapper.dart';
import 'package:smart_ledger/core/errors/ledger_exception.dart';
import 'package:smart_ledger/core/time/ledger_time.dart';
import 'package:smart_ledger/core/validation/ledger_validation.dart';
import 'package:smart_ledger/features/categories/domain/ledger_category.dart';

final class DriftCategoryRepository implements CategoryRepository {
  const DriftCategoryRepository(this._database, this._clock, this._ids);

  final AppDatabase _database;
  final LedgerClock _clock;
  final EntityIdGenerator _ids;

  @override
  Stream<List<LedgerCategory>> watchAll({
    CategoryType? type,
    bool enabledOnly = false,
  }) {
    final query = _database.select(_database.categories)
      ..where((row) => row.deletedAtMs.isNull())
      ..orderBy([
        (row) => OrderingTerm.asc(row.sortOrder),
        (row) => OrderingTerm.asc(row.createdAtMs),
      ]);
    if (type != null) query.where((row) => row.categoryType.equals(type.name));
    if (enabledOnly) query.where((row) => row.enabled.equals(true));
    return query.watch().map((rows) => rows.map(_map).toList(growable: false));
  }

  @override
  Future<List<LedgerCategory>> listEnabled(CategoryType type) {
    return watchAll(type: type, enabledOnly: true).first;
  }

  @override
  Stream<List<LedgerCategory>> watchQuick({
    required CategoryType type,
    required DateTime windowStartUtc,
    int limit = 6,
  }) {
    return _database
        .customSelect(
          '''
          SELECT c.*, COUNT(t.id) AS use_count,
            COALESCE(MAX(t.occurred_at_utc_ms), 0) AS last_used_at_ms
          FROM categories c
          LEFT JOIN transactions t
            ON t.category_id = c.id
            AND t.deleted_at_ms IS NULL
            AND t.transaction_type = c.category_type
            AND t.occurred_at_utc_ms >= ?
          WHERE c.ledger_id = ? AND c.category_type = ?
            AND c.enabled = 1 AND c.deleted_at_ms IS NULL
          GROUP BY c.id
          ORDER BY use_count DESC, last_used_at_ms DESC,
            c.sort_order ASC, c.id ASC
          LIMIT ?
          ''',
          variables: [
            Variable.withInt(windowStartUtc.toUtc().millisecondsSinceEpoch),
            Variable.withString(defaultLedgerId),
            Variable.withString(type.name),
            Variable.withInt(limit),
          ],
          readsFrom: {_database.categories, _database.ledgerTransactions},
        )
        .watch()
        .map((rows) => rows.map(_mapQueryRow).toList(growable: false));
  }

  @override
  Future<LedgerCategory?> getById(String id) async {
    final row =
        await (_database.select(_database.categories)
              ..where((item) => item.id.equals(id) & item.deletedAtMs.isNull()))
            .getSingleOrNull();
    return row == null ? null : _map(row);
  }

  @override
  Future<String> create({
    required String name,
    required CategoryType type,
  }) async {
    final validName = requireName(name, field: '分类名称');
    await _ensureNameAvailable(validName, type);
    final id = _ids.next();
    final now = _clock.nowUtc().millisecondsSinceEpoch;
    final current =
        await (_database.selectOnly(_database.categories)
              ..addColumns([_database.categories.sortOrder.max()])
              ..where(_database.categories.categoryType.equals(type.name)))
            .getSingle();
    final sortOrder =
        (current.read(_database.categories.sortOrder.max()) ?? -1) + 1;
    await _database
        .into(_database.categories)
        .insert(
          CategoriesCompanion.insert(
            id: id,
            ledgerId: defaultLedgerId,
            categoryType: type.name,
            name: validName,
            normalizedName: normalizedName(validName),
            sortOrder: Value(sortOrder),
            createdAtMs: now,
            updatedAtMs: now,
          ),
        );
    return id;
  }

  @override
  Future<void> update({required String id, required String name}) async {
    final validName = requireName(name, field: '分类名称');
    final current = await (_database.select(
      _database.categories,
    )..where((row) => row.id.equals(id))).getSingleOrNull();
    if (current == null || current.deletedAtMs != null) {
      throw const LedgerException('CATEGORY_NOT_FOUND', '分类不存在');
    }
    await _ensureNameAvailable(
      validName,
      CategoryType.fromDatabase(current.categoryType),
      excludingId: id,
    );
    await (_database.update(
      _database.categories,
    )..where((row) => row.id.equals(id))).write(
      CategoriesCompanion(
        name: Value(validName),
        normalizedName: Value(normalizedName(validName)),
        updatedAtMs: Value(_clock.nowUtc().millisecondsSinceEpoch),
        version: Value(current.version + 1),
        syncStatus: const Value('pending'),
      ),
    );
  }

  @override
  Future<void> setEnabled(String id, bool enabled) async {
    final current = await (_database.select(
      _database.categories,
    )..where((row) => row.id.equals(id))).getSingleOrNull();
    if (current == null || current.deletedAtMs != null) {
      throw const LedgerException('CATEGORY_NOT_FOUND', '分类不存在');
    }
    await (_database.update(
      _database.categories,
    )..where((row) => row.id.equals(id))).write(
      CategoriesCompanion(
        enabled: Value(enabled),
        updatedAtMs: Value(_clock.nowUtc().millisecondsSinceEpoch),
        version: Value(current.version + 1),
        syncStatus: const Value('pending'),
      ),
    );
  }

  Future<void> _ensureNameAvailable(
    String name,
    CategoryType type, {
    String? excludingId,
  }) async {
    final found =
        await (_database.select(_database.categories)..where(
              (row) =>
                  row.ledgerId.equals(defaultLedgerId) &
                  row.categoryType.equals(type.name) &
                  row.normalizedName.equals(normalizedName(name)) &
                  row.deletedAtMs.isNull(),
            ))
            .get();
    if (found.any((row) => row.id != excludingId)) {
      throw const LedgerException('CATEGORY_NAME_EXISTS', '同类型分类名称已存在');
    }
  }

  LedgerCategory _map(Category row) {
    return LedgerCategory(
      id: row.id,
      ledgerId: row.ledgerId,
      name: row.name,
      type: CategoryType.fromDatabase(row.categoryType),
      enabled: row.enabled,
      version: row.version,
      iconCode: row.iconCode,
      systemKey: row.systemKey,
    );
  }

  LedgerCategory _mapQueryRow(QueryRow row) => LedgerCategory(
    id: row.read<String>('id'),
    ledgerId: row.read<String>('ledger_id'),
    name: row.read<String>('name'),
    type: CategoryType.fromDatabase(row.read<String>('category_type')),
    enabled: row.read<int>('enabled') == 1,
    version: row.read<int>('version'),
    iconCode: row.readNullable<String>('icon_code'),
    systemKey: row.readNullable<String>('system_key'),
  );
}
