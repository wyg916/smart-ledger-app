// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $LedgersTable extends Ledgers with TableInfo<$LedgersTable, Ledger> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LedgersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyCodeMeta = const VerificationMeta(
    'currencyCode',
  );
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
    'currency_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('CNY'),
  );
  static const VerificationMeta _timeZoneIdMeta = const VerificationMeta(
    'timeZoneId',
  );
  @override
  late final GeneratedColumn<String> timeZoneId = GeneratedColumn<String>(
    'time_zone_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isDefaultMeta = const VerificationMeta(
    'isDefault',
  );
  @override
  late final GeneratedColumn<bool> isDefault = GeneratedColumn<bool>(
    'is_default',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_default" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _settingsJsonMeta = const VerificationMeta(
    'settingsJson',
  );
  @override
  late final GeneratedColumn<String> settingsJson = GeneratedColumn<String>(
    'settings_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMsMeta = const VerificationMeta(
    'createdAtMs',
  );
  @override
  late final GeneratedColumn<int> createdAtMs = GeneratedColumn<int>(
    'created_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMsMeta = const VerificationMeta(
    'updatedAtMs',
  );
  @override
  late final GeneratedColumn<int> updatedAtMs = GeneratedColumn<int>(
    'updated_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMsMeta = const VerificationMeta(
    'deletedAtMs',
  );
  @override
  late final GeneratedColumn<int> deletedAtMs = GeneratedColumn<int>(
    'deleted_at_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _lastModifiedDeviceIdMeta =
      const VerificationMeta('lastModifiedDeviceId');
  @override
  late final GeneratedColumn<String> lastModifiedDeviceId =
      GeneratedColumn<String>(
        'last_modified_device_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _legacyIdMeta = const VerificationMeta(
    'legacyId',
  );
  @override
  late final GeneratedColumn<int> legacyId = GeneratedColumn<int>(
    'legacy_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    currencyCode,
    timeZoneId,
    isDefault,
    settingsJson,
    createdAtMs,
    updatedAtMs,
    deletedAtMs,
    version,
    lastModifiedDeviceId,
    syncStatus,
    legacyId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ledgers';
  @override
  VerificationContext validateIntegrity(
    Insertable<Ledger> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('currency_code')) {
      context.handle(
        _currencyCodeMeta,
        currencyCode.isAcceptableOrUnknown(
          data['currency_code']!,
          _currencyCodeMeta,
        ),
      );
    }
    if (data.containsKey('time_zone_id')) {
      context.handle(
        _timeZoneIdMeta,
        timeZoneId.isAcceptableOrUnknown(
          data['time_zone_id']!,
          _timeZoneIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_timeZoneIdMeta);
    }
    if (data.containsKey('is_default')) {
      context.handle(
        _isDefaultMeta,
        isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta),
      );
    }
    if (data.containsKey('settings_json')) {
      context.handle(
        _settingsJsonMeta,
        settingsJson.isAcceptableOrUnknown(
          data['settings_json']!,
          _settingsJsonMeta,
        ),
      );
    }
    if (data.containsKey('created_at_ms')) {
      context.handle(
        _createdAtMsMeta,
        createdAtMs.isAcceptableOrUnknown(
          data['created_at_ms']!,
          _createdAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtMsMeta);
    }
    if (data.containsKey('updated_at_ms')) {
      context.handle(
        _updatedAtMsMeta,
        updatedAtMs.isAcceptableOrUnknown(
          data['updated_at_ms']!,
          _updatedAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMsMeta);
    }
    if (data.containsKey('deleted_at_ms')) {
      context.handle(
        _deletedAtMsMeta,
        deletedAtMs.isAcceptableOrUnknown(
          data['deleted_at_ms']!,
          _deletedAtMsMeta,
        ),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('last_modified_device_id')) {
      context.handle(
        _lastModifiedDeviceIdMeta,
        lastModifiedDeviceId.isAcceptableOrUnknown(
          data['last_modified_device_id']!,
          _lastModifiedDeviceIdMeta,
        ),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('legacy_id')) {
      context.handle(
        _legacyIdMeta,
        legacyId.isAcceptableOrUnknown(data['legacy_id']!, _legacyIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Ledger map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Ledger(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
      )!,
      timeZoneId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}time_zone_id'],
      )!,
      isDefault: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_default'],
      )!,
      settingsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}settings_json'],
      ),
      createdAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_ms'],
      )!,
      updatedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_ms'],
      )!,
      deletedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at_ms'],
      ),
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      lastModifiedDeviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_modified_device_id'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      legacyId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}legacy_id'],
      ),
    );
  }

  @override
  $LedgersTable createAlias(String alias) {
    return $LedgersTable(attachedDatabase, alias);
  }
}

class Ledger extends DataClass implements Insertable<Ledger> {
  final String id;
  final String name;
  final String currencyCode;
  final String timeZoneId;
  final bool isDefault;
  final String? settingsJson;
  final int createdAtMs;
  final int updatedAtMs;
  final int? deletedAtMs;
  final int version;
  final String? lastModifiedDeviceId;
  final String syncStatus;
  final int? legacyId;
  const Ledger({
    required this.id,
    required this.name,
    required this.currencyCode,
    required this.timeZoneId,
    required this.isDefault,
    this.settingsJson,
    required this.createdAtMs,
    required this.updatedAtMs,
    this.deletedAtMs,
    required this.version,
    this.lastModifiedDeviceId,
    required this.syncStatus,
    this.legacyId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['currency_code'] = Variable<String>(currencyCode);
    map['time_zone_id'] = Variable<String>(timeZoneId);
    map['is_default'] = Variable<bool>(isDefault);
    if (!nullToAbsent || settingsJson != null) {
      map['settings_json'] = Variable<String>(settingsJson);
    }
    map['created_at_ms'] = Variable<int>(createdAtMs);
    map['updated_at_ms'] = Variable<int>(updatedAtMs);
    if (!nullToAbsent || deletedAtMs != null) {
      map['deleted_at_ms'] = Variable<int>(deletedAtMs);
    }
    map['version'] = Variable<int>(version);
    if (!nullToAbsent || lastModifiedDeviceId != null) {
      map['last_modified_device_id'] = Variable<String>(lastModifiedDeviceId);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    if (!nullToAbsent || legacyId != null) {
      map['legacy_id'] = Variable<int>(legacyId);
    }
    return map;
  }

  LedgersCompanion toCompanion(bool nullToAbsent) {
    return LedgersCompanion(
      id: Value(id),
      name: Value(name),
      currencyCode: Value(currencyCode),
      timeZoneId: Value(timeZoneId),
      isDefault: Value(isDefault),
      settingsJson: settingsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(settingsJson),
      createdAtMs: Value(createdAtMs),
      updatedAtMs: Value(updatedAtMs),
      deletedAtMs: deletedAtMs == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAtMs),
      version: Value(version),
      lastModifiedDeviceId: lastModifiedDeviceId == null && nullToAbsent
          ? const Value.absent()
          : Value(lastModifiedDeviceId),
      syncStatus: Value(syncStatus),
      legacyId: legacyId == null && nullToAbsent
          ? const Value.absent()
          : Value(legacyId),
    );
  }

  factory Ledger.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Ledger(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      timeZoneId: serializer.fromJson<String>(json['timeZoneId']),
      isDefault: serializer.fromJson<bool>(json['isDefault']),
      settingsJson: serializer.fromJson<String?>(json['settingsJson']),
      createdAtMs: serializer.fromJson<int>(json['createdAtMs']),
      updatedAtMs: serializer.fromJson<int>(json['updatedAtMs']),
      deletedAtMs: serializer.fromJson<int?>(json['deletedAtMs']),
      version: serializer.fromJson<int>(json['version']),
      lastModifiedDeviceId: serializer.fromJson<String?>(
        json['lastModifiedDeviceId'],
      ),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      legacyId: serializer.fromJson<int?>(json['legacyId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'timeZoneId': serializer.toJson<String>(timeZoneId),
      'isDefault': serializer.toJson<bool>(isDefault),
      'settingsJson': serializer.toJson<String?>(settingsJson),
      'createdAtMs': serializer.toJson<int>(createdAtMs),
      'updatedAtMs': serializer.toJson<int>(updatedAtMs),
      'deletedAtMs': serializer.toJson<int?>(deletedAtMs),
      'version': serializer.toJson<int>(version),
      'lastModifiedDeviceId': serializer.toJson<String?>(lastModifiedDeviceId),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'legacyId': serializer.toJson<int?>(legacyId),
    };
  }

  Ledger copyWith({
    String? id,
    String? name,
    String? currencyCode,
    String? timeZoneId,
    bool? isDefault,
    Value<String?> settingsJson = const Value.absent(),
    int? createdAtMs,
    int? updatedAtMs,
    Value<int?> deletedAtMs = const Value.absent(),
    int? version,
    Value<String?> lastModifiedDeviceId = const Value.absent(),
    String? syncStatus,
    Value<int?> legacyId = const Value.absent(),
  }) => Ledger(
    id: id ?? this.id,
    name: name ?? this.name,
    currencyCode: currencyCode ?? this.currencyCode,
    timeZoneId: timeZoneId ?? this.timeZoneId,
    isDefault: isDefault ?? this.isDefault,
    settingsJson: settingsJson.present ? settingsJson.value : this.settingsJson,
    createdAtMs: createdAtMs ?? this.createdAtMs,
    updatedAtMs: updatedAtMs ?? this.updatedAtMs,
    deletedAtMs: deletedAtMs.present ? deletedAtMs.value : this.deletedAtMs,
    version: version ?? this.version,
    lastModifiedDeviceId: lastModifiedDeviceId.present
        ? lastModifiedDeviceId.value
        : this.lastModifiedDeviceId,
    syncStatus: syncStatus ?? this.syncStatus,
    legacyId: legacyId.present ? legacyId.value : this.legacyId,
  );
  Ledger copyWithCompanion(LedgersCompanion data) {
    return Ledger(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      timeZoneId: data.timeZoneId.present
          ? data.timeZoneId.value
          : this.timeZoneId,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
      settingsJson: data.settingsJson.present
          ? data.settingsJson.value
          : this.settingsJson,
      createdAtMs: data.createdAtMs.present
          ? data.createdAtMs.value
          : this.createdAtMs,
      updatedAtMs: data.updatedAtMs.present
          ? data.updatedAtMs.value
          : this.updatedAtMs,
      deletedAtMs: data.deletedAtMs.present
          ? data.deletedAtMs.value
          : this.deletedAtMs,
      version: data.version.present ? data.version.value : this.version,
      lastModifiedDeviceId: data.lastModifiedDeviceId.present
          ? data.lastModifiedDeviceId.value
          : this.lastModifiedDeviceId,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      legacyId: data.legacyId.present ? data.legacyId.value : this.legacyId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Ledger(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('timeZoneId: $timeZoneId, ')
          ..write('isDefault: $isDefault, ')
          ..write('settingsJson: $settingsJson, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('updatedAtMs: $updatedAtMs, ')
          ..write('deletedAtMs: $deletedAtMs, ')
          ..write('version: $version, ')
          ..write('lastModifiedDeviceId: $lastModifiedDeviceId, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('legacyId: $legacyId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    currencyCode,
    timeZoneId,
    isDefault,
    settingsJson,
    createdAtMs,
    updatedAtMs,
    deletedAtMs,
    version,
    lastModifiedDeviceId,
    syncStatus,
    legacyId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Ledger &&
          other.id == this.id &&
          other.name == this.name &&
          other.currencyCode == this.currencyCode &&
          other.timeZoneId == this.timeZoneId &&
          other.isDefault == this.isDefault &&
          other.settingsJson == this.settingsJson &&
          other.createdAtMs == this.createdAtMs &&
          other.updatedAtMs == this.updatedAtMs &&
          other.deletedAtMs == this.deletedAtMs &&
          other.version == this.version &&
          other.lastModifiedDeviceId == this.lastModifiedDeviceId &&
          other.syncStatus == this.syncStatus &&
          other.legacyId == this.legacyId);
}

class LedgersCompanion extends UpdateCompanion<Ledger> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> currencyCode;
  final Value<String> timeZoneId;
  final Value<bool> isDefault;
  final Value<String?> settingsJson;
  final Value<int> createdAtMs;
  final Value<int> updatedAtMs;
  final Value<int?> deletedAtMs;
  final Value<int> version;
  final Value<String?> lastModifiedDeviceId;
  final Value<String> syncStatus;
  final Value<int?> legacyId;
  final Value<int> rowid;
  const LedgersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.timeZoneId = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.settingsJson = const Value.absent(),
    this.createdAtMs = const Value.absent(),
    this.updatedAtMs = const Value.absent(),
    this.deletedAtMs = const Value.absent(),
    this.version = const Value.absent(),
    this.lastModifiedDeviceId = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.legacyId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LedgersCompanion.insert({
    required String id,
    required String name,
    this.currencyCode = const Value.absent(),
    required String timeZoneId,
    this.isDefault = const Value.absent(),
    this.settingsJson = const Value.absent(),
    required int createdAtMs,
    required int updatedAtMs,
    this.deletedAtMs = const Value.absent(),
    this.version = const Value.absent(),
    this.lastModifiedDeviceId = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.legacyId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       timeZoneId = Value(timeZoneId),
       createdAtMs = Value(createdAtMs),
       updatedAtMs = Value(updatedAtMs);
  static Insertable<Ledger> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? currencyCode,
    Expression<String>? timeZoneId,
    Expression<bool>? isDefault,
    Expression<String>? settingsJson,
    Expression<int>? createdAtMs,
    Expression<int>? updatedAtMs,
    Expression<int>? deletedAtMs,
    Expression<int>? version,
    Expression<String>? lastModifiedDeviceId,
    Expression<String>? syncStatus,
    Expression<int>? legacyId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (timeZoneId != null) 'time_zone_id': timeZoneId,
      if (isDefault != null) 'is_default': isDefault,
      if (settingsJson != null) 'settings_json': settingsJson,
      if (createdAtMs != null) 'created_at_ms': createdAtMs,
      if (updatedAtMs != null) 'updated_at_ms': updatedAtMs,
      if (deletedAtMs != null) 'deleted_at_ms': deletedAtMs,
      if (version != null) 'version': version,
      if (lastModifiedDeviceId != null)
        'last_modified_device_id': lastModifiedDeviceId,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (legacyId != null) 'legacy_id': legacyId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LedgersCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? currencyCode,
    Value<String>? timeZoneId,
    Value<bool>? isDefault,
    Value<String?>? settingsJson,
    Value<int>? createdAtMs,
    Value<int>? updatedAtMs,
    Value<int?>? deletedAtMs,
    Value<int>? version,
    Value<String?>? lastModifiedDeviceId,
    Value<String>? syncStatus,
    Value<int?>? legacyId,
    Value<int>? rowid,
  }) {
    return LedgersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      currencyCode: currencyCode ?? this.currencyCode,
      timeZoneId: timeZoneId ?? this.timeZoneId,
      isDefault: isDefault ?? this.isDefault,
      settingsJson: settingsJson ?? this.settingsJson,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
      deletedAtMs: deletedAtMs ?? this.deletedAtMs,
      version: version ?? this.version,
      lastModifiedDeviceId: lastModifiedDeviceId ?? this.lastModifiedDeviceId,
      syncStatus: syncStatus ?? this.syncStatus,
      legacyId: legacyId ?? this.legacyId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (timeZoneId.present) {
      map['time_zone_id'] = Variable<String>(timeZoneId.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<bool>(isDefault.value);
    }
    if (settingsJson.present) {
      map['settings_json'] = Variable<String>(settingsJson.value);
    }
    if (createdAtMs.present) {
      map['created_at_ms'] = Variable<int>(createdAtMs.value);
    }
    if (updatedAtMs.present) {
      map['updated_at_ms'] = Variable<int>(updatedAtMs.value);
    }
    if (deletedAtMs.present) {
      map['deleted_at_ms'] = Variable<int>(deletedAtMs.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (lastModifiedDeviceId.present) {
      map['last_modified_device_id'] = Variable<String>(
        lastModifiedDeviceId.value,
      );
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (legacyId.present) {
      map['legacy_id'] = Variable<int>(legacyId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LedgersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('timeZoneId: $timeZoneId, ')
          ..write('isDefault: $isDefault, ')
          ..write('settingsJson: $settingsJson, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('updatedAtMs: $updatedAtMs, ')
          ..write('deletedAtMs: $deletedAtMs, ')
          ..write('version: $version, ')
          ..write('lastModifiedDeviceId: $lastModifiedDeviceId, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('legacyId: $legacyId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AccountsTable extends Accounts with TableInfo<$AccountsTable, Account> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ledgerIdMeta = const VerificationMeta(
    'ledgerId',
  );
  @override
  late final GeneratedColumn<String> ledgerId = GeneratedColumn<String>(
    'ledger_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES ledgers (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _normalizedNameMeta = const VerificationMeta(
    'normalizedName',
  );
  @override
  late final GeneratedColumn<String> normalizedName = GeneratedColumn<String>(
    'normalized_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountTypeMeta = const VerificationMeta(
    'accountType',
  );
  @override
  late final GeneratedColumn<String> accountType = GeneratedColumn<String>(
    'account_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('cash'),
  );
  static const VerificationMeta _openingBalanceMinorMeta =
      const VerificationMeta('openingBalanceMinor');
  @override
  late final GeneratedColumn<int> openingBalanceMinor = GeneratedColumn<int>(
    'opening_balance_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _iconCodeMeta = const VerificationMeta(
    'iconCode',
  );
  @override
  late final GeneratedColumn<String> iconCode = GeneratedColumn<String>(
    'icon_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtMsMeta = const VerificationMeta(
    'createdAtMs',
  );
  @override
  late final GeneratedColumn<int> createdAtMs = GeneratedColumn<int>(
    'created_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMsMeta = const VerificationMeta(
    'updatedAtMs',
  );
  @override
  late final GeneratedColumn<int> updatedAtMs = GeneratedColumn<int>(
    'updated_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMsMeta = const VerificationMeta(
    'deletedAtMs',
  );
  @override
  late final GeneratedColumn<int> deletedAtMs = GeneratedColumn<int>(
    'deleted_at_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _lastModifiedDeviceIdMeta =
      const VerificationMeta('lastModifiedDeviceId');
  @override
  late final GeneratedColumn<String> lastModifiedDeviceId =
      GeneratedColumn<String>(
        'last_modified_device_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _legacyIdMeta = const VerificationMeta(
    'legacyId',
  );
  @override
  late final GeneratedColumn<int> legacyId = GeneratedColumn<int>(
    'legacy_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    ledgerId,
    name,
    normalizedName,
    accountType,
    openingBalanceMinor,
    iconCode,
    sortOrder,
    enabled,
    createdAtMs,
    updatedAtMs,
    deletedAtMs,
    version,
    lastModifiedDeviceId,
    syncStatus,
    legacyId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'accounts';
  @override
  VerificationContext validateIntegrity(
    Insertable<Account> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('ledger_id')) {
      context.handle(
        _ledgerIdMeta,
        ledgerId.isAcceptableOrUnknown(data['ledger_id']!, _ledgerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ledgerIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('normalized_name')) {
      context.handle(
        _normalizedNameMeta,
        normalizedName.isAcceptableOrUnknown(
          data['normalized_name']!,
          _normalizedNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_normalizedNameMeta);
    }
    if (data.containsKey('account_type')) {
      context.handle(
        _accountTypeMeta,
        accountType.isAcceptableOrUnknown(
          data['account_type']!,
          _accountTypeMeta,
        ),
      );
    }
    if (data.containsKey('opening_balance_minor')) {
      context.handle(
        _openingBalanceMinorMeta,
        openingBalanceMinor.isAcceptableOrUnknown(
          data['opening_balance_minor']!,
          _openingBalanceMinorMeta,
        ),
      );
    }
    if (data.containsKey('icon_code')) {
      context.handle(
        _iconCodeMeta,
        iconCode.isAcceptableOrUnknown(data['icon_code']!, _iconCodeMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('created_at_ms')) {
      context.handle(
        _createdAtMsMeta,
        createdAtMs.isAcceptableOrUnknown(
          data['created_at_ms']!,
          _createdAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtMsMeta);
    }
    if (data.containsKey('updated_at_ms')) {
      context.handle(
        _updatedAtMsMeta,
        updatedAtMs.isAcceptableOrUnknown(
          data['updated_at_ms']!,
          _updatedAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMsMeta);
    }
    if (data.containsKey('deleted_at_ms')) {
      context.handle(
        _deletedAtMsMeta,
        deletedAtMs.isAcceptableOrUnknown(
          data['deleted_at_ms']!,
          _deletedAtMsMeta,
        ),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('last_modified_device_id')) {
      context.handle(
        _lastModifiedDeviceIdMeta,
        lastModifiedDeviceId.isAcceptableOrUnknown(
          data['last_modified_device_id']!,
          _lastModifiedDeviceIdMeta,
        ),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('legacy_id')) {
      context.handle(
        _legacyIdMeta,
        legacyId.isAcceptableOrUnknown(data['legacy_id']!, _legacyIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {ledgerId, normalizedName},
  ];
  @override
  Account map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Account(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      ledgerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ledger_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      normalizedName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}normalized_name'],
      )!,
      accountType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_type'],
      )!,
      openingBalanceMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}opening_balance_minor'],
      )!,
      iconCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon_code'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      createdAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_ms'],
      )!,
      updatedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_ms'],
      )!,
      deletedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at_ms'],
      ),
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      lastModifiedDeviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_modified_device_id'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      legacyId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}legacy_id'],
      ),
    );
  }

  @override
  $AccountsTable createAlias(String alias) {
    return $AccountsTable(attachedDatabase, alias);
  }
}

class Account extends DataClass implements Insertable<Account> {
  final String id;
  final String ledgerId;
  final String name;
  final String normalizedName;
  final String accountType;
  final int openingBalanceMinor;
  final String? iconCode;
  final int sortOrder;
  final bool enabled;
  final int createdAtMs;
  final int updatedAtMs;
  final int? deletedAtMs;
  final int version;
  final String? lastModifiedDeviceId;
  final String syncStatus;
  final int? legacyId;
  const Account({
    required this.id,
    required this.ledgerId,
    required this.name,
    required this.normalizedName,
    required this.accountType,
    required this.openingBalanceMinor,
    this.iconCode,
    required this.sortOrder,
    required this.enabled,
    required this.createdAtMs,
    required this.updatedAtMs,
    this.deletedAtMs,
    required this.version,
    this.lastModifiedDeviceId,
    required this.syncStatus,
    this.legacyId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['ledger_id'] = Variable<String>(ledgerId);
    map['name'] = Variable<String>(name);
    map['normalized_name'] = Variable<String>(normalizedName);
    map['account_type'] = Variable<String>(accountType);
    map['opening_balance_minor'] = Variable<int>(openingBalanceMinor);
    if (!nullToAbsent || iconCode != null) {
      map['icon_code'] = Variable<String>(iconCode);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    map['enabled'] = Variable<bool>(enabled);
    map['created_at_ms'] = Variable<int>(createdAtMs);
    map['updated_at_ms'] = Variable<int>(updatedAtMs);
    if (!nullToAbsent || deletedAtMs != null) {
      map['deleted_at_ms'] = Variable<int>(deletedAtMs);
    }
    map['version'] = Variable<int>(version);
    if (!nullToAbsent || lastModifiedDeviceId != null) {
      map['last_modified_device_id'] = Variable<String>(lastModifiedDeviceId);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    if (!nullToAbsent || legacyId != null) {
      map['legacy_id'] = Variable<int>(legacyId);
    }
    return map;
  }

  AccountsCompanion toCompanion(bool nullToAbsent) {
    return AccountsCompanion(
      id: Value(id),
      ledgerId: Value(ledgerId),
      name: Value(name),
      normalizedName: Value(normalizedName),
      accountType: Value(accountType),
      openingBalanceMinor: Value(openingBalanceMinor),
      iconCode: iconCode == null && nullToAbsent
          ? const Value.absent()
          : Value(iconCode),
      sortOrder: Value(sortOrder),
      enabled: Value(enabled),
      createdAtMs: Value(createdAtMs),
      updatedAtMs: Value(updatedAtMs),
      deletedAtMs: deletedAtMs == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAtMs),
      version: Value(version),
      lastModifiedDeviceId: lastModifiedDeviceId == null && nullToAbsent
          ? const Value.absent()
          : Value(lastModifiedDeviceId),
      syncStatus: Value(syncStatus),
      legacyId: legacyId == null && nullToAbsent
          ? const Value.absent()
          : Value(legacyId),
    );
  }

  factory Account.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Account(
      id: serializer.fromJson<String>(json['id']),
      ledgerId: serializer.fromJson<String>(json['ledgerId']),
      name: serializer.fromJson<String>(json['name']),
      normalizedName: serializer.fromJson<String>(json['normalizedName']),
      accountType: serializer.fromJson<String>(json['accountType']),
      openingBalanceMinor: serializer.fromJson<int>(
        json['openingBalanceMinor'],
      ),
      iconCode: serializer.fromJson<String?>(json['iconCode']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      createdAtMs: serializer.fromJson<int>(json['createdAtMs']),
      updatedAtMs: serializer.fromJson<int>(json['updatedAtMs']),
      deletedAtMs: serializer.fromJson<int?>(json['deletedAtMs']),
      version: serializer.fromJson<int>(json['version']),
      lastModifiedDeviceId: serializer.fromJson<String?>(
        json['lastModifiedDeviceId'],
      ),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      legacyId: serializer.fromJson<int?>(json['legacyId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'ledgerId': serializer.toJson<String>(ledgerId),
      'name': serializer.toJson<String>(name),
      'normalizedName': serializer.toJson<String>(normalizedName),
      'accountType': serializer.toJson<String>(accountType),
      'openingBalanceMinor': serializer.toJson<int>(openingBalanceMinor),
      'iconCode': serializer.toJson<String?>(iconCode),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'enabled': serializer.toJson<bool>(enabled),
      'createdAtMs': serializer.toJson<int>(createdAtMs),
      'updatedAtMs': serializer.toJson<int>(updatedAtMs),
      'deletedAtMs': serializer.toJson<int?>(deletedAtMs),
      'version': serializer.toJson<int>(version),
      'lastModifiedDeviceId': serializer.toJson<String?>(lastModifiedDeviceId),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'legacyId': serializer.toJson<int?>(legacyId),
    };
  }

  Account copyWith({
    String? id,
    String? ledgerId,
    String? name,
    String? normalizedName,
    String? accountType,
    int? openingBalanceMinor,
    Value<String?> iconCode = const Value.absent(),
    int? sortOrder,
    bool? enabled,
    int? createdAtMs,
    int? updatedAtMs,
    Value<int?> deletedAtMs = const Value.absent(),
    int? version,
    Value<String?> lastModifiedDeviceId = const Value.absent(),
    String? syncStatus,
    Value<int?> legacyId = const Value.absent(),
  }) => Account(
    id: id ?? this.id,
    ledgerId: ledgerId ?? this.ledgerId,
    name: name ?? this.name,
    normalizedName: normalizedName ?? this.normalizedName,
    accountType: accountType ?? this.accountType,
    openingBalanceMinor: openingBalanceMinor ?? this.openingBalanceMinor,
    iconCode: iconCode.present ? iconCode.value : this.iconCode,
    sortOrder: sortOrder ?? this.sortOrder,
    enabled: enabled ?? this.enabled,
    createdAtMs: createdAtMs ?? this.createdAtMs,
    updatedAtMs: updatedAtMs ?? this.updatedAtMs,
    deletedAtMs: deletedAtMs.present ? deletedAtMs.value : this.deletedAtMs,
    version: version ?? this.version,
    lastModifiedDeviceId: lastModifiedDeviceId.present
        ? lastModifiedDeviceId.value
        : this.lastModifiedDeviceId,
    syncStatus: syncStatus ?? this.syncStatus,
    legacyId: legacyId.present ? legacyId.value : this.legacyId,
  );
  Account copyWithCompanion(AccountsCompanion data) {
    return Account(
      id: data.id.present ? data.id.value : this.id,
      ledgerId: data.ledgerId.present ? data.ledgerId.value : this.ledgerId,
      name: data.name.present ? data.name.value : this.name,
      normalizedName: data.normalizedName.present
          ? data.normalizedName.value
          : this.normalizedName,
      accountType: data.accountType.present
          ? data.accountType.value
          : this.accountType,
      openingBalanceMinor: data.openingBalanceMinor.present
          ? data.openingBalanceMinor.value
          : this.openingBalanceMinor,
      iconCode: data.iconCode.present ? data.iconCode.value : this.iconCode,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      createdAtMs: data.createdAtMs.present
          ? data.createdAtMs.value
          : this.createdAtMs,
      updatedAtMs: data.updatedAtMs.present
          ? data.updatedAtMs.value
          : this.updatedAtMs,
      deletedAtMs: data.deletedAtMs.present
          ? data.deletedAtMs.value
          : this.deletedAtMs,
      version: data.version.present ? data.version.value : this.version,
      lastModifiedDeviceId: data.lastModifiedDeviceId.present
          ? data.lastModifiedDeviceId.value
          : this.lastModifiedDeviceId,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      legacyId: data.legacyId.present ? data.legacyId.value : this.legacyId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Account(')
          ..write('id: $id, ')
          ..write('ledgerId: $ledgerId, ')
          ..write('name: $name, ')
          ..write('normalizedName: $normalizedName, ')
          ..write('accountType: $accountType, ')
          ..write('openingBalanceMinor: $openingBalanceMinor, ')
          ..write('iconCode: $iconCode, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('enabled: $enabled, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('updatedAtMs: $updatedAtMs, ')
          ..write('deletedAtMs: $deletedAtMs, ')
          ..write('version: $version, ')
          ..write('lastModifiedDeviceId: $lastModifiedDeviceId, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('legacyId: $legacyId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    ledgerId,
    name,
    normalizedName,
    accountType,
    openingBalanceMinor,
    iconCode,
    sortOrder,
    enabled,
    createdAtMs,
    updatedAtMs,
    deletedAtMs,
    version,
    lastModifiedDeviceId,
    syncStatus,
    legacyId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Account &&
          other.id == this.id &&
          other.ledgerId == this.ledgerId &&
          other.name == this.name &&
          other.normalizedName == this.normalizedName &&
          other.accountType == this.accountType &&
          other.openingBalanceMinor == this.openingBalanceMinor &&
          other.iconCode == this.iconCode &&
          other.sortOrder == this.sortOrder &&
          other.enabled == this.enabled &&
          other.createdAtMs == this.createdAtMs &&
          other.updatedAtMs == this.updatedAtMs &&
          other.deletedAtMs == this.deletedAtMs &&
          other.version == this.version &&
          other.lastModifiedDeviceId == this.lastModifiedDeviceId &&
          other.syncStatus == this.syncStatus &&
          other.legacyId == this.legacyId);
}

class AccountsCompanion extends UpdateCompanion<Account> {
  final Value<String> id;
  final Value<String> ledgerId;
  final Value<String> name;
  final Value<String> normalizedName;
  final Value<String> accountType;
  final Value<int> openingBalanceMinor;
  final Value<String?> iconCode;
  final Value<int> sortOrder;
  final Value<bool> enabled;
  final Value<int> createdAtMs;
  final Value<int> updatedAtMs;
  final Value<int?> deletedAtMs;
  final Value<int> version;
  final Value<String?> lastModifiedDeviceId;
  final Value<String> syncStatus;
  final Value<int?> legacyId;
  final Value<int> rowid;
  const AccountsCompanion({
    this.id = const Value.absent(),
    this.ledgerId = const Value.absent(),
    this.name = const Value.absent(),
    this.normalizedName = const Value.absent(),
    this.accountType = const Value.absent(),
    this.openingBalanceMinor = const Value.absent(),
    this.iconCode = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.enabled = const Value.absent(),
    this.createdAtMs = const Value.absent(),
    this.updatedAtMs = const Value.absent(),
    this.deletedAtMs = const Value.absent(),
    this.version = const Value.absent(),
    this.lastModifiedDeviceId = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.legacyId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AccountsCompanion.insert({
    required String id,
    required String ledgerId,
    required String name,
    required String normalizedName,
    this.accountType = const Value.absent(),
    this.openingBalanceMinor = const Value.absent(),
    this.iconCode = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.enabled = const Value.absent(),
    required int createdAtMs,
    required int updatedAtMs,
    this.deletedAtMs = const Value.absent(),
    this.version = const Value.absent(),
    this.lastModifiedDeviceId = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.legacyId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       ledgerId = Value(ledgerId),
       name = Value(name),
       normalizedName = Value(normalizedName),
       createdAtMs = Value(createdAtMs),
       updatedAtMs = Value(updatedAtMs);
  static Insertable<Account> custom({
    Expression<String>? id,
    Expression<String>? ledgerId,
    Expression<String>? name,
    Expression<String>? normalizedName,
    Expression<String>? accountType,
    Expression<int>? openingBalanceMinor,
    Expression<String>? iconCode,
    Expression<int>? sortOrder,
    Expression<bool>? enabled,
    Expression<int>? createdAtMs,
    Expression<int>? updatedAtMs,
    Expression<int>? deletedAtMs,
    Expression<int>? version,
    Expression<String>? lastModifiedDeviceId,
    Expression<String>? syncStatus,
    Expression<int>? legacyId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ledgerId != null) 'ledger_id': ledgerId,
      if (name != null) 'name': name,
      if (normalizedName != null) 'normalized_name': normalizedName,
      if (accountType != null) 'account_type': accountType,
      if (openingBalanceMinor != null)
        'opening_balance_minor': openingBalanceMinor,
      if (iconCode != null) 'icon_code': iconCode,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (enabled != null) 'enabled': enabled,
      if (createdAtMs != null) 'created_at_ms': createdAtMs,
      if (updatedAtMs != null) 'updated_at_ms': updatedAtMs,
      if (deletedAtMs != null) 'deleted_at_ms': deletedAtMs,
      if (version != null) 'version': version,
      if (lastModifiedDeviceId != null)
        'last_modified_device_id': lastModifiedDeviceId,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (legacyId != null) 'legacy_id': legacyId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AccountsCompanion copyWith({
    Value<String>? id,
    Value<String>? ledgerId,
    Value<String>? name,
    Value<String>? normalizedName,
    Value<String>? accountType,
    Value<int>? openingBalanceMinor,
    Value<String?>? iconCode,
    Value<int>? sortOrder,
    Value<bool>? enabled,
    Value<int>? createdAtMs,
    Value<int>? updatedAtMs,
    Value<int?>? deletedAtMs,
    Value<int>? version,
    Value<String?>? lastModifiedDeviceId,
    Value<String>? syncStatus,
    Value<int?>? legacyId,
    Value<int>? rowid,
  }) {
    return AccountsCompanion(
      id: id ?? this.id,
      ledgerId: ledgerId ?? this.ledgerId,
      name: name ?? this.name,
      normalizedName: normalizedName ?? this.normalizedName,
      accountType: accountType ?? this.accountType,
      openingBalanceMinor: openingBalanceMinor ?? this.openingBalanceMinor,
      iconCode: iconCode ?? this.iconCode,
      sortOrder: sortOrder ?? this.sortOrder,
      enabled: enabled ?? this.enabled,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
      deletedAtMs: deletedAtMs ?? this.deletedAtMs,
      version: version ?? this.version,
      lastModifiedDeviceId: lastModifiedDeviceId ?? this.lastModifiedDeviceId,
      syncStatus: syncStatus ?? this.syncStatus,
      legacyId: legacyId ?? this.legacyId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (ledgerId.present) {
      map['ledger_id'] = Variable<String>(ledgerId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (normalizedName.present) {
      map['normalized_name'] = Variable<String>(normalizedName.value);
    }
    if (accountType.present) {
      map['account_type'] = Variable<String>(accountType.value);
    }
    if (openingBalanceMinor.present) {
      map['opening_balance_minor'] = Variable<int>(openingBalanceMinor.value);
    }
    if (iconCode.present) {
      map['icon_code'] = Variable<String>(iconCode.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (createdAtMs.present) {
      map['created_at_ms'] = Variable<int>(createdAtMs.value);
    }
    if (updatedAtMs.present) {
      map['updated_at_ms'] = Variable<int>(updatedAtMs.value);
    }
    if (deletedAtMs.present) {
      map['deleted_at_ms'] = Variable<int>(deletedAtMs.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (lastModifiedDeviceId.present) {
      map['last_modified_device_id'] = Variable<String>(
        lastModifiedDeviceId.value,
      );
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (legacyId.present) {
      map['legacy_id'] = Variable<int>(legacyId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountsCompanion(')
          ..write('id: $id, ')
          ..write('ledgerId: $ledgerId, ')
          ..write('name: $name, ')
          ..write('normalizedName: $normalizedName, ')
          ..write('accountType: $accountType, ')
          ..write('openingBalanceMinor: $openingBalanceMinor, ')
          ..write('iconCode: $iconCode, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('enabled: $enabled, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('updatedAtMs: $updatedAtMs, ')
          ..write('deletedAtMs: $deletedAtMs, ')
          ..write('version: $version, ')
          ..write('lastModifiedDeviceId: $lastModifiedDeviceId, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('legacyId: $legacyId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, Category> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ledgerIdMeta = const VerificationMeta(
    'ledgerId',
  );
  @override
  late final GeneratedColumn<String> ledgerId = GeneratedColumn<String>(
    'ledger_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES ledgers (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _categoryTypeMeta = const VerificationMeta(
    'categoryType',
  );
  @override
  late final GeneratedColumn<String> categoryType = GeneratedColumn<String>(
    'category_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _normalizedNameMeta = const VerificationMeta(
    'normalizedName',
  );
  @override
  late final GeneratedColumn<String> normalizedName = GeneratedColumn<String>(
    'normalized_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconCodeMeta = const VerificationMeta(
    'iconCode',
  );
  @override
  late final GeneratedColumn<String> iconCode = GeneratedColumn<String>(
    'icon_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorTokenMeta = const VerificationMeta(
    'colorToken',
  );
  @override
  late final GeneratedColumn<String> colorToken = GeneratedColumn<String>(
    'color_token',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _systemKeyMeta = const VerificationMeta(
    'systemKey',
  );
  @override
  late final GeneratedColumn<String> systemKey = GeneratedColumn<String>(
    'system_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMsMeta = const VerificationMeta(
    'createdAtMs',
  );
  @override
  late final GeneratedColumn<int> createdAtMs = GeneratedColumn<int>(
    'created_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMsMeta = const VerificationMeta(
    'updatedAtMs',
  );
  @override
  late final GeneratedColumn<int> updatedAtMs = GeneratedColumn<int>(
    'updated_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMsMeta = const VerificationMeta(
    'deletedAtMs',
  );
  @override
  late final GeneratedColumn<int> deletedAtMs = GeneratedColumn<int>(
    'deleted_at_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _lastModifiedDeviceIdMeta =
      const VerificationMeta('lastModifiedDeviceId');
  @override
  late final GeneratedColumn<String> lastModifiedDeviceId =
      GeneratedColumn<String>(
        'last_modified_device_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _legacyIdMeta = const VerificationMeta(
    'legacyId',
  );
  @override
  late final GeneratedColumn<int> legacyId = GeneratedColumn<int>(
    'legacy_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    ledgerId,
    categoryType,
    name,
    normalizedName,
    iconCode,
    colorToken,
    sortOrder,
    enabled,
    systemKey,
    createdAtMs,
    updatedAtMs,
    deletedAtMs,
    version,
    lastModifiedDeviceId,
    syncStatus,
    legacyId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<Category> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('ledger_id')) {
      context.handle(
        _ledgerIdMeta,
        ledgerId.isAcceptableOrUnknown(data['ledger_id']!, _ledgerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ledgerIdMeta);
    }
    if (data.containsKey('category_type')) {
      context.handle(
        _categoryTypeMeta,
        categoryType.isAcceptableOrUnknown(
          data['category_type']!,
          _categoryTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_categoryTypeMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('normalized_name')) {
      context.handle(
        _normalizedNameMeta,
        normalizedName.isAcceptableOrUnknown(
          data['normalized_name']!,
          _normalizedNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_normalizedNameMeta);
    }
    if (data.containsKey('icon_code')) {
      context.handle(
        _iconCodeMeta,
        iconCode.isAcceptableOrUnknown(data['icon_code']!, _iconCodeMeta),
      );
    }
    if (data.containsKey('color_token')) {
      context.handle(
        _colorTokenMeta,
        colorToken.isAcceptableOrUnknown(data['color_token']!, _colorTokenMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('system_key')) {
      context.handle(
        _systemKeyMeta,
        systemKey.isAcceptableOrUnknown(data['system_key']!, _systemKeyMeta),
      );
    }
    if (data.containsKey('created_at_ms')) {
      context.handle(
        _createdAtMsMeta,
        createdAtMs.isAcceptableOrUnknown(
          data['created_at_ms']!,
          _createdAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtMsMeta);
    }
    if (data.containsKey('updated_at_ms')) {
      context.handle(
        _updatedAtMsMeta,
        updatedAtMs.isAcceptableOrUnknown(
          data['updated_at_ms']!,
          _updatedAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMsMeta);
    }
    if (data.containsKey('deleted_at_ms')) {
      context.handle(
        _deletedAtMsMeta,
        deletedAtMs.isAcceptableOrUnknown(
          data['deleted_at_ms']!,
          _deletedAtMsMeta,
        ),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('last_modified_device_id')) {
      context.handle(
        _lastModifiedDeviceIdMeta,
        lastModifiedDeviceId.isAcceptableOrUnknown(
          data['last_modified_device_id']!,
          _lastModifiedDeviceIdMeta,
        ),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('legacy_id')) {
      context.handle(
        _legacyIdMeta,
        legacyId.isAcceptableOrUnknown(data['legacy_id']!, _legacyIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {ledgerId, categoryType, normalizedName},
    {ledgerId, systemKey},
  ];
  @override
  Category map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Category(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      ledgerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ledger_id'],
      )!,
      categoryType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_type'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      normalizedName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}normalized_name'],
      )!,
      iconCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon_code'],
      ),
      colorToken: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color_token'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      systemKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}system_key'],
      ),
      createdAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_ms'],
      )!,
      updatedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_ms'],
      )!,
      deletedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at_ms'],
      ),
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      lastModifiedDeviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_modified_device_id'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      legacyId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}legacy_id'],
      ),
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }
}

class Category extends DataClass implements Insertable<Category> {
  final String id;
  final String ledgerId;
  final String categoryType;
  final String name;
  final String normalizedName;
  final String? iconCode;
  final String? colorToken;
  final int sortOrder;
  final bool enabled;
  final String? systemKey;
  final int createdAtMs;
  final int updatedAtMs;
  final int? deletedAtMs;
  final int version;
  final String? lastModifiedDeviceId;
  final String syncStatus;
  final int? legacyId;
  const Category({
    required this.id,
    required this.ledgerId,
    required this.categoryType,
    required this.name,
    required this.normalizedName,
    this.iconCode,
    this.colorToken,
    required this.sortOrder,
    required this.enabled,
    this.systemKey,
    required this.createdAtMs,
    required this.updatedAtMs,
    this.deletedAtMs,
    required this.version,
    this.lastModifiedDeviceId,
    required this.syncStatus,
    this.legacyId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['ledger_id'] = Variable<String>(ledgerId);
    map['category_type'] = Variable<String>(categoryType);
    map['name'] = Variable<String>(name);
    map['normalized_name'] = Variable<String>(normalizedName);
    if (!nullToAbsent || iconCode != null) {
      map['icon_code'] = Variable<String>(iconCode);
    }
    if (!nullToAbsent || colorToken != null) {
      map['color_token'] = Variable<String>(colorToken);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    map['enabled'] = Variable<bool>(enabled);
    if (!nullToAbsent || systemKey != null) {
      map['system_key'] = Variable<String>(systemKey);
    }
    map['created_at_ms'] = Variable<int>(createdAtMs);
    map['updated_at_ms'] = Variable<int>(updatedAtMs);
    if (!nullToAbsent || deletedAtMs != null) {
      map['deleted_at_ms'] = Variable<int>(deletedAtMs);
    }
    map['version'] = Variable<int>(version);
    if (!nullToAbsent || lastModifiedDeviceId != null) {
      map['last_modified_device_id'] = Variable<String>(lastModifiedDeviceId);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    if (!nullToAbsent || legacyId != null) {
      map['legacy_id'] = Variable<int>(legacyId);
    }
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      ledgerId: Value(ledgerId),
      categoryType: Value(categoryType),
      name: Value(name),
      normalizedName: Value(normalizedName),
      iconCode: iconCode == null && nullToAbsent
          ? const Value.absent()
          : Value(iconCode),
      colorToken: colorToken == null && nullToAbsent
          ? const Value.absent()
          : Value(colorToken),
      sortOrder: Value(sortOrder),
      enabled: Value(enabled),
      systemKey: systemKey == null && nullToAbsent
          ? const Value.absent()
          : Value(systemKey),
      createdAtMs: Value(createdAtMs),
      updatedAtMs: Value(updatedAtMs),
      deletedAtMs: deletedAtMs == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAtMs),
      version: Value(version),
      lastModifiedDeviceId: lastModifiedDeviceId == null && nullToAbsent
          ? const Value.absent()
          : Value(lastModifiedDeviceId),
      syncStatus: Value(syncStatus),
      legacyId: legacyId == null && nullToAbsent
          ? const Value.absent()
          : Value(legacyId),
    );
  }

  factory Category.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Category(
      id: serializer.fromJson<String>(json['id']),
      ledgerId: serializer.fromJson<String>(json['ledgerId']),
      categoryType: serializer.fromJson<String>(json['categoryType']),
      name: serializer.fromJson<String>(json['name']),
      normalizedName: serializer.fromJson<String>(json['normalizedName']),
      iconCode: serializer.fromJson<String?>(json['iconCode']),
      colorToken: serializer.fromJson<String?>(json['colorToken']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      systemKey: serializer.fromJson<String?>(json['systemKey']),
      createdAtMs: serializer.fromJson<int>(json['createdAtMs']),
      updatedAtMs: serializer.fromJson<int>(json['updatedAtMs']),
      deletedAtMs: serializer.fromJson<int?>(json['deletedAtMs']),
      version: serializer.fromJson<int>(json['version']),
      lastModifiedDeviceId: serializer.fromJson<String?>(
        json['lastModifiedDeviceId'],
      ),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      legacyId: serializer.fromJson<int?>(json['legacyId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'ledgerId': serializer.toJson<String>(ledgerId),
      'categoryType': serializer.toJson<String>(categoryType),
      'name': serializer.toJson<String>(name),
      'normalizedName': serializer.toJson<String>(normalizedName),
      'iconCode': serializer.toJson<String?>(iconCode),
      'colorToken': serializer.toJson<String?>(colorToken),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'enabled': serializer.toJson<bool>(enabled),
      'systemKey': serializer.toJson<String?>(systemKey),
      'createdAtMs': serializer.toJson<int>(createdAtMs),
      'updatedAtMs': serializer.toJson<int>(updatedAtMs),
      'deletedAtMs': serializer.toJson<int?>(deletedAtMs),
      'version': serializer.toJson<int>(version),
      'lastModifiedDeviceId': serializer.toJson<String?>(lastModifiedDeviceId),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'legacyId': serializer.toJson<int?>(legacyId),
    };
  }

  Category copyWith({
    String? id,
    String? ledgerId,
    String? categoryType,
    String? name,
    String? normalizedName,
    Value<String?> iconCode = const Value.absent(),
    Value<String?> colorToken = const Value.absent(),
    int? sortOrder,
    bool? enabled,
    Value<String?> systemKey = const Value.absent(),
    int? createdAtMs,
    int? updatedAtMs,
    Value<int?> deletedAtMs = const Value.absent(),
    int? version,
    Value<String?> lastModifiedDeviceId = const Value.absent(),
    String? syncStatus,
    Value<int?> legacyId = const Value.absent(),
  }) => Category(
    id: id ?? this.id,
    ledgerId: ledgerId ?? this.ledgerId,
    categoryType: categoryType ?? this.categoryType,
    name: name ?? this.name,
    normalizedName: normalizedName ?? this.normalizedName,
    iconCode: iconCode.present ? iconCode.value : this.iconCode,
    colorToken: colorToken.present ? colorToken.value : this.colorToken,
    sortOrder: sortOrder ?? this.sortOrder,
    enabled: enabled ?? this.enabled,
    systemKey: systemKey.present ? systemKey.value : this.systemKey,
    createdAtMs: createdAtMs ?? this.createdAtMs,
    updatedAtMs: updatedAtMs ?? this.updatedAtMs,
    deletedAtMs: deletedAtMs.present ? deletedAtMs.value : this.deletedAtMs,
    version: version ?? this.version,
    lastModifiedDeviceId: lastModifiedDeviceId.present
        ? lastModifiedDeviceId.value
        : this.lastModifiedDeviceId,
    syncStatus: syncStatus ?? this.syncStatus,
    legacyId: legacyId.present ? legacyId.value : this.legacyId,
  );
  Category copyWithCompanion(CategoriesCompanion data) {
    return Category(
      id: data.id.present ? data.id.value : this.id,
      ledgerId: data.ledgerId.present ? data.ledgerId.value : this.ledgerId,
      categoryType: data.categoryType.present
          ? data.categoryType.value
          : this.categoryType,
      name: data.name.present ? data.name.value : this.name,
      normalizedName: data.normalizedName.present
          ? data.normalizedName.value
          : this.normalizedName,
      iconCode: data.iconCode.present ? data.iconCode.value : this.iconCode,
      colorToken: data.colorToken.present
          ? data.colorToken.value
          : this.colorToken,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      systemKey: data.systemKey.present ? data.systemKey.value : this.systemKey,
      createdAtMs: data.createdAtMs.present
          ? data.createdAtMs.value
          : this.createdAtMs,
      updatedAtMs: data.updatedAtMs.present
          ? data.updatedAtMs.value
          : this.updatedAtMs,
      deletedAtMs: data.deletedAtMs.present
          ? data.deletedAtMs.value
          : this.deletedAtMs,
      version: data.version.present ? data.version.value : this.version,
      lastModifiedDeviceId: data.lastModifiedDeviceId.present
          ? data.lastModifiedDeviceId.value
          : this.lastModifiedDeviceId,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      legacyId: data.legacyId.present ? data.legacyId.value : this.legacyId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Category(')
          ..write('id: $id, ')
          ..write('ledgerId: $ledgerId, ')
          ..write('categoryType: $categoryType, ')
          ..write('name: $name, ')
          ..write('normalizedName: $normalizedName, ')
          ..write('iconCode: $iconCode, ')
          ..write('colorToken: $colorToken, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('enabled: $enabled, ')
          ..write('systemKey: $systemKey, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('updatedAtMs: $updatedAtMs, ')
          ..write('deletedAtMs: $deletedAtMs, ')
          ..write('version: $version, ')
          ..write('lastModifiedDeviceId: $lastModifiedDeviceId, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('legacyId: $legacyId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    ledgerId,
    categoryType,
    name,
    normalizedName,
    iconCode,
    colorToken,
    sortOrder,
    enabled,
    systemKey,
    createdAtMs,
    updatedAtMs,
    deletedAtMs,
    version,
    lastModifiedDeviceId,
    syncStatus,
    legacyId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Category &&
          other.id == this.id &&
          other.ledgerId == this.ledgerId &&
          other.categoryType == this.categoryType &&
          other.name == this.name &&
          other.normalizedName == this.normalizedName &&
          other.iconCode == this.iconCode &&
          other.colorToken == this.colorToken &&
          other.sortOrder == this.sortOrder &&
          other.enabled == this.enabled &&
          other.systemKey == this.systemKey &&
          other.createdAtMs == this.createdAtMs &&
          other.updatedAtMs == this.updatedAtMs &&
          other.deletedAtMs == this.deletedAtMs &&
          other.version == this.version &&
          other.lastModifiedDeviceId == this.lastModifiedDeviceId &&
          other.syncStatus == this.syncStatus &&
          other.legacyId == this.legacyId);
}

class CategoriesCompanion extends UpdateCompanion<Category> {
  final Value<String> id;
  final Value<String> ledgerId;
  final Value<String> categoryType;
  final Value<String> name;
  final Value<String> normalizedName;
  final Value<String?> iconCode;
  final Value<String?> colorToken;
  final Value<int> sortOrder;
  final Value<bool> enabled;
  final Value<String?> systemKey;
  final Value<int> createdAtMs;
  final Value<int> updatedAtMs;
  final Value<int?> deletedAtMs;
  final Value<int> version;
  final Value<String?> lastModifiedDeviceId;
  final Value<String> syncStatus;
  final Value<int?> legacyId;
  final Value<int> rowid;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.ledgerId = const Value.absent(),
    this.categoryType = const Value.absent(),
    this.name = const Value.absent(),
    this.normalizedName = const Value.absent(),
    this.iconCode = const Value.absent(),
    this.colorToken = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.enabled = const Value.absent(),
    this.systemKey = const Value.absent(),
    this.createdAtMs = const Value.absent(),
    this.updatedAtMs = const Value.absent(),
    this.deletedAtMs = const Value.absent(),
    this.version = const Value.absent(),
    this.lastModifiedDeviceId = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.legacyId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoriesCompanion.insert({
    required String id,
    required String ledgerId,
    required String categoryType,
    required String name,
    required String normalizedName,
    this.iconCode = const Value.absent(),
    this.colorToken = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.enabled = const Value.absent(),
    this.systemKey = const Value.absent(),
    required int createdAtMs,
    required int updatedAtMs,
    this.deletedAtMs = const Value.absent(),
    this.version = const Value.absent(),
    this.lastModifiedDeviceId = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.legacyId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       ledgerId = Value(ledgerId),
       categoryType = Value(categoryType),
       name = Value(name),
       normalizedName = Value(normalizedName),
       createdAtMs = Value(createdAtMs),
       updatedAtMs = Value(updatedAtMs);
  static Insertable<Category> custom({
    Expression<String>? id,
    Expression<String>? ledgerId,
    Expression<String>? categoryType,
    Expression<String>? name,
    Expression<String>? normalizedName,
    Expression<String>? iconCode,
    Expression<String>? colorToken,
    Expression<int>? sortOrder,
    Expression<bool>? enabled,
    Expression<String>? systemKey,
    Expression<int>? createdAtMs,
    Expression<int>? updatedAtMs,
    Expression<int>? deletedAtMs,
    Expression<int>? version,
    Expression<String>? lastModifiedDeviceId,
    Expression<String>? syncStatus,
    Expression<int>? legacyId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ledgerId != null) 'ledger_id': ledgerId,
      if (categoryType != null) 'category_type': categoryType,
      if (name != null) 'name': name,
      if (normalizedName != null) 'normalized_name': normalizedName,
      if (iconCode != null) 'icon_code': iconCode,
      if (colorToken != null) 'color_token': colorToken,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (enabled != null) 'enabled': enabled,
      if (systemKey != null) 'system_key': systemKey,
      if (createdAtMs != null) 'created_at_ms': createdAtMs,
      if (updatedAtMs != null) 'updated_at_ms': updatedAtMs,
      if (deletedAtMs != null) 'deleted_at_ms': deletedAtMs,
      if (version != null) 'version': version,
      if (lastModifiedDeviceId != null)
        'last_modified_device_id': lastModifiedDeviceId,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (legacyId != null) 'legacy_id': legacyId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoriesCompanion copyWith({
    Value<String>? id,
    Value<String>? ledgerId,
    Value<String>? categoryType,
    Value<String>? name,
    Value<String>? normalizedName,
    Value<String?>? iconCode,
    Value<String?>? colorToken,
    Value<int>? sortOrder,
    Value<bool>? enabled,
    Value<String?>? systemKey,
    Value<int>? createdAtMs,
    Value<int>? updatedAtMs,
    Value<int?>? deletedAtMs,
    Value<int>? version,
    Value<String?>? lastModifiedDeviceId,
    Value<String>? syncStatus,
    Value<int?>? legacyId,
    Value<int>? rowid,
  }) {
    return CategoriesCompanion(
      id: id ?? this.id,
      ledgerId: ledgerId ?? this.ledgerId,
      categoryType: categoryType ?? this.categoryType,
      name: name ?? this.name,
      normalizedName: normalizedName ?? this.normalizedName,
      iconCode: iconCode ?? this.iconCode,
      colorToken: colorToken ?? this.colorToken,
      sortOrder: sortOrder ?? this.sortOrder,
      enabled: enabled ?? this.enabled,
      systemKey: systemKey ?? this.systemKey,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
      deletedAtMs: deletedAtMs ?? this.deletedAtMs,
      version: version ?? this.version,
      lastModifiedDeviceId: lastModifiedDeviceId ?? this.lastModifiedDeviceId,
      syncStatus: syncStatus ?? this.syncStatus,
      legacyId: legacyId ?? this.legacyId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (ledgerId.present) {
      map['ledger_id'] = Variable<String>(ledgerId.value);
    }
    if (categoryType.present) {
      map['category_type'] = Variable<String>(categoryType.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (normalizedName.present) {
      map['normalized_name'] = Variable<String>(normalizedName.value);
    }
    if (iconCode.present) {
      map['icon_code'] = Variable<String>(iconCode.value);
    }
    if (colorToken.present) {
      map['color_token'] = Variable<String>(colorToken.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (systemKey.present) {
      map['system_key'] = Variable<String>(systemKey.value);
    }
    if (createdAtMs.present) {
      map['created_at_ms'] = Variable<int>(createdAtMs.value);
    }
    if (updatedAtMs.present) {
      map['updated_at_ms'] = Variable<int>(updatedAtMs.value);
    }
    if (deletedAtMs.present) {
      map['deleted_at_ms'] = Variable<int>(deletedAtMs.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (lastModifiedDeviceId.present) {
      map['last_modified_device_id'] = Variable<String>(
        lastModifiedDeviceId.value,
      );
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (legacyId.present) {
      map['legacy_id'] = Variable<int>(legacyId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('ledgerId: $ledgerId, ')
          ..write('categoryType: $categoryType, ')
          ..write('name: $name, ')
          ..write('normalizedName: $normalizedName, ')
          ..write('iconCode: $iconCode, ')
          ..write('colorToken: $colorToken, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('enabled: $enabled, ')
          ..write('systemKey: $systemKey, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('updatedAtMs: $updatedAtMs, ')
          ..write('deletedAtMs: $deletedAtMs, ')
          ..write('version: $version, ')
          ..write('lastModifiedDeviceId: $lastModifiedDeviceId, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('legacyId: $legacyId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LedgerTransactionsTable extends LedgerTransactions
    with TableInfo<$LedgerTransactionsTable, LedgerTransaction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LedgerTransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ledgerIdMeta = const VerificationMeta(
    'ledgerId',
  );
  @override
  late final GeneratedColumn<String> ledgerId = GeneratedColumn<String>(
    'ledger_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES ledgers (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _transactionTypeMeta = const VerificationMeta(
    'transactionType',
  );
  @override
  late final GeneratedColumn<String> transactionType = GeneratedColumn<String>(
    'transaction_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES accounts (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _toAccountIdMeta = const VerificationMeta(
    'toAccountId',
  );
  @override
  late final GeneratedColumn<String> toAccountId = GeneratedColumn<String>(
    'to_account_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES accounts (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categories (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _amountMinorMeta = const VerificationMeta(
    'amountMinor',
  );
  @override
  late final GeneratedColumn<int> amountMinor = GeneratedColumn<int>(
    'amount_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _occurredAtUtcMsMeta = const VerificationMeta(
    'occurredAtUtcMs',
  );
  @override
  late final GeneratedColumn<int> occurredAtUtcMs = GeneratedColumn<int>(
    'occurred_at_utc_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timeZoneIdMeta = const VerificationMeta(
    'timeZoneId',
  );
  @override
  late final GeneratedColumn<String> timeZoneId = GeneratedColumn<String>(
    'time_zone_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _merchantMeta = const VerificationMeta(
    'merchant',
  );
  @override
  late final GeneratedColumn<String> merchant = GeneratedColumn<String>(
    'merchant',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceTypeMeta = const VerificationMeta(
    'sourceType',
  );
  @override
  late final GeneratedColumn<String> sourceType = GeneratedColumn<String>(
    'source_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('manual'),
  );
  static const VerificationMeta _transferGroupIdMeta = const VerificationMeta(
    'transferGroupId',
  );
  @override
  late final GeneratedColumn<String> transferGroupId = GeneratedColumn<String>(
    'transfer_group_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMsMeta = const VerificationMeta(
    'createdAtMs',
  );
  @override
  late final GeneratedColumn<int> createdAtMs = GeneratedColumn<int>(
    'created_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMsMeta = const VerificationMeta(
    'updatedAtMs',
  );
  @override
  late final GeneratedColumn<int> updatedAtMs = GeneratedColumn<int>(
    'updated_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMsMeta = const VerificationMeta(
    'deletedAtMs',
  );
  @override
  late final GeneratedColumn<int> deletedAtMs = GeneratedColumn<int>(
    'deleted_at_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _lastModifiedDeviceIdMeta =
      const VerificationMeta('lastModifiedDeviceId');
  @override
  late final GeneratedColumn<String> lastModifiedDeviceId =
      GeneratedColumn<String>(
        'last_modified_device_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _legacyIdMeta = const VerificationMeta(
    'legacyId',
  );
  @override
  late final GeneratedColumn<int> legacyId = GeneratedColumn<int>(
    'legacy_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    ledgerId,
    transactionType,
    accountId,
    toAccountId,
    categoryId,
    amountMinor,
    occurredAtUtcMs,
    timeZoneId,
    note,
    merchant,
    sourceType,
    transferGroupId,
    createdAtMs,
    updatedAtMs,
    deletedAtMs,
    version,
    lastModifiedDeviceId,
    syncStatus,
    legacyId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<LedgerTransaction> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('ledger_id')) {
      context.handle(
        _ledgerIdMeta,
        ledgerId.isAcceptableOrUnknown(data['ledger_id']!, _ledgerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ledgerIdMeta);
    }
    if (data.containsKey('transaction_type')) {
      context.handle(
        _transactionTypeMeta,
        transactionType.isAcceptableOrUnknown(
          data['transaction_type']!,
          _transactionTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_transactionTypeMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('to_account_id')) {
      context.handle(
        _toAccountIdMeta,
        toAccountId.isAcceptableOrUnknown(
          data['to_account_id']!,
          _toAccountIdMeta,
        ),
      );
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('amount_minor')) {
      context.handle(
        _amountMinorMeta,
        amountMinor.isAcceptableOrUnknown(
          data['amount_minor']!,
          _amountMinorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountMinorMeta);
    }
    if (data.containsKey('occurred_at_utc_ms')) {
      context.handle(
        _occurredAtUtcMsMeta,
        occurredAtUtcMs.isAcceptableOrUnknown(
          data['occurred_at_utc_ms']!,
          _occurredAtUtcMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_occurredAtUtcMsMeta);
    }
    if (data.containsKey('time_zone_id')) {
      context.handle(
        _timeZoneIdMeta,
        timeZoneId.isAcceptableOrUnknown(
          data['time_zone_id']!,
          _timeZoneIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_timeZoneIdMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('merchant')) {
      context.handle(
        _merchantMeta,
        merchant.isAcceptableOrUnknown(data['merchant']!, _merchantMeta),
      );
    }
    if (data.containsKey('source_type')) {
      context.handle(
        _sourceTypeMeta,
        sourceType.isAcceptableOrUnknown(data['source_type']!, _sourceTypeMeta),
      );
    }
    if (data.containsKey('transfer_group_id')) {
      context.handle(
        _transferGroupIdMeta,
        transferGroupId.isAcceptableOrUnknown(
          data['transfer_group_id']!,
          _transferGroupIdMeta,
        ),
      );
    }
    if (data.containsKey('created_at_ms')) {
      context.handle(
        _createdAtMsMeta,
        createdAtMs.isAcceptableOrUnknown(
          data['created_at_ms']!,
          _createdAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtMsMeta);
    }
    if (data.containsKey('updated_at_ms')) {
      context.handle(
        _updatedAtMsMeta,
        updatedAtMs.isAcceptableOrUnknown(
          data['updated_at_ms']!,
          _updatedAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMsMeta);
    }
    if (data.containsKey('deleted_at_ms')) {
      context.handle(
        _deletedAtMsMeta,
        deletedAtMs.isAcceptableOrUnknown(
          data['deleted_at_ms']!,
          _deletedAtMsMeta,
        ),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('last_modified_device_id')) {
      context.handle(
        _lastModifiedDeviceIdMeta,
        lastModifiedDeviceId.isAcceptableOrUnknown(
          data['last_modified_device_id']!,
          _lastModifiedDeviceIdMeta,
        ),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('legacy_id')) {
      context.handle(
        _legacyIdMeta,
        legacyId.isAcceptableOrUnknown(data['legacy_id']!, _legacyIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LedgerTransaction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LedgerTransaction(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      ledgerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ledger_id'],
      )!,
      transactionType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transaction_type'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      toAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}to_account_id'],
      ),
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      ),
      amountMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_minor'],
      )!,
      occurredAtUtcMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}occurred_at_utc_ms'],
      )!,
      timeZoneId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}time_zone_id'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      merchant: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}merchant'],
      ),
      sourceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_type'],
      )!,
      transferGroupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}transfer_group_id'],
      ),
      createdAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_ms'],
      )!,
      updatedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_ms'],
      )!,
      deletedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at_ms'],
      ),
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      lastModifiedDeviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_modified_device_id'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      legacyId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}legacy_id'],
      ),
    );
  }

  @override
  $LedgerTransactionsTable createAlias(String alias) {
    return $LedgerTransactionsTable(attachedDatabase, alias);
  }
}

class LedgerTransaction extends DataClass
    implements Insertable<LedgerTransaction> {
  final String id;
  final String ledgerId;
  final String transactionType;
  final String accountId;
  final String? toAccountId;
  final String? categoryId;
  final int amountMinor;
  final int occurredAtUtcMs;
  final String timeZoneId;
  final String? note;
  final String? merchant;
  final String sourceType;
  final String? transferGroupId;
  final int createdAtMs;
  final int updatedAtMs;
  final int? deletedAtMs;
  final int version;
  final String? lastModifiedDeviceId;
  final String syncStatus;
  final int? legacyId;
  const LedgerTransaction({
    required this.id,
    required this.ledgerId,
    required this.transactionType,
    required this.accountId,
    this.toAccountId,
    this.categoryId,
    required this.amountMinor,
    required this.occurredAtUtcMs,
    required this.timeZoneId,
    this.note,
    this.merchant,
    required this.sourceType,
    this.transferGroupId,
    required this.createdAtMs,
    required this.updatedAtMs,
    this.deletedAtMs,
    required this.version,
    this.lastModifiedDeviceId,
    required this.syncStatus,
    this.legacyId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['ledger_id'] = Variable<String>(ledgerId);
    map['transaction_type'] = Variable<String>(transactionType);
    map['account_id'] = Variable<String>(accountId);
    if (!nullToAbsent || toAccountId != null) {
      map['to_account_id'] = Variable<String>(toAccountId);
    }
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    map['amount_minor'] = Variable<int>(amountMinor);
    map['occurred_at_utc_ms'] = Variable<int>(occurredAtUtcMs);
    map['time_zone_id'] = Variable<String>(timeZoneId);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || merchant != null) {
      map['merchant'] = Variable<String>(merchant);
    }
    map['source_type'] = Variable<String>(sourceType);
    if (!nullToAbsent || transferGroupId != null) {
      map['transfer_group_id'] = Variable<String>(transferGroupId);
    }
    map['created_at_ms'] = Variable<int>(createdAtMs);
    map['updated_at_ms'] = Variable<int>(updatedAtMs);
    if (!nullToAbsent || deletedAtMs != null) {
      map['deleted_at_ms'] = Variable<int>(deletedAtMs);
    }
    map['version'] = Variable<int>(version);
    if (!nullToAbsent || lastModifiedDeviceId != null) {
      map['last_modified_device_id'] = Variable<String>(lastModifiedDeviceId);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    if (!nullToAbsent || legacyId != null) {
      map['legacy_id'] = Variable<int>(legacyId);
    }
    return map;
  }

  LedgerTransactionsCompanion toCompanion(bool nullToAbsent) {
    return LedgerTransactionsCompanion(
      id: Value(id),
      ledgerId: Value(ledgerId),
      transactionType: Value(transactionType),
      accountId: Value(accountId),
      toAccountId: toAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(toAccountId),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      amountMinor: Value(amountMinor),
      occurredAtUtcMs: Value(occurredAtUtcMs),
      timeZoneId: Value(timeZoneId),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      merchant: merchant == null && nullToAbsent
          ? const Value.absent()
          : Value(merchant),
      sourceType: Value(sourceType),
      transferGroupId: transferGroupId == null && nullToAbsent
          ? const Value.absent()
          : Value(transferGroupId),
      createdAtMs: Value(createdAtMs),
      updatedAtMs: Value(updatedAtMs),
      deletedAtMs: deletedAtMs == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAtMs),
      version: Value(version),
      lastModifiedDeviceId: lastModifiedDeviceId == null && nullToAbsent
          ? const Value.absent()
          : Value(lastModifiedDeviceId),
      syncStatus: Value(syncStatus),
      legacyId: legacyId == null && nullToAbsent
          ? const Value.absent()
          : Value(legacyId),
    );
  }

  factory LedgerTransaction.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LedgerTransaction(
      id: serializer.fromJson<String>(json['id']),
      ledgerId: serializer.fromJson<String>(json['ledgerId']),
      transactionType: serializer.fromJson<String>(json['transactionType']),
      accountId: serializer.fromJson<String>(json['accountId']),
      toAccountId: serializer.fromJson<String?>(json['toAccountId']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      amountMinor: serializer.fromJson<int>(json['amountMinor']),
      occurredAtUtcMs: serializer.fromJson<int>(json['occurredAtUtcMs']),
      timeZoneId: serializer.fromJson<String>(json['timeZoneId']),
      note: serializer.fromJson<String?>(json['note']),
      merchant: serializer.fromJson<String?>(json['merchant']),
      sourceType: serializer.fromJson<String>(json['sourceType']),
      transferGroupId: serializer.fromJson<String?>(json['transferGroupId']),
      createdAtMs: serializer.fromJson<int>(json['createdAtMs']),
      updatedAtMs: serializer.fromJson<int>(json['updatedAtMs']),
      deletedAtMs: serializer.fromJson<int?>(json['deletedAtMs']),
      version: serializer.fromJson<int>(json['version']),
      lastModifiedDeviceId: serializer.fromJson<String?>(
        json['lastModifiedDeviceId'],
      ),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      legacyId: serializer.fromJson<int?>(json['legacyId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'ledgerId': serializer.toJson<String>(ledgerId),
      'transactionType': serializer.toJson<String>(transactionType),
      'accountId': serializer.toJson<String>(accountId),
      'toAccountId': serializer.toJson<String?>(toAccountId),
      'categoryId': serializer.toJson<String?>(categoryId),
      'amountMinor': serializer.toJson<int>(amountMinor),
      'occurredAtUtcMs': serializer.toJson<int>(occurredAtUtcMs),
      'timeZoneId': serializer.toJson<String>(timeZoneId),
      'note': serializer.toJson<String?>(note),
      'merchant': serializer.toJson<String?>(merchant),
      'sourceType': serializer.toJson<String>(sourceType),
      'transferGroupId': serializer.toJson<String?>(transferGroupId),
      'createdAtMs': serializer.toJson<int>(createdAtMs),
      'updatedAtMs': serializer.toJson<int>(updatedAtMs),
      'deletedAtMs': serializer.toJson<int?>(deletedAtMs),
      'version': serializer.toJson<int>(version),
      'lastModifiedDeviceId': serializer.toJson<String?>(lastModifiedDeviceId),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'legacyId': serializer.toJson<int?>(legacyId),
    };
  }

  LedgerTransaction copyWith({
    String? id,
    String? ledgerId,
    String? transactionType,
    String? accountId,
    Value<String?> toAccountId = const Value.absent(),
    Value<String?> categoryId = const Value.absent(),
    int? amountMinor,
    int? occurredAtUtcMs,
    String? timeZoneId,
    Value<String?> note = const Value.absent(),
    Value<String?> merchant = const Value.absent(),
    String? sourceType,
    Value<String?> transferGroupId = const Value.absent(),
    int? createdAtMs,
    int? updatedAtMs,
    Value<int?> deletedAtMs = const Value.absent(),
    int? version,
    Value<String?> lastModifiedDeviceId = const Value.absent(),
    String? syncStatus,
    Value<int?> legacyId = const Value.absent(),
  }) => LedgerTransaction(
    id: id ?? this.id,
    ledgerId: ledgerId ?? this.ledgerId,
    transactionType: transactionType ?? this.transactionType,
    accountId: accountId ?? this.accountId,
    toAccountId: toAccountId.present ? toAccountId.value : this.toAccountId,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    amountMinor: amountMinor ?? this.amountMinor,
    occurredAtUtcMs: occurredAtUtcMs ?? this.occurredAtUtcMs,
    timeZoneId: timeZoneId ?? this.timeZoneId,
    note: note.present ? note.value : this.note,
    merchant: merchant.present ? merchant.value : this.merchant,
    sourceType: sourceType ?? this.sourceType,
    transferGroupId: transferGroupId.present
        ? transferGroupId.value
        : this.transferGroupId,
    createdAtMs: createdAtMs ?? this.createdAtMs,
    updatedAtMs: updatedAtMs ?? this.updatedAtMs,
    deletedAtMs: deletedAtMs.present ? deletedAtMs.value : this.deletedAtMs,
    version: version ?? this.version,
    lastModifiedDeviceId: lastModifiedDeviceId.present
        ? lastModifiedDeviceId.value
        : this.lastModifiedDeviceId,
    syncStatus: syncStatus ?? this.syncStatus,
    legacyId: legacyId.present ? legacyId.value : this.legacyId,
  );
  LedgerTransaction copyWithCompanion(LedgerTransactionsCompanion data) {
    return LedgerTransaction(
      id: data.id.present ? data.id.value : this.id,
      ledgerId: data.ledgerId.present ? data.ledgerId.value : this.ledgerId,
      transactionType: data.transactionType.present
          ? data.transactionType.value
          : this.transactionType,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      toAccountId: data.toAccountId.present
          ? data.toAccountId.value
          : this.toAccountId,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      amountMinor: data.amountMinor.present
          ? data.amountMinor.value
          : this.amountMinor,
      occurredAtUtcMs: data.occurredAtUtcMs.present
          ? data.occurredAtUtcMs.value
          : this.occurredAtUtcMs,
      timeZoneId: data.timeZoneId.present
          ? data.timeZoneId.value
          : this.timeZoneId,
      note: data.note.present ? data.note.value : this.note,
      merchant: data.merchant.present ? data.merchant.value : this.merchant,
      sourceType: data.sourceType.present
          ? data.sourceType.value
          : this.sourceType,
      transferGroupId: data.transferGroupId.present
          ? data.transferGroupId.value
          : this.transferGroupId,
      createdAtMs: data.createdAtMs.present
          ? data.createdAtMs.value
          : this.createdAtMs,
      updatedAtMs: data.updatedAtMs.present
          ? data.updatedAtMs.value
          : this.updatedAtMs,
      deletedAtMs: data.deletedAtMs.present
          ? data.deletedAtMs.value
          : this.deletedAtMs,
      version: data.version.present ? data.version.value : this.version,
      lastModifiedDeviceId: data.lastModifiedDeviceId.present
          ? data.lastModifiedDeviceId.value
          : this.lastModifiedDeviceId,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      legacyId: data.legacyId.present ? data.legacyId.value : this.legacyId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LedgerTransaction(')
          ..write('id: $id, ')
          ..write('ledgerId: $ledgerId, ')
          ..write('transactionType: $transactionType, ')
          ..write('accountId: $accountId, ')
          ..write('toAccountId: $toAccountId, ')
          ..write('categoryId: $categoryId, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('occurredAtUtcMs: $occurredAtUtcMs, ')
          ..write('timeZoneId: $timeZoneId, ')
          ..write('note: $note, ')
          ..write('merchant: $merchant, ')
          ..write('sourceType: $sourceType, ')
          ..write('transferGroupId: $transferGroupId, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('updatedAtMs: $updatedAtMs, ')
          ..write('deletedAtMs: $deletedAtMs, ')
          ..write('version: $version, ')
          ..write('lastModifiedDeviceId: $lastModifiedDeviceId, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('legacyId: $legacyId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    ledgerId,
    transactionType,
    accountId,
    toAccountId,
    categoryId,
    amountMinor,
    occurredAtUtcMs,
    timeZoneId,
    note,
    merchant,
    sourceType,
    transferGroupId,
    createdAtMs,
    updatedAtMs,
    deletedAtMs,
    version,
    lastModifiedDeviceId,
    syncStatus,
    legacyId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LedgerTransaction &&
          other.id == this.id &&
          other.ledgerId == this.ledgerId &&
          other.transactionType == this.transactionType &&
          other.accountId == this.accountId &&
          other.toAccountId == this.toAccountId &&
          other.categoryId == this.categoryId &&
          other.amountMinor == this.amountMinor &&
          other.occurredAtUtcMs == this.occurredAtUtcMs &&
          other.timeZoneId == this.timeZoneId &&
          other.note == this.note &&
          other.merchant == this.merchant &&
          other.sourceType == this.sourceType &&
          other.transferGroupId == this.transferGroupId &&
          other.createdAtMs == this.createdAtMs &&
          other.updatedAtMs == this.updatedAtMs &&
          other.deletedAtMs == this.deletedAtMs &&
          other.version == this.version &&
          other.lastModifiedDeviceId == this.lastModifiedDeviceId &&
          other.syncStatus == this.syncStatus &&
          other.legacyId == this.legacyId);
}

class LedgerTransactionsCompanion extends UpdateCompanion<LedgerTransaction> {
  final Value<String> id;
  final Value<String> ledgerId;
  final Value<String> transactionType;
  final Value<String> accountId;
  final Value<String?> toAccountId;
  final Value<String?> categoryId;
  final Value<int> amountMinor;
  final Value<int> occurredAtUtcMs;
  final Value<String> timeZoneId;
  final Value<String?> note;
  final Value<String?> merchant;
  final Value<String> sourceType;
  final Value<String?> transferGroupId;
  final Value<int> createdAtMs;
  final Value<int> updatedAtMs;
  final Value<int?> deletedAtMs;
  final Value<int> version;
  final Value<String?> lastModifiedDeviceId;
  final Value<String> syncStatus;
  final Value<int?> legacyId;
  final Value<int> rowid;
  const LedgerTransactionsCompanion({
    this.id = const Value.absent(),
    this.ledgerId = const Value.absent(),
    this.transactionType = const Value.absent(),
    this.accountId = const Value.absent(),
    this.toAccountId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.amountMinor = const Value.absent(),
    this.occurredAtUtcMs = const Value.absent(),
    this.timeZoneId = const Value.absent(),
    this.note = const Value.absent(),
    this.merchant = const Value.absent(),
    this.sourceType = const Value.absent(),
    this.transferGroupId = const Value.absent(),
    this.createdAtMs = const Value.absent(),
    this.updatedAtMs = const Value.absent(),
    this.deletedAtMs = const Value.absent(),
    this.version = const Value.absent(),
    this.lastModifiedDeviceId = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.legacyId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LedgerTransactionsCompanion.insert({
    required String id,
    required String ledgerId,
    required String transactionType,
    required String accountId,
    this.toAccountId = const Value.absent(),
    this.categoryId = const Value.absent(),
    required int amountMinor,
    required int occurredAtUtcMs,
    required String timeZoneId,
    this.note = const Value.absent(),
    this.merchant = const Value.absent(),
    this.sourceType = const Value.absent(),
    this.transferGroupId = const Value.absent(),
    required int createdAtMs,
    required int updatedAtMs,
    this.deletedAtMs = const Value.absent(),
    this.version = const Value.absent(),
    this.lastModifiedDeviceId = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.legacyId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       ledgerId = Value(ledgerId),
       transactionType = Value(transactionType),
       accountId = Value(accountId),
       amountMinor = Value(amountMinor),
       occurredAtUtcMs = Value(occurredAtUtcMs),
       timeZoneId = Value(timeZoneId),
       createdAtMs = Value(createdAtMs),
       updatedAtMs = Value(updatedAtMs);
  static Insertable<LedgerTransaction> custom({
    Expression<String>? id,
    Expression<String>? ledgerId,
    Expression<String>? transactionType,
    Expression<String>? accountId,
    Expression<String>? toAccountId,
    Expression<String>? categoryId,
    Expression<int>? amountMinor,
    Expression<int>? occurredAtUtcMs,
    Expression<String>? timeZoneId,
    Expression<String>? note,
    Expression<String>? merchant,
    Expression<String>? sourceType,
    Expression<String>? transferGroupId,
    Expression<int>? createdAtMs,
    Expression<int>? updatedAtMs,
    Expression<int>? deletedAtMs,
    Expression<int>? version,
    Expression<String>? lastModifiedDeviceId,
    Expression<String>? syncStatus,
    Expression<int>? legacyId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ledgerId != null) 'ledger_id': ledgerId,
      if (transactionType != null) 'transaction_type': transactionType,
      if (accountId != null) 'account_id': accountId,
      if (toAccountId != null) 'to_account_id': toAccountId,
      if (categoryId != null) 'category_id': categoryId,
      if (amountMinor != null) 'amount_minor': amountMinor,
      if (occurredAtUtcMs != null) 'occurred_at_utc_ms': occurredAtUtcMs,
      if (timeZoneId != null) 'time_zone_id': timeZoneId,
      if (note != null) 'note': note,
      if (merchant != null) 'merchant': merchant,
      if (sourceType != null) 'source_type': sourceType,
      if (transferGroupId != null) 'transfer_group_id': transferGroupId,
      if (createdAtMs != null) 'created_at_ms': createdAtMs,
      if (updatedAtMs != null) 'updated_at_ms': updatedAtMs,
      if (deletedAtMs != null) 'deleted_at_ms': deletedAtMs,
      if (version != null) 'version': version,
      if (lastModifiedDeviceId != null)
        'last_modified_device_id': lastModifiedDeviceId,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (legacyId != null) 'legacy_id': legacyId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LedgerTransactionsCompanion copyWith({
    Value<String>? id,
    Value<String>? ledgerId,
    Value<String>? transactionType,
    Value<String>? accountId,
    Value<String?>? toAccountId,
    Value<String?>? categoryId,
    Value<int>? amountMinor,
    Value<int>? occurredAtUtcMs,
    Value<String>? timeZoneId,
    Value<String?>? note,
    Value<String?>? merchant,
    Value<String>? sourceType,
    Value<String?>? transferGroupId,
    Value<int>? createdAtMs,
    Value<int>? updatedAtMs,
    Value<int?>? deletedAtMs,
    Value<int>? version,
    Value<String?>? lastModifiedDeviceId,
    Value<String>? syncStatus,
    Value<int?>? legacyId,
    Value<int>? rowid,
  }) {
    return LedgerTransactionsCompanion(
      id: id ?? this.id,
      ledgerId: ledgerId ?? this.ledgerId,
      transactionType: transactionType ?? this.transactionType,
      accountId: accountId ?? this.accountId,
      toAccountId: toAccountId ?? this.toAccountId,
      categoryId: categoryId ?? this.categoryId,
      amountMinor: amountMinor ?? this.amountMinor,
      occurredAtUtcMs: occurredAtUtcMs ?? this.occurredAtUtcMs,
      timeZoneId: timeZoneId ?? this.timeZoneId,
      note: note ?? this.note,
      merchant: merchant ?? this.merchant,
      sourceType: sourceType ?? this.sourceType,
      transferGroupId: transferGroupId ?? this.transferGroupId,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
      deletedAtMs: deletedAtMs ?? this.deletedAtMs,
      version: version ?? this.version,
      lastModifiedDeviceId: lastModifiedDeviceId ?? this.lastModifiedDeviceId,
      syncStatus: syncStatus ?? this.syncStatus,
      legacyId: legacyId ?? this.legacyId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (ledgerId.present) {
      map['ledger_id'] = Variable<String>(ledgerId.value);
    }
    if (transactionType.present) {
      map['transaction_type'] = Variable<String>(transactionType.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (toAccountId.present) {
      map['to_account_id'] = Variable<String>(toAccountId.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (amountMinor.present) {
      map['amount_minor'] = Variable<int>(amountMinor.value);
    }
    if (occurredAtUtcMs.present) {
      map['occurred_at_utc_ms'] = Variable<int>(occurredAtUtcMs.value);
    }
    if (timeZoneId.present) {
      map['time_zone_id'] = Variable<String>(timeZoneId.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (merchant.present) {
      map['merchant'] = Variable<String>(merchant.value);
    }
    if (sourceType.present) {
      map['source_type'] = Variable<String>(sourceType.value);
    }
    if (transferGroupId.present) {
      map['transfer_group_id'] = Variable<String>(transferGroupId.value);
    }
    if (createdAtMs.present) {
      map['created_at_ms'] = Variable<int>(createdAtMs.value);
    }
    if (updatedAtMs.present) {
      map['updated_at_ms'] = Variable<int>(updatedAtMs.value);
    }
    if (deletedAtMs.present) {
      map['deleted_at_ms'] = Variable<int>(deletedAtMs.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (lastModifiedDeviceId.present) {
      map['last_modified_device_id'] = Variable<String>(
        lastModifiedDeviceId.value,
      );
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (legacyId.present) {
      map['legacy_id'] = Variable<int>(legacyId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LedgerTransactionsCompanion(')
          ..write('id: $id, ')
          ..write('ledgerId: $ledgerId, ')
          ..write('transactionType: $transactionType, ')
          ..write('accountId: $accountId, ')
          ..write('toAccountId: $toAccountId, ')
          ..write('categoryId: $categoryId, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('occurredAtUtcMs: $occurredAtUtcMs, ')
          ..write('timeZoneId: $timeZoneId, ')
          ..write('note: $note, ')
          ..write('merchant: $merchant, ')
          ..write('sourceType: $sourceType, ')
          ..write('transferGroupId: $transferGroupId, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('updatedAtMs: $updatedAtMs, ')
          ..write('deletedAtMs: $deletedAtMs, ')
          ..write('version: $version, ')
          ..write('lastModifiedDeviceId: $lastModifiedDeviceId, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('legacyId: $legacyId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueTypeMeta = const VerificationMeta(
    'valueType',
  );
  @override
  late final GeneratedColumn<String> valueType = GeneratedColumn<String>(
    'value_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueTextMeta = const VerificationMeta(
    'valueText',
  );
  @override
  late final GeneratedColumn<String> valueText = GeneratedColumn<String>(
    'value_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMsMeta = const VerificationMeta(
    'updatedAtMs',
  );
  @override
  late final GeneratedColumn<int> updatedAtMs = GeneratedColumn<int>(
    'updated_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncScopeMeta = const VerificationMeta(
    'syncScope',
  );
  @override
  late final GeneratedColumn<String> syncScope = GeneratedColumn<String>(
    'sync_scope',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('device'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    key,
    valueType,
    valueText,
    updatedAtMs,
    syncScope,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value_type')) {
      context.handle(
        _valueTypeMeta,
        valueType.isAcceptableOrUnknown(data['value_type']!, _valueTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_valueTypeMeta);
    }
    if (data.containsKey('value_text')) {
      context.handle(
        _valueTextMeta,
        valueText.isAcceptableOrUnknown(data['value_text']!, _valueTextMeta),
      );
    }
    if (data.containsKey('updated_at_ms')) {
      context.handle(
        _updatedAtMsMeta,
        updatedAtMs.isAcceptableOrUnknown(
          data['updated_at_ms']!,
          _updatedAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMsMeta);
    }
    if (data.containsKey('sync_scope')) {
      context.handle(
        _syncScopeMeta,
        syncScope.isAcceptableOrUnknown(data['sync_scope']!, _syncScopeMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      valueType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value_type'],
      )!,
      valueText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value_text'],
      ),
      updatedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_ms'],
      )!,
      syncScope: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_scope'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final String key;
  final String valueType;
  final String? valueText;
  final int updatedAtMs;
  final String syncScope;
  const AppSetting({
    required this.key,
    required this.valueType,
    this.valueText,
    required this.updatedAtMs,
    required this.syncScope,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value_type'] = Variable<String>(valueType);
    if (!nullToAbsent || valueText != null) {
      map['value_text'] = Variable<String>(valueText);
    }
    map['updated_at_ms'] = Variable<int>(updatedAtMs);
    map['sync_scope'] = Variable<String>(syncScope);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      key: Value(key),
      valueType: Value(valueType),
      valueText: valueText == null && nullToAbsent
          ? const Value.absent()
          : Value(valueText),
      updatedAtMs: Value(updatedAtMs),
      syncScope: Value(syncScope),
    );
  }

  factory AppSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      key: serializer.fromJson<String>(json['key']),
      valueType: serializer.fromJson<String>(json['valueType']),
      valueText: serializer.fromJson<String?>(json['valueText']),
      updatedAtMs: serializer.fromJson<int>(json['updatedAtMs']),
      syncScope: serializer.fromJson<String>(json['syncScope']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'valueType': serializer.toJson<String>(valueType),
      'valueText': serializer.toJson<String?>(valueText),
      'updatedAtMs': serializer.toJson<int>(updatedAtMs),
      'syncScope': serializer.toJson<String>(syncScope),
    };
  }

  AppSetting copyWith({
    String? key,
    String? valueType,
    Value<String?> valueText = const Value.absent(),
    int? updatedAtMs,
    String? syncScope,
  }) => AppSetting(
    key: key ?? this.key,
    valueType: valueType ?? this.valueType,
    valueText: valueText.present ? valueText.value : this.valueText,
    updatedAtMs: updatedAtMs ?? this.updatedAtMs,
    syncScope: syncScope ?? this.syncScope,
  );
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      key: data.key.present ? data.key.value : this.key,
      valueType: data.valueType.present ? data.valueType.value : this.valueType,
      valueText: data.valueText.present ? data.valueText.value : this.valueText,
      updatedAtMs: data.updatedAtMs.present
          ? data.updatedAtMs.value
          : this.updatedAtMs,
      syncScope: data.syncScope.present ? data.syncScope.value : this.syncScope,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('key: $key, ')
          ..write('valueType: $valueType, ')
          ..write('valueText: $valueText, ')
          ..write('updatedAtMs: $updatedAtMs, ')
          ..write('syncScope: $syncScope')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(key, valueType, valueText, updatedAtMs, syncScope);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.key == this.key &&
          other.valueType == this.valueType &&
          other.valueText == this.valueText &&
          other.updatedAtMs == this.updatedAtMs &&
          other.syncScope == this.syncScope);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<String> key;
  final Value<String> valueType;
  final Value<String?> valueText;
  final Value<int> updatedAtMs;
  final Value<String> syncScope;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.valueType = const Value.absent(),
    this.valueText = const Value.absent(),
    this.updatedAtMs = const Value.absent(),
    this.syncScope = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    required String valueType,
    this.valueText = const Value.absent(),
    required int updatedAtMs,
    this.syncScope = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       valueType = Value(valueType),
       updatedAtMs = Value(updatedAtMs);
  static Insertable<AppSetting> custom({
    Expression<String>? key,
    Expression<String>? valueType,
    Expression<String>? valueText,
    Expression<int>? updatedAtMs,
    Expression<String>? syncScope,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (valueType != null) 'value_type': valueType,
      if (valueText != null) 'value_text': valueText,
      if (updatedAtMs != null) 'updated_at_ms': updatedAtMs,
      if (syncScope != null) 'sync_scope': syncScope,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? valueType,
    Value<String?>? valueText,
    Value<int>? updatedAtMs,
    Value<String>? syncScope,
    Value<int>? rowid,
  }) {
    return AppSettingsCompanion(
      key: key ?? this.key,
      valueType: valueType ?? this.valueType,
      valueText: valueText ?? this.valueText,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
      syncScope: syncScope ?? this.syncScope,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (valueType.present) {
      map['value_type'] = Variable<String>(valueType.value);
    }
    if (valueText.present) {
      map['value_text'] = Variable<String>(valueText.value);
    }
    if (updatedAtMs.present) {
      map['updated_at_ms'] = Variable<int>(updatedAtMs.value);
    }
    if (syncScope.present) {
      map['sync_scope'] = Variable<String>(syncScope.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('key: $key, ')
          ..write('valueType: $valueType, ')
          ..write('valueText: $valueText, ')
          ..write('updatedAtMs: $updatedAtMs, ')
          ..write('syncScope: $syncScope, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BudgetsTable extends Budgets with TableInfo<$BudgetsTable, Budget> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BudgetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ledgerIdMeta = const VerificationMeta(
    'ledgerId',
  );
  @override
  late final GeneratedColumn<String> ledgerId = GeneratedColumn<String>(
    'ledger_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES ledgers (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scopeTypeMeta = const VerificationMeta(
    'scopeType',
  );
  @override
  late final GeneratedColumn<String> scopeType = GeneratedColumn<String>(
    'scope_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categories (id) ON DELETE RESTRICT',
    ),
  );
  static const VerificationMeta _yearMonthMeta = const VerificationMeta(
    'yearMonth',
  );
  @override
  late final GeneratedColumn<String> yearMonth = GeneratedColumn<String>(
    'year_month',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMinorMeta = const VerificationMeta(
    'amountMinor',
  );
  @override
  late final GeneratedColumn<int> amountMinor = GeneratedColumn<int>(
    'amount_minor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyCodeMeta = const VerificationMeta(
    'currencyCode',
  );
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
    'currency_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timeZoneIdMeta = const VerificationMeta(
    'timeZoneId',
  );
  @override
  late final GeneratedColumn<String> timeZoneId = GeneratedColumn<String>(
    'time_zone_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _periodTypeMeta = const VerificationMeta(
    'periodType',
  );
  @override
  late final GeneratedColumn<String> periodType = GeneratedColumn<String>(
    'period_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('monthly'),
  );
  static const VerificationMeta _startDateLocalMeta = const VerificationMeta(
    'startDateLocal',
  );
  @override
  late final GeneratedColumn<String> startDateLocal = GeneratedColumn<String>(
    'start_date_local',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endDateLocalMeta = const VerificationMeta(
    'endDateLocal',
  );
  @override
  late final GeneratedColumn<String> endDateLocal = GeneratedColumn<String>(
    'end_date_local',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _alertThresholdsJsonMeta =
      const VerificationMeta('alertThresholdsJson');
  @override
  late final GeneratedColumn<String> alertThresholdsJson =
      GeneratedColumn<String>(
        'alert_thresholds_json',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[0.8,1.0]'),
      );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtMsMeta = const VerificationMeta(
    'createdAtMs',
  );
  @override
  late final GeneratedColumn<int> createdAtMs = GeneratedColumn<int>(
    'created_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMsMeta = const VerificationMeta(
    'updatedAtMs',
  );
  @override
  late final GeneratedColumn<int> updatedAtMs = GeneratedColumn<int>(
    'updated_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMsMeta = const VerificationMeta(
    'deletedAtMs',
  );
  @override
  late final GeneratedColumn<int> deletedAtMs = GeneratedColumn<int>(
    'deleted_at_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _lastModifiedDeviceIdMeta =
      const VerificationMeta('lastModifiedDeviceId');
  @override
  late final GeneratedColumn<String> lastModifiedDeviceId =
      GeneratedColumn<String>(
        'last_modified_device_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _legacyIdMeta = const VerificationMeta(
    'legacyId',
  );
  @override
  late final GeneratedColumn<int> legacyId = GeneratedColumn<int>(
    'legacy_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    ledgerId,
    name,
    scopeType,
    categoryId,
    yearMonth,
    amountMinor,
    currencyCode,
    timeZoneId,
    periodType,
    startDateLocal,
    endDateLocal,
    alertThresholdsJson,
    isActive,
    createdAtMs,
    updatedAtMs,
    deletedAtMs,
    version,
    lastModifiedDeviceId,
    syncStatus,
    legacyId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'budgets';
  @override
  VerificationContext validateIntegrity(
    Insertable<Budget> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('ledger_id')) {
      context.handle(
        _ledgerIdMeta,
        ledgerId.isAcceptableOrUnknown(data['ledger_id']!, _ledgerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ledgerIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('scope_type')) {
      context.handle(
        _scopeTypeMeta,
        scopeType.isAcceptableOrUnknown(data['scope_type']!, _scopeTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_scopeTypeMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('year_month')) {
      context.handle(
        _yearMonthMeta,
        yearMonth.isAcceptableOrUnknown(data['year_month']!, _yearMonthMeta),
      );
    } else if (isInserting) {
      context.missing(_yearMonthMeta);
    }
    if (data.containsKey('amount_minor')) {
      context.handle(
        _amountMinorMeta,
        amountMinor.isAcceptableOrUnknown(
          data['amount_minor']!,
          _amountMinorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountMinorMeta);
    }
    if (data.containsKey('currency_code')) {
      context.handle(
        _currencyCodeMeta,
        currencyCode.isAcceptableOrUnknown(
          data['currency_code']!,
          _currencyCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_currencyCodeMeta);
    }
    if (data.containsKey('time_zone_id')) {
      context.handle(
        _timeZoneIdMeta,
        timeZoneId.isAcceptableOrUnknown(
          data['time_zone_id']!,
          _timeZoneIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_timeZoneIdMeta);
    }
    if (data.containsKey('period_type')) {
      context.handle(
        _periodTypeMeta,
        periodType.isAcceptableOrUnknown(data['period_type']!, _periodTypeMeta),
      );
    }
    if (data.containsKey('start_date_local')) {
      context.handle(
        _startDateLocalMeta,
        startDateLocal.isAcceptableOrUnknown(
          data['start_date_local']!,
          _startDateLocalMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startDateLocalMeta);
    }
    if (data.containsKey('end_date_local')) {
      context.handle(
        _endDateLocalMeta,
        endDateLocal.isAcceptableOrUnknown(
          data['end_date_local']!,
          _endDateLocalMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_endDateLocalMeta);
    }
    if (data.containsKey('alert_thresholds_json')) {
      context.handle(
        _alertThresholdsJsonMeta,
        alertThresholdsJson.isAcceptableOrUnknown(
          data['alert_thresholds_json']!,
          _alertThresholdsJsonMeta,
        ),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('created_at_ms')) {
      context.handle(
        _createdAtMsMeta,
        createdAtMs.isAcceptableOrUnknown(
          data['created_at_ms']!,
          _createdAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtMsMeta);
    }
    if (data.containsKey('updated_at_ms')) {
      context.handle(
        _updatedAtMsMeta,
        updatedAtMs.isAcceptableOrUnknown(
          data['updated_at_ms']!,
          _updatedAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMsMeta);
    }
    if (data.containsKey('deleted_at_ms')) {
      context.handle(
        _deletedAtMsMeta,
        deletedAtMs.isAcceptableOrUnknown(
          data['deleted_at_ms']!,
          _deletedAtMsMeta,
        ),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('last_modified_device_id')) {
      context.handle(
        _lastModifiedDeviceIdMeta,
        lastModifiedDeviceId.isAcceptableOrUnknown(
          data['last_modified_device_id']!,
          _lastModifiedDeviceIdMeta,
        ),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('legacy_id')) {
      context.handle(
        _legacyIdMeta,
        legacyId.isAcceptableOrUnknown(data['legacy_id']!, _legacyIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Budget map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Budget(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      ledgerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ledger_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      scopeType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scope_type'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      ),
      yearMonth: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}year_month'],
      )!,
      amountMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_minor'],
      )!,
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
      )!,
      timeZoneId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}time_zone_id'],
      )!,
      periodType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}period_type'],
      )!,
      startDateLocal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_date_local'],
      )!,
      endDateLocal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end_date_local'],
      )!,
      alertThresholdsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}alert_thresholds_json'],
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      createdAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_ms'],
      )!,
      updatedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_ms'],
      )!,
      deletedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at_ms'],
      ),
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      lastModifiedDeviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_modified_device_id'],
      ),
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      legacyId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}legacy_id'],
      ),
    );
  }

  @override
  $BudgetsTable createAlias(String alias) {
    return $BudgetsTable(attachedDatabase, alias);
  }
}

class Budget extends DataClass implements Insertable<Budget> {
  final String id;
  final String ledgerId;
  final String name;
  final String scopeType;
  final String? categoryId;
  final String yearMonth;
  final int amountMinor;
  final String currencyCode;
  final String timeZoneId;
  final String periodType;
  final String startDateLocal;
  final String endDateLocal;
  final String? alertThresholdsJson;
  final bool isActive;
  final int createdAtMs;
  final int updatedAtMs;
  final int? deletedAtMs;
  final int version;
  final String? lastModifiedDeviceId;
  final String syncStatus;
  final int? legacyId;
  const Budget({
    required this.id,
    required this.ledgerId,
    required this.name,
    required this.scopeType,
    this.categoryId,
    required this.yearMonth,
    required this.amountMinor,
    required this.currencyCode,
    required this.timeZoneId,
    required this.periodType,
    required this.startDateLocal,
    required this.endDateLocal,
    this.alertThresholdsJson,
    required this.isActive,
    required this.createdAtMs,
    required this.updatedAtMs,
    this.deletedAtMs,
    required this.version,
    this.lastModifiedDeviceId,
    required this.syncStatus,
    this.legacyId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['ledger_id'] = Variable<String>(ledgerId);
    map['name'] = Variable<String>(name);
    map['scope_type'] = Variable<String>(scopeType);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    map['year_month'] = Variable<String>(yearMonth);
    map['amount_minor'] = Variable<int>(amountMinor);
    map['currency_code'] = Variable<String>(currencyCode);
    map['time_zone_id'] = Variable<String>(timeZoneId);
    map['period_type'] = Variable<String>(periodType);
    map['start_date_local'] = Variable<String>(startDateLocal);
    map['end_date_local'] = Variable<String>(endDateLocal);
    if (!nullToAbsent || alertThresholdsJson != null) {
      map['alert_thresholds_json'] = Variable<String>(alertThresholdsJson);
    }
    map['is_active'] = Variable<bool>(isActive);
    map['created_at_ms'] = Variable<int>(createdAtMs);
    map['updated_at_ms'] = Variable<int>(updatedAtMs);
    if (!nullToAbsent || deletedAtMs != null) {
      map['deleted_at_ms'] = Variable<int>(deletedAtMs);
    }
    map['version'] = Variable<int>(version);
    if (!nullToAbsent || lastModifiedDeviceId != null) {
      map['last_modified_device_id'] = Variable<String>(lastModifiedDeviceId);
    }
    map['sync_status'] = Variable<String>(syncStatus);
    if (!nullToAbsent || legacyId != null) {
      map['legacy_id'] = Variable<int>(legacyId);
    }
    return map;
  }

  BudgetsCompanion toCompanion(bool nullToAbsent) {
    return BudgetsCompanion(
      id: Value(id),
      ledgerId: Value(ledgerId),
      name: Value(name),
      scopeType: Value(scopeType),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      yearMonth: Value(yearMonth),
      amountMinor: Value(amountMinor),
      currencyCode: Value(currencyCode),
      timeZoneId: Value(timeZoneId),
      periodType: Value(periodType),
      startDateLocal: Value(startDateLocal),
      endDateLocal: Value(endDateLocal),
      alertThresholdsJson: alertThresholdsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(alertThresholdsJson),
      isActive: Value(isActive),
      createdAtMs: Value(createdAtMs),
      updatedAtMs: Value(updatedAtMs),
      deletedAtMs: deletedAtMs == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAtMs),
      version: Value(version),
      lastModifiedDeviceId: lastModifiedDeviceId == null && nullToAbsent
          ? const Value.absent()
          : Value(lastModifiedDeviceId),
      syncStatus: Value(syncStatus),
      legacyId: legacyId == null && nullToAbsent
          ? const Value.absent()
          : Value(legacyId),
    );
  }

  factory Budget.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Budget(
      id: serializer.fromJson<String>(json['id']),
      ledgerId: serializer.fromJson<String>(json['ledgerId']),
      name: serializer.fromJson<String>(json['name']),
      scopeType: serializer.fromJson<String>(json['scopeType']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      yearMonth: serializer.fromJson<String>(json['yearMonth']),
      amountMinor: serializer.fromJson<int>(json['amountMinor']),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      timeZoneId: serializer.fromJson<String>(json['timeZoneId']),
      periodType: serializer.fromJson<String>(json['periodType']),
      startDateLocal: serializer.fromJson<String>(json['startDateLocal']),
      endDateLocal: serializer.fromJson<String>(json['endDateLocal']),
      alertThresholdsJson: serializer.fromJson<String?>(
        json['alertThresholdsJson'],
      ),
      isActive: serializer.fromJson<bool>(json['isActive']),
      createdAtMs: serializer.fromJson<int>(json['createdAtMs']),
      updatedAtMs: serializer.fromJson<int>(json['updatedAtMs']),
      deletedAtMs: serializer.fromJson<int?>(json['deletedAtMs']),
      version: serializer.fromJson<int>(json['version']),
      lastModifiedDeviceId: serializer.fromJson<String?>(
        json['lastModifiedDeviceId'],
      ),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      legacyId: serializer.fromJson<int?>(json['legacyId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'ledgerId': serializer.toJson<String>(ledgerId),
      'name': serializer.toJson<String>(name),
      'scopeType': serializer.toJson<String>(scopeType),
      'categoryId': serializer.toJson<String?>(categoryId),
      'yearMonth': serializer.toJson<String>(yearMonth),
      'amountMinor': serializer.toJson<int>(amountMinor),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'timeZoneId': serializer.toJson<String>(timeZoneId),
      'periodType': serializer.toJson<String>(periodType),
      'startDateLocal': serializer.toJson<String>(startDateLocal),
      'endDateLocal': serializer.toJson<String>(endDateLocal),
      'alertThresholdsJson': serializer.toJson<String?>(alertThresholdsJson),
      'isActive': serializer.toJson<bool>(isActive),
      'createdAtMs': serializer.toJson<int>(createdAtMs),
      'updatedAtMs': serializer.toJson<int>(updatedAtMs),
      'deletedAtMs': serializer.toJson<int?>(deletedAtMs),
      'version': serializer.toJson<int>(version),
      'lastModifiedDeviceId': serializer.toJson<String?>(lastModifiedDeviceId),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'legacyId': serializer.toJson<int?>(legacyId),
    };
  }

  Budget copyWith({
    String? id,
    String? ledgerId,
    String? name,
    String? scopeType,
    Value<String?> categoryId = const Value.absent(),
    String? yearMonth,
    int? amountMinor,
    String? currencyCode,
    String? timeZoneId,
    String? periodType,
    String? startDateLocal,
    String? endDateLocal,
    Value<String?> alertThresholdsJson = const Value.absent(),
    bool? isActive,
    int? createdAtMs,
    int? updatedAtMs,
    Value<int?> deletedAtMs = const Value.absent(),
    int? version,
    Value<String?> lastModifiedDeviceId = const Value.absent(),
    String? syncStatus,
    Value<int?> legacyId = const Value.absent(),
  }) => Budget(
    id: id ?? this.id,
    ledgerId: ledgerId ?? this.ledgerId,
    name: name ?? this.name,
    scopeType: scopeType ?? this.scopeType,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    yearMonth: yearMonth ?? this.yearMonth,
    amountMinor: amountMinor ?? this.amountMinor,
    currencyCode: currencyCode ?? this.currencyCode,
    timeZoneId: timeZoneId ?? this.timeZoneId,
    periodType: periodType ?? this.periodType,
    startDateLocal: startDateLocal ?? this.startDateLocal,
    endDateLocal: endDateLocal ?? this.endDateLocal,
    alertThresholdsJson: alertThresholdsJson.present
        ? alertThresholdsJson.value
        : this.alertThresholdsJson,
    isActive: isActive ?? this.isActive,
    createdAtMs: createdAtMs ?? this.createdAtMs,
    updatedAtMs: updatedAtMs ?? this.updatedAtMs,
    deletedAtMs: deletedAtMs.present ? deletedAtMs.value : this.deletedAtMs,
    version: version ?? this.version,
    lastModifiedDeviceId: lastModifiedDeviceId.present
        ? lastModifiedDeviceId.value
        : this.lastModifiedDeviceId,
    syncStatus: syncStatus ?? this.syncStatus,
    legacyId: legacyId.present ? legacyId.value : this.legacyId,
  );
  Budget copyWithCompanion(BudgetsCompanion data) {
    return Budget(
      id: data.id.present ? data.id.value : this.id,
      ledgerId: data.ledgerId.present ? data.ledgerId.value : this.ledgerId,
      name: data.name.present ? data.name.value : this.name,
      scopeType: data.scopeType.present ? data.scopeType.value : this.scopeType,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      yearMonth: data.yearMonth.present ? data.yearMonth.value : this.yearMonth,
      amountMinor: data.amountMinor.present
          ? data.amountMinor.value
          : this.amountMinor,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      timeZoneId: data.timeZoneId.present
          ? data.timeZoneId.value
          : this.timeZoneId,
      periodType: data.periodType.present
          ? data.periodType.value
          : this.periodType,
      startDateLocal: data.startDateLocal.present
          ? data.startDateLocal.value
          : this.startDateLocal,
      endDateLocal: data.endDateLocal.present
          ? data.endDateLocal.value
          : this.endDateLocal,
      alertThresholdsJson: data.alertThresholdsJson.present
          ? data.alertThresholdsJson.value
          : this.alertThresholdsJson,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      createdAtMs: data.createdAtMs.present
          ? data.createdAtMs.value
          : this.createdAtMs,
      updatedAtMs: data.updatedAtMs.present
          ? data.updatedAtMs.value
          : this.updatedAtMs,
      deletedAtMs: data.deletedAtMs.present
          ? data.deletedAtMs.value
          : this.deletedAtMs,
      version: data.version.present ? data.version.value : this.version,
      lastModifiedDeviceId: data.lastModifiedDeviceId.present
          ? data.lastModifiedDeviceId.value
          : this.lastModifiedDeviceId,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      legacyId: data.legacyId.present ? data.legacyId.value : this.legacyId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Budget(')
          ..write('id: $id, ')
          ..write('ledgerId: $ledgerId, ')
          ..write('name: $name, ')
          ..write('scopeType: $scopeType, ')
          ..write('categoryId: $categoryId, ')
          ..write('yearMonth: $yearMonth, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('timeZoneId: $timeZoneId, ')
          ..write('periodType: $periodType, ')
          ..write('startDateLocal: $startDateLocal, ')
          ..write('endDateLocal: $endDateLocal, ')
          ..write('alertThresholdsJson: $alertThresholdsJson, ')
          ..write('isActive: $isActive, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('updatedAtMs: $updatedAtMs, ')
          ..write('deletedAtMs: $deletedAtMs, ')
          ..write('version: $version, ')
          ..write('lastModifiedDeviceId: $lastModifiedDeviceId, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('legacyId: $legacyId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    ledgerId,
    name,
    scopeType,
    categoryId,
    yearMonth,
    amountMinor,
    currencyCode,
    timeZoneId,
    periodType,
    startDateLocal,
    endDateLocal,
    alertThresholdsJson,
    isActive,
    createdAtMs,
    updatedAtMs,
    deletedAtMs,
    version,
    lastModifiedDeviceId,
    syncStatus,
    legacyId,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Budget &&
          other.id == this.id &&
          other.ledgerId == this.ledgerId &&
          other.name == this.name &&
          other.scopeType == this.scopeType &&
          other.categoryId == this.categoryId &&
          other.yearMonth == this.yearMonth &&
          other.amountMinor == this.amountMinor &&
          other.currencyCode == this.currencyCode &&
          other.timeZoneId == this.timeZoneId &&
          other.periodType == this.periodType &&
          other.startDateLocal == this.startDateLocal &&
          other.endDateLocal == this.endDateLocal &&
          other.alertThresholdsJson == this.alertThresholdsJson &&
          other.isActive == this.isActive &&
          other.createdAtMs == this.createdAtMs &&
          other.updatedAtMs == this.updatedAtMs &&
          other.deletedAtMs == this.deletedAtMs &&
          other.version == this.version &&
          other.lastModifiedDeviceId == this.lastModifiedDeviceId &&
          other.syncStatus == this.syncStatus &&
          other.legacyId == this.legacyId);
}

class BudgetsCompanion extends UpdateCompanion<Budget> {
  final Value<String> id;
  final Value<String> ledgerId;
  final Value<String> name;
  final Value<String> scopeType;
  final Value<String?> categoryId;
  final Value<String> yearMonth;
  final Value<int> amountMinor;
  final Value<String> currencyCode;
  final Value<String> timeZoneId;
  final Value<String> periodType;
  final Value<String> startDateLocal;
  final Value<String> endDateLocal;
  final Value<String?> alertThresholdsJson;
  final Value<bool> isActive;
  final Value<int> createdAtMs;
  final Value<int> updatedAtMs;
  final Value<int?> deletedAtMs;
  final Value<int> version;
  final Value<String?> lastModifiedDeviceId;
  final Value<String> syncStatus;
  final Value<int?> legacyId;
  final Value<int> rowid;
  const BudgetsCompanion({
    this.id = const Value.absent(),
    this.ledgerId = const Value.absent(),
    this.name = const Value.absent(),
    this.scopeType = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.yearMonth = const Value.absent(),
    this.amountMinor = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.timeZoneId = const Value.absent(),
    this.periodType = const Value.absent(),
    this.startDateLocal = const Value.absent(),
    this.endDateLocal = const Value.absent(),
    this.alertThresholdsJson = const Value.absent(),
    this.isActive = const Value.absent(),
    this.createdAtMs = const Value.absent(),
    this.updatedAtMs = const Value.absent(),
    this.deletedAtMs = const Value.absent(),
    this.version = const Value.absent(),
    this.lastModifiedDeviceId = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.legacyId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BudgetsCompanion.insert({
    required String id,
    required String ledgerId,
    required String name,
    required String scopeType,
    this.categoryId = const Value.absent(),
    required String yearMonth,
    required int amountMinor,
    required String currencyCode,
    required String timeZoneId,
    this.periodType = const Value.absent(),
    required String startDateLocal,
    required String endDateLocal,
    this.alertThresholdsJson = const Value.absent(),
    this.isActive = const Value.absent(),
    required int createdAtMs,
    required int updatedAtMs,
    this.deletedAtMs = const Value.absent(),
    this.version = const Value.absent(),
    this.lastModifiedDeviceId = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.legacyId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       ledgerId = Value(ledgerId),
       name = Value(name),
       scopeType = Value(scopeType),
       yearMonth = Value(yearMonth),
       amountMinor = Value(amountMinor),
       currencyCode = Value(currencyCode),
       timeZoneId = Value(timeZoneId),
       startDateLocal = Value(startDateLocal),
       endDateLocal = Value(endDateLocal),
       createdAtMs = Value(createdAtMs),
       updatedAtMs = Value(updatedAtMs);
  static Insertable<Budget> custom({
    Expression<String>? id,
    Expression<String>? ledgerId,
    Expression<String>? name,
    Expression<String>? scopeType,
    Expression<String>? categoryId,
    Expression<String>? yearMonth,
    Expression<int>? amountMinor,
    Expression<String>? currencyCode,
    Expression<String>? timeZoneId,
    Expression<String>? periodType,
    Expression<String>? startDateLocal,
    Expression<String>? endDateLocal,
    Expression<String>? alertThresholdsJson,
    Expression<bool>? isActive,
    Expression<int>? createdAtMs,
    Expression<int>? updatedAtMs,
    Expression<int>? deletedAtMs,
    Expression<int>? version,
    Expression<String>? lastModifiedDeviceId,
    Expression<String>? syncStatus,
    Expression<int>? legacyId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ledgerId != null) 'ledger_id': ledgerId,
      if (name != null) 'name': name,
      if (scopeType != null) 'scope_type': scopeType,
      if (categoryId != null) 'category_id': categoryId,
      if (yearMonth != null) 'year_month': yearMonth,
      if (amountMinor != null) 'amount_minor': amountMinor,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (timeZoneId != null) 'time_zone_id': timeZoneId,
      if (periodType != null) 'period_type': periodType,
      if (startDateLocal != null) 'start_date_local': startDateLocal,
      if (endDateLocal != null) 'end_date_local': endDateLocal,
      if (alertThresholdsJson != null)
        'alert_thresholds_json': alertThresholdsJson,
      if (isActive != null) 'is_active': isActive,
      if (createdAtMs != null) 'created_at_ms': createdAtMs,
      if (updatedAtMs != null) 'updated_at_ms': updatedAtMs,
      if (deletedAtMs != null) 'deleted_at_ms': deletedAtMs,
      if (version != null) 'version': version,
      if (lastModifiedDeviceId != null)
        'last_modified_device_id': lastModifiedDeviceId,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (legacyId != null) 'legacy_id': legacyId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BudgetsCompanion copyWith({
    Value<String>? id,
    Value<String>? ledgerId,
    Value<String>? name,
    Value<String>? scopeType,
    Value<String?>? categoryId,
    Value<String>? yearMonth,
    Value<int>? amountMinor,
    Value<String>? currencyCode,
    Value<String>? timeZoneId,
    Value<String>? periodType,
    Value<String>? startDateLocal,
    Value<String>? endDateLocal,
    Value<String?>? alertThresholdsJson,
    Value<bool>? isActive,
    Value<int>? createdAtMs,
    Value<int>? updatedAtMs,
    Value<int?>? deletedAtMs,
    Value<int>? version,
    Value<String?>? lastModifiedDeviceId,
    Value<String>? syncStatus,
    Value<int?>? legacyId,
    Value<int>? rowid,
  }) {
    return BudgetsCompanion(
      id: id ?? this.id,
      ledgerId: ledgerId ?? this.ledgerId,
      name: name ?? this.name,
      scopeType: scopeType ?? this.scopeType,
      categoryId: categoryId ?? this.categoryId,
      yearMonth: yearMonth ?? this.yearMonth,
      amountMinor: amountMinor ?? this.amountMinor,
      currencyCode: currencyCode ?? this.currencyCode,
      timeZoneId: timeZoneId ?? this.timeZoneId,
      periodType: periodType ?? this.periodType,
      startDateLocal: startDateLocal ?? this.startDateLocal,
      endDateLocal: endDateLocal ?? this.endDateLocal,
      alertThresholdsJson: alertThresholdsJson ?? this.alertThresholdsJson,
      isActive: isActive ?? this.isActive,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
      deletedAtMs: deletedAtMs ?? this.deletedAtMs,
      version: version ?? this.version,
      lastModifiedDeviceId: lastModifiedDeviceId ?? this.lastModifiedDeviceId,
      syncStatus: syncStatus ?? this.syncStatus,
      legacyId: legacyId ?? this.legacyId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (ledgerId.present) {
      map['ledger_id'] = Variable<String>(ledgerId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (scopeType.present) {
      map['scope_type'] = Variable<String>(scopeType.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (yearMonth.present) {
      map['year_month'] = Variable<String>(yearMonth.value);
    }
    if (amountMinor.present) {
      map['amount_minor'] = Variable<int>(amountMinor.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (timeZoneId.present) {
      map['time_zone_id'] = Variable<String>(timeZoneId.value);
    }
    if (periodType.present) {
      map['period_type'] = Variable<String>(periodType.value);
    }
    if (startDateLocal.present) {
      map['start_date_local'] = Variable<String>(startDateLocal.value);
    }
    if (endDateLocal.present) {
      map['end_date_local'] = Variable<String>(endDateLocal.value);
    }
    if (alertThresholdsJson.present) {
      map['alert_thresholds_json'] = Variable<String>(
        alertThresholdsJson.value,
      );
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (createdAtMs.present) {
      map['created_at_ms'] = Variable<int>(createdAtMs.value);
    }
    if (updatedAtMs.present) {
      map['updated_at_ms'] = Variable<int>(updatedAtMs.value);
    }
    if (deletedAtMs.present) {
      map['deleted_at_ms'] = Variable<int>(deletedAtMs.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (lastModifiedDeviceId.present) {
      map['last_modified_device_id'] = Variable<String>(
        lastModifiedDeviceId.value,
      );
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (legacyId.present) {
      map['legacy_id'] = Variable<int>(legacyId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BudgetsCompanion(')
          ..write('id: $id, ')
          ..write('ledgerId: $ledgerId, ')
          ..write('name: $name, ')
          ..write('scopeType: $scopeType, ')
          ..write('categoryId: $categoryId, ')
          ..write('yearMonth: $yearMonth, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('timeZoneId: $timeZoneId, ')
          ..write('periodType: $periodType, ')
          ..write('startDateLocal: $startDateLocal, ')
          ..write('endDateLocal: $endDateLocal, ')
          ..write('alertThresholdsJson: $alertThresholdsJson, ')
          ..write('isActive: $isActive, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('updatedAtMs: $updatedAtMs, ')
          ..write('deletedAtMs: $deletedAtMs, ')
          ..write('version: $version, ')
          ..write('lastModifiedDeviceId: $lastModifiedDeviceId, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('legacyId: $legacyId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AnalyticsEventQueueTable extends AnalyticsEventQueue
    with TableInfo<$AnalyticsEventQueueTable, AnalyticsEventQueueData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AnalyticsEventQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _eventIdMeta = const VerificationMeta(
    'eventId',
  );
  @override
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
    'event_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eventNameMeta = const VerificationMeta(
    'eventName',
  );
  @override
  late final GeneratedColumn<String> eventName = GeneratedColumn<String>(
    'event_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _occurredAtMsMeta = const VerificationMeta(
    'occurredAtMs',
  );
  @override
  late final GeneratedColumn<int> occurredAtMs = GeneratedColumn<int>(
    'occurred_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _schemaVersionMeta = const VerificationMeta(
    'schemaVersion',
  );
  @override
  late final GeneratedColumn<int> schemaVersion = GeneratedColumn<int>(
    'schema_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _identityScopeMeta = const VerificationMeta(
    'identityScope',
  );
  @override
  late final GeneratedColumn<String> identityScope = GeneratedColumn<String>(
    'identity_scope',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('anonymous_legacy'),
  );
  static const VerificationMeta _propertiesJsonMeta = const VerificationMeta(
    'propertiesJson',
  );
  @override
  late final GeneratedColumn<String> propertiesJson = GeneratedColumn<String>(
    'properties_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _attemptCountMeta = const VerificationMeta(
    'attemptCount',
  );
  @override
  late final GeneratedColumn<int> attemptCount = GeneratedColumn<int>(
    'attempt_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _nextRetryAtMsMeta = const VerificationMeta(
    'nextRetryAtMs',
  );
  @override
  late final GeneratedColumn<int> nextRetryAtMs = GeneratedColumn<int>(
    'next_retry_at_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMsMeta = const VerificationMeta(
    'createdAtMs',
  );
  @override
  late final GeneratedColumn<int> createdAtMs = GeneratedColumn<int>(
    'created_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    eventId,
    eventName,
    sessionId,
    occurredAtMs,
    schemaVersion,
    userId,
    identityScope,
    propertiesJson,
    attemptCount,
    nextRetryAtMs,
    createdAtMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'analytics_event_queue';
  @override
  VerificationContext validateIntegrity(
    Insertable<AnalyticsEventQueueData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('event_id')) {
      context.handle(
        _eventIdMeta,
        eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta),
      );
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    if (data.containsKey('event_name')) {
      context.handle(
        _eventNameMeta,
        eventName.isAcceptableOrUnknown(data['event_name']!, _eventNameMeta),
      );
    } else if (isInserting) {
      context.missing(_eventNameMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('occurred_at_ms')) {
      context.handle(
        _occurredAtMsMeta,
        occurredAtMs.isAcceptableOrUnknown(
          data['occurred_at_ms']!,
          _occurredAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_occurredAtMsMeta);
    }
    if (data.containsKey('schema_version')) {
      context.handle(
        _schemaVersionMeta,
        schemaVersion.isAcceptableOrUnknown(
          data['schema_version']!,
          _schemaVersionMeta,
        ),
      );
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('identity_scope')) {
      context.handle(
        _identityScopeMeta,
        identityScope.isAcceptableOrUnknown(
          data['identity_scope']!,
          _identityScopeMeta,
        ),
      );
    }
    if (data.containsKey('properties_json')) {
      context.handle(
        _propertiesJsonMeta,
        propertiesJson.isAcceptableOrUnknown(
          data['properties_json']!,
          _propertiesJsonMeta,
        ),
      );
    }
    if (data.containsKey('attempt_count')) {
      context.handle(
        _attemptCountMeta,
        attemptCount.isAcceptableOrUnknown(
          data['attempt_count']!,
          _attemptCountMeta,
        ),
      );
    }
    if (data.containsKey('next_retry_at_ms')) {
      context.handle(
        _nextRetryAtMsMeta,
        nextRetryAtMs.isAcceptableOrUnknown(
          data['next_retry_at_ms']!,
          _nextRetryAtMsMeta,
        ),
      );
    }
    if (data.containsKey('created_at_ms')) {
      context.handle(
        _createdAtMsMeta,
        createdAtMs.isAcceptableOrUnknown(
          data['created_at_ms']!,
          _createdAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {eventId};
  @override
  AnalyticsEventQueueData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AnalyticsEventQueueData(
      eventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_id'],
      )!,
      eventName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_name'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      occurredAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}occurred_at_ms'],
      )!,
      schemaVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}schema_version'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      ),
      identityScope: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}identity_scope'],
      )!,
      propertiesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}properties_json'],
      )!,
      attemptCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempt_count'],
      )!,
      nextRetryAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}next_retry_at_ms'],
      ),
      createdAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_ms'],
      )!,
    );
  }

  @override
  $AnalyticsEventQueueTable createAlias(String alias) {
    return $AnalyticsEventQueueTable(attachedDatabase, alias);
  }
}

class AnalyticsEventQueueData extends DataClass
    implements Insertable<AnalyticsEventQueueData> {
  final String eventId;
  final String eventName;
  final String sessionId;
  final int occurredAtMs;
  final int schemaVersion;
  final String? userId;
  final String identityScope;
  final String propertiesJson;
  final int attemptCount;
  final int? nextRetryAtMs;
  final int createdAtMs;
  const AnalyticsEventQueueData({
    required this.eventId,
    required this.eventName,
    required this.sessionId,
    required this.occurredAtMs,
    required this.schemaVersion,
    this.userId,
    required this.identityScope,
    required this.propertiesJson,
    required this.attemptCount,
    this.nextRetryAtMs,
    required this.createdAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['event_id'] = Variable<String>(eventId);
    map['event_name'] = Variable<String>(eventName);
    map['session_id'] = Variable<String>(sessionId);
    map['occurred_at_ms'] = Variable<int>(occurredAtMs);
    map['schema_version'] = Variable<int>(schemaVersion);
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    map['identity_scope'] = Variable<String>(identityScope);
    map['properties_json'] = Variable<String>(propertiesJson);
    map['attempt_count'] = Variable<int>(attemptCount);
    if (!nullToAbsent || nextRetryAtMs != null) {
      map['next_retry_at_ms'] = Variable<int>(nextRetryAtMs);
    }
    map['created_at_ms'] = Variable<int>(createdAtMs);
    return map;
  }

  AnalyticsEventQueueCompanion toCompanion(bool nullToAbsent) {
    return AnalyticsEventQueueCompanion(
      eventId: Value(eventId),
      eventName: Value(eventName),
      sessionId: Value(sessionId),
      occurredAtMs: Value(occurredAtMs),
      schemaVersion: Value(schemaVersion),
      userId: userId == null && nullToAbsent
          ? const Value.absent()
          : Value(userId),
      identityScope: Value(identityScope),
      propertiesJson: Value(propertiesJson),
      attemptCount: Value(attemptCount),
      nextRetryAtMs: nextRetryAtMs == null && nullToAbsent
          ? const Value.absent()
          : Value(nextRetryAtMs),
      createdAtMs: Value(createdAtMs),
    );
  }

  factory AnalyticsEventQueueData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AnalyticsEventQueueData(
      eventId: serializer.fromJson<String>(json['eventId']),
      eventName: serializer.fromJson<String>(json['eventName']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      occurredAtMs: serializer.fromJson<int>(json['occurredAtMs']),
      schemaVersion: serializer.fromJson<int>(json['schemaVersion']),
      userId: serializer.fromJson<String?>(json['userId']),
      identityScope: serializer.fromJson<String>(json['identityScope']),
      propertiesJson: serializer.fromJson<String>(json['propertiesJson']),
      attemptCount: serializer.fromJson<int>(json['attemptCount']),
      nextRetryAtMs: serializer.fromJson<int?>(json['nextRetryAtMs']),
      createdAtMs: serializer.fromJson<int>(json['createdAtMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'eventId': serializer.toJson<String>(eventId),
      'eventName': serializer.toJson<String>(eventName),
      'sessionId': serializer.toJson<String>(sessionId),
      'occurredAtMs': serializer.toJson<int>(occurredAtMs),
      'schemaVersion': serializer.toJson<int>(schemaVersion),
      'userId': serializer.toJson<String?>(userId),
      'identityScope': serializer.toJson<String>(identityScope),
      'propertiesJson': serializer.toJson<String>(propertiesJson),
      'attemptCount': serializer.toJson<int>(attemptCount),
      'nextRetryAtMs': serializer.toJson<int?>(nextRetryAtMs),
      'createdAtMs': serializer.toJson<int>(createdAtMs),
    };
  }

  AnalyticsEventQueueData copyWith({
    String? eventId,
    String? eventName,
    String? sessionId,
    int? occurredAtMs,
    int? schemaVersion,
    Value<String?> userId = const Value.absent(),
    String? identityScope,
    String? propertiesJson,
    int? attemptCount,
    Value<int?> nextRetryAtMs = const Value.absent(),
    int? createdAtMs,
  }) => AnalyticsEventQueueData(
    eventId: eventId ?? this.eventId,
    eventName: eventName ?? this.eventName,
    sessionId: sessionId ?? this.sessionId,
    occurredAtMs: occurredAtMs ?? this.occurredAtMs,
    schemaVersion: schemaVersion ?? this.schemaVersion,
    userId: userId.present ? userId.value : this.userId,
    identityScope: identityScope ?? this.identityScope,
    propertiesJson: propertiesJson ?? this.propertiesJson,
    attemptCount: attemptCount ?? this.attemptCount,
    nextRetryAtMs: nextRetryAtMs.present
        ? nextRetryAtMs.value
        : this.nextRetryAtMs,
    createdAtMs: createdAtMs ?? this.createdAtMs,
  );
  AnalyticsEventQueueData copyWithCompanion(AnalyticsEventQueueCompanion data) {
    return AnalyticsEventQueueData(
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      eventName: data.eventName.present ? data.eventName.value : this.eventName,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      occurredAtMs: data.occurredAtMs.present
          ? data.occurredAtMs.value
          : this.occurredAtMs,
      schemaVersion: data.schemaVersion.present
          ? data.schemaVersion.value
          : this.schemaVersion,
      userId: data.userId.present ? data.userId.value : this.userId,
      identityScope: data.identityScope.present
          ? data.identityScope.value
          : this.identityScope,
      propertiesJson: data.propertiesJson.present
          ? data.propertiesJson.value
          : this.propertiesJson,
      attemptCount: data.attemptCount.present
          ? data.attemptCount.value
          : this.attemptCount,
      nextRetryAtMs: data.nextRetryAtMs.present
          ? data.nextRetryAtMs.value
          : this.nextRetryAtMs,
      createdAtMs: data.createdAtMs.present
          ? data.createdAtMs.value
          : this.createdAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AnalyticsEventQueueData(')
          ..write('eventId: $eventId, ')
          ..write('eventName: $eventName, ')
          ..write('sessionId: $sessionId, ')
          ..write('occurredAtMs: $occurredAtMs, ')
          ..write('schemaVersion: $schemaVersion, ')
          ..write('userId: $userId, ')
          ..write('identityScope: $identityScope, ')
          ..write('propertiesJson: $propertiesJson, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('nextRetryAtMs: $nextRetryAtMs, ')
          ..write('createdAtMs: $createdAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    eventId,
    eventName,
    sessionId,
    occurredAtMs,
    schemaVersion,
    userId,
    identityScope,
    propertiesJson,
    attemptCount,
    nextRetryAtMs,
    createdAtMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AnalyticsEventQueueData &&
          other.eventId == this.eventId &&
          other.eventName == this.eventName &&
          other.sessionId == this.sessionId &&
          other.occurredAtMs == this.occurredAtMs &&
          other.schemaVersion == this.schemaVersion &&
          other.userId == this.userId &&
          other.identityScope == this.identityScope &&
          other.propertiesJson == this.propertiesJson &&
          other.attemptCount == this.attemptCount &&
          other.nextRetryAtMs == this.nextRetryAtMs &&
          other.createdAtMs == this.createdAtMs);
}

class AnalyticsEventQueueCompanion
    extends UpdateCompanion<AnalyticsEventQueueData> {
  final Value<String> eventId;
  final Value<String> eventName;
  final Value<String> sessionId;
  final Value<int> occurredAtMs;
  final Value<int> schemaVersion;
  final Value<String?> userId;
  final Value<String> identityScope;
  final Value<String> propertiesJson;
  final Value<int> attemptCount;
  final Value<int?> nextRetryAtMs;
  final Value<int> createdAtMs;
  final Value<int> rowid;
  const AnalyticsEventQueueCompanion({
    this.eventId = const Value.absent(),
    this.eventName = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.occurredAtMs = const Value.absent(),
    this.schemaVersion = const Value.absent(),
    this.userId = const Value.absent(),
    this.identityScope = const Value.absent(),
    this.propertiesJson = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.nextRetryAtMs = const Value.absent(),
    this.createdAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AnalyticsEventQueueCompanion.insert({
    required String eventId,
    required String eventName,
    required String sessionId,
    required int occurredAtMs,
    this.schemaVersion = const Value.absent(),
    this.userId = const Value.absent(),
    this.identityScope = const Value.absent(),
    this.propertiesJson = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.nextRetryAtMs = const Value.absent(),
    required int createdAtMs,
    this.rowid = const Value.absent(),
  }) : eventId = Value(eventId),
       eventName = Value(eventName),
       sessionId = Value(sessionId),
       occurredAtMs = Value(occurredAtMs),
       createdAtMs = Value(createdAtMs);
  static Insertable<AnalyticsEventQueueData> custom({
    Expression<String>? eventId,
    Expression<String>? eventName,
    Expression<String>? sessionId,
    Expression<int>? occurredAtMs,
    Expression<int>? schemaVersion,
    Expression<String>? userId,
    Expression<String>? identityScope,
    Expression<String>? propertiesJson,
    Expression<int>? attemptCount,
    Expression<int>? nextRetryAtMs,
    Expression<int>? createdAtMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (eventId != null) 'event_id': eventId,
      if (eventName != null) 'event_name': eventName,
      if (sessionId != null) 'session_id': sessionId,
      if (occurredAtMs != null) 'occurred_at_ms': occurredAtMs,
      if (schemaVersion != null) 'schema_version': schemaVersion,
      if (userId != null) 'user_id': userId,
      if (identityScope != null) 'identity_scope': identityScope,
      if (propertiesJson != null) 'properties_json': propertiesJson,
      if (attemptCount != null) 'attempt_count': attemptCount,
      if (nextRetryAtMs != null) 'next_retry_at_ms': nextRetryAtMs,
      if (createdAtMs != null) 'created_at_ms': createdAtMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AnalyticsEventQueueCompanion copyWith({
    Value<String>? eventId,
    Value<String>? eventName,
    Value<String>? sessionId,
    Value<int>? occurredAtMs,
    Value<int>? schemaVersion,
    Value<String?>? userId,
    Value<String>? identityScope,
    Value<String>? propertiesJson,
    Value<int>? attemptCount,
    Value<int?>? nextRetryAtMs,
    Value<int>? createdAtMs,
    Value<int>? rowid,
  }) {
    return AnalyticsEventQueueCompanion(
      eventId: eventId ?? this.eventId,
      eventName: eventName ?? this.eventName,
      sessionId: sessionId ?? this.sessionId,
      occurredAtMs: occurredAtMs ?? this.occurredAtMs,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      userId: userId ?? this.userId,
      identityScope: identityScope ?? this.identityScope,
      propertiesJson: propertiesJson ?? this.propertiesJson,
      attemptCount: attemptCount ?? this.attemptCount,
      nextRetryAtMs: nextRetryAtMs ?? this.nextRetryAtMs,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (eventName.present) {
      map['event_name'] = Variable<String>(eventName.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (occurredAtMs.present) {
      map['occurred_at_ms'] = Variable<int>(occurredAtMs.value);
    }
    if (schemaVersion.present) {
      map['schema_version'] = Variable<int>(schemaVersion.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (identityScope.present) {
      map['identity_scope'] = Variable<String>(identityScope.value);
    }
    if (propertiesJson.present) {
      map['properties_json'] = Variable<String>(propertiesJson.value);
    }
    if (attemptCount.present) {
      map['attempt_count'] = Variable<int>(attemptCount.value);
    }
    if (nextRetryAtMs.present) {
      map['next_retry_at_ms'] = Variable<int>(nextRetryAtMs.value);
    }
    if (createdAtMs.present) {
      map['created_at_ms'] = Variable<int>(createdAtMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AnalyticsEventQueueCompanion(')
          ..write('eventId: $eventId, ')
          ..write('eventName: $eventName, ')
          ..write('sessionId: $sessionId, ')
          ..write('occurredAtMs: $occurredAtMs, ')
          ..write('schemaVersion: $schemaVersion, ')
          ..write('userId: $userId, ')
          ..write('identityScope: $identityScope, ')
          ..write('propertiesJson: $propertiesJson, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('nextRetryAtMs: $nextRetryAtMs, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LedgersTable ledgers = $LedgersTable(this);
  late final $AccountsTable accounts = $AccountsTable(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $LedgerTransactionsTable ledgerTransactions =
      $LedgerTransactionsTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $BudgetsTable budgets = $BudgetsTable(this);
  late final $AnalyticsEventQueueTable analyticsEventQueue =
      $AnalyticsEventQueueTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    ledgers,
    accounts,
    categories,
    ledgerTransactions,
    appSettings,
    budgets,
    analyticsEventQueue,
  ];
}

typedef $$LedgersTableCreateCompanionBuilder =
    LedgersCompanion Function({
      required String id,
      required String name,
      Value<String> currencyCode,
      required String timeZoneId,
      Value<bool> isDefault,
      Value<String?> settingsJson,
      required int createdAtMs,
      required int updatedAtMs,
      Value<int?> deletedAtMs,
      Value<int> version,
      Value<String?> lastModifiedDeviceId,
      Value<String> syncStatus,
      Value<int?> legacyId,
      Value<int> rowid,
    });
typedef $$LedgersTableUpdateCompanionBuilder =
    LedgersCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> currencyCode,
      Value<String> timeZoneId,
      Value<bool> isDefault,
      Value<String?> settingsJson,
      Value<int> createdAtMs,
      Value<int> updatedAtMs,
      Value<int?> deletedAtMs,
      Value<int> version,
      Value<String?> lastModifiedDeviceId,
      Value<String> syncStatus,
      Value<int?> legacyId,
      Value<int> rowid,
    });

final class $$LedgersTableReferences
    extends BaseReferences<_$AppDatabase, $LedgersTable, Ledger> {
  $$LedgersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$AccountsTable, List<Account>> _accountsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.accounts,
    aliasName: 'ledgers__id__accounts__ledger_id',
  );

  $$AccountsTableProcessedTableManager get accountsRefs {
    final manager = $$AccountsTableTableManager(
      $_db,
      $_db.accounts,
    ).filter((f) => f.ledgerId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_accountsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CategoriesTable, List<Category>>
  _categoriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.categories,
    aliasName: 'ledgers__id__categories__ledger_id',
  );

  $$CategoriesTableProcessedTableManager get categoriesRefs {
    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.ledgerId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_categoriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$LedgerTransactionsTable, List<LedgerTransaction>>
  _ledgerTransactionsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.ledgerTransactions,
        aliasName: 'ledgers__id__transactions__ledger_id',
      );

  $$LedgerTransactionsTableProcessedTableManager get ledgerTransactionsRefs {
    final manager = $$LedgerTransactionsTableTableManager(
      $_db,
      $_db.ledgerTransactions,
    ).filter((f) => f.ledgerId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _ledgerTransactionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$BudgetsTable, List<Budget>> _budgetsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.budgets,
    aliasName: 'ledgers__id__budgets__ledger_id',
  );

  $$BudgetsTableProcessedTableManager get budgetsRefs {
    final manager = $$BudgetsTableTableManager(
      $_db,
      $_db.budgets,
    ).filter((f) => f.ledgerId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_budgetsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$LedgersTableFilterComposer
    extends Composer<_$AppDatabase, $LedgersTable> {
  $$LedgersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timeZoneId => $composableBuilder(
    column: $table.timeZoneId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get settingsJson => $composableBuilder(
    column: $table.settingsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAtMs => $composableBuilder(
    column: $table.deletedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastModifiedDeviceId => $composableBuilder(
    column: $table.lastModifiedDeviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get legacyId => $composableBuilder(
    column: $table.legacyId,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> accountsRefs(
    Expression<bool> Function($$AccountsTableFilterComposer f) f,
  ) {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.ledgerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableFilterComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> categoriesRefs(
    Expression<bool> Function($$CategoriesTableFilterComposer f) f,
  ) {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.ledgerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> ledgerTransactionsRefs(
    Expression<bool> Function($$LedgerTransactionsTableFilterComposer f) f,
  ) {
    final $$LedgerTransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ledgerTransactions,
      getReferencedColumn: (t) => t.ledgerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LedgerTransactionsTableFilterComposer(
            $db: $db,
            $table: $db.ledgerTransactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> budgetsRefs(
    Expression<bool> Function($$BudgetsTableFilterComposer f) f,
  ) {
    final $$BudgetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.budgets,
      getReferencedColumn: (t) => t.ledgerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BudgetsTableFilterComposer(
            $db: $db,
            $table: $db.budgets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LedgersTableOrderingComposer
    extends Composer<_$AppDatabase, $LedgersTable> {
  $$LedgersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timeZoneId => $composableBuilder(
    column: $table.timeZoneId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get settingsJson => $composableBuilder(
    column: $table.settingsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAtMs => $composableBuilder(
    column: $table.deletedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastModifiedDeviceId => $composableBuilder(
    column: $table.lastModifiedDeviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get legacyId => $composableBuilder(
    column: $table.legacyId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LedgersTableAnnotationComposer
    extends Composer<_$AppDatabase, $LedgersTable> {
  $$LedgersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get timeZoneId => $composableBuilder(
    column: $table.timeZoneId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => column);

  GeneratedColumn<String> get settingsJson => $composableBuilder(
    column: $table.settingsJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get deletedAtMs => $composableBuilder(
    column: $table.deletedAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get lastModifiedDeviceId => $composableBuilder(
    column: $table.lastModifiedDeviceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get legacyId =>
      $composableBuilder(column: $table.legacyId, builder: (column) => column);

  Expression<T> accountsRefs<T extends Object>(
    Expression<T> Function($$AccountsTableAnnotationComposer a) f,
  ) {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.ledgerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> categoriesRefs<T extends Object>(
    Expression<T> Function($$CategoriesTableAnnotationComposer a) f,
  ) {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.ledgerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> ledgerTransactionsRefs<T extends Object>(
    Expression<T> Function($$LedgerTransactionsTableAnnotationComposer a) f,
  ) {
    final $$LedgerTransactionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.ledgerTransactions,
          getReferencedColumn: (t) => t.ledgerId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$LedgerTransactionsTableAnnotationComposer(
                $db: $db,
                $table: $db.ledgerTransactions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> budgetsRefs<T extends Object>(
    Expression<T> Function($$BudgetsTableAnnotationComposer a) f,
  ) {
    final $$BudgetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.budgets,
      getReferencedColumn: (t) => t.ledgerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BudgetsTableAnnotationComposer(
            $db: $db,
            $table: $db.budgets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LedgersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LedgersTable,
          Ledger,
          $$LedgersTableFilterComposer,
          $$LedgersTableOrderingComposer,
          $$LedgersTableAnnotationComposer,
          $$LedgersTableCreateCompanionBuilder,
          $$LedgersTableUpdateCompanionBuilder,
          (Ledger, $$LedgersTableReferences),
          Ledger,
          PrefetchHooks Function({
            bool accountsRefs,
            bool categoriesRefs,
            bool ledgerTransactionsRefs,
            bool budgetsRefs,
          })
        > {
  $$LedgersTableTableManager(_$AppDatabase db, $LedgersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LedgersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LedgersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LedgersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                Value<String> timeZoneId = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<String?> settingsJson = const Value.absent(),
                Value<int> createdAtMs = const Value.absent(),
                Value<int> updatedAtMs = const Value.absent(),
                Value<int?> deletedAtMs = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String?> lastModifiedDeviceId = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int?> legacyId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LedgersCompanion(
                id: id,
                name: name,
                currencyCode: currencyCode,
                timeZoneId: timeZoneId,
                isDefault: isDefault,
                settingsJson: settingsJson,
                createdAtMs: createdAtMs,
                updatedAtMs: updatedAtMs,
                deletedAtMs: deletedAtMs,
                version: version,
                lastModifiedDeviceId: lastModifiedDeviceId,
                syncStatus: syncStatus,
                legacyId: legacyId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String> currencyCode = const Value.absent(),
                required String timeZoneId,
                Value<bool> isDefault = const Value.absent(),
                Value<String?> settingsJson = const Value.absent(),
                required int createdAtMs,
                required int updatedAtMs,
                Value<int?> deletedAtMs = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String?> lastModifiedDeviceId = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int?> legacyId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LedgersCompanion.insert(
                id: id,
                name: name,
                currencyCode: currencyCode,
                timeZoneId: timeZoneId,
                isDefault: isDefault,
                settingsJson: settingsJson,
                createdAtMs: createdAtMs,
                updatedAtMs: updatedAtMs,
                deletedAtMs: deletedAtMs,
                version: version,
                lastModifiedDeviceId: lastModifiedDeviceId,
                syncStatus: syncStatus,
                legacyId: legacyId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LedgersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                accountsRefs = false,
                categoriesRefs = false,
                ledgerTransactionsRefs = false,
                budgetsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (accountsRefs) db.accounts,
                    if (categoriesRefs) db.categories,
                    if (ledgerTransactionsRefs) db.ledgerTransactions,
                    if (budgetsRefs) db.budgets,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (accountsRefs)
                        await $_getPrefetchedData<
                          Ledger,
                          $LedgersTable,
                          Account
                        >(
                          currentTable: table,
                          referencedTable: $$LedgersTableReferences
                              ._accountsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LedgersTableReferences(
                                db,
                                table,
                                p0,
                              ).accountsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.ledgerId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (categoriesRefs)
                        await $_getPrefetchedData<
                          Ledger,
                          $LedgersTable,
                          Category
                        >(
                          currentTable: table,
                          referencedTable: $$LedgersTableReferences
                              ._categoriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LedgersTableReferences(
                                db,
                                table,
                                p0,
                              ).categoriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.ledgerId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (ledgerTransactionsRefs)
                        await $_getPrefetchedData<
                          Ledger,
                          $LedgersTable,
                          LedgerTransaction
                        >(
                          currentTable: table,
                          referencedTable: $$LedgersTableReferences
                              ._ledgerTransactionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LedgersTableReferences(
                                db,
                                table,
                                p0,
                              ).ledgerTransactionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.ledgerId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (budgetsRefs)
                        await $_getPrefetchedData<
                          Ledger,
                          $LedgersTable,
                          Budget
                        >(
                          currentTable: table,
                          referencedTable: $$LedgersTableReferences
                              ._budgetsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LedgersTableReferences(
                                db,
                                table,
                                p0,
                              ).budgetsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.ledgerId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$LedgersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LedgersTable,
      Ledger,
      $$LedgersTableFilterComposer,
      $$LedgersTableOrderingComposer,
      $$LedgersTableAnnotationComposer,
      $$LedgersTableCreateCompanionBuilder,
      $$LedgersTableUpdateCompanionBuilder,
      (Ledger, $$LedgersTableReferences),
      Ledger,
      PrefetchHooks Function({
        bool accountsRefs,
        bool categoriesRefs,
        bool ledgerTransactionsRefs,
        bool budgetsRefs,
      })
    >;
typedef $$AccountsTableCreateCompanionBuilder =
    AccountsCompanion Function({
      required String id,
      required String ledgerId,
      required String name,
      required String normalizedName,
      Value<String> accountType,
      Value<int> openingBalanceMinor,
      Value<String?> iconCode,
      Value<int> sortOrder,
      Value<bool> enabled,
      required int createdAtMs,
      required int updatedAtMs,
      Value<int?> deletedAtMs,
      Value<int> version,
      Value<String?> lastModifiedDeviceId,
      Value<String> syncStatus,
      Value<int?> legacyId,
      Value<int> rowid,
    });
typedef $$AccountsTableUpdateCompanionBuilder =
    AccountsCompanion Function({
      Value<String> id,
      Value<String> ledgerId,
      Value<String> name,
      Value<String> normalizedName,
      Value<String> accountType,
      Value<int> openingBalanceMinor,
      Value<String?> iconCode,
      Value<int> sortOrder,
      Value<bool> enabled,
      Value<int> createdAtMs,
      Value<int> updatedAtMs,
      Value<int?> deletedAtMs,
      Value<int> version,
      Value<String?> lastModifiedDeviceId,
      Value<String> syncStatus,
      Value<int?> legacyId,
      Value<int> rowid,
    });

final class $$AccountsTableReferences
    extends BaseReferences<_$AppDatabase, $AccountsTable, Account> {
  $$AccountsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $LedgersTable _ledgerIdTable(_$AppDatabase db) =>
      db.ledgers.createAlias('accounts__ledger_id__ledgers__id');

  $$LedgersTableProcessedTableManager get ledgerId {
    final $_column = $_itemColumn<String>('ledger_id')!;

    final manager = $$LedgersTableTableManager(
      $_db,
      $_db.ledgers,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_ledgerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$LedgerTransactionsTable, List<LedgerTransaction>>
  _sourceTransactionsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.ledgerTransactions,
    aliasName: 'accounts__id__transactions__account_id',
  );

  $$LedgerTransactionsTableProcessedTableManager get sourceTransactions {
    final manager = $$LedgerTransactionsTableTableManager(
      $_db,
      $_db.ledgerTransactions,
    ).filter((f) => f.accountId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_sourceTransactionsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$LedgerTransactionsTable, List<LedgerTransaction>>
  _targetTransactionsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.ledgerTransactions,
    aliasName: 'accounts__id__transactions__to_account_id',
  );

  $$LedgerTransactionsTableProcessedTableManager get targetTransactions {
    final manager = $$LedgerTransactionsTableTableManager(
      $_db,
      $_db.ledgerTransactions,
    ).filter((f) => f.toAccountId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_targetTransactionsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AccountsTableFilterComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get normalizedName => $composableBuilder(
    column: $table.normalizedName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountType => $composableBuilder(
    column: $table.accountType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get openingBalanceMinor => $composableBuilder(
    column: $table.openingBalanceMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get iconCode => $composableBuilder(
    column: $table.iconCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAtMs => $composableBuilder(
    column: $table.deletedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastModifiedDeviceId => $composableBuilder(
    column: $table.lastModifiedDeviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get legacyId => $composableBuilder(
    column: $table.legacyId,
    builder: (column) => ColumnFilters(column),
  );

  $$LedgersTableFilterComposer get ledgerId {
    final $$LedgersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ledgerId,
      referencedTable: $db.ledgers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LedgersTableFilterComposer(
            $db: $db,
            $table: $db.ledgers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> sourceTransactions(
    Expression<bool> Function($$LedgerTransactionsTableFilterComposer f) f,
  ) {
    final $$LedgerTransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ledgerTransactions,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LedgerTransactionsTableFilterComposer(
            $db: $db,
            $table: $db.ledgerTransactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> targetTransactions(
    Expression<bool> Function($$LedgerTransactionsTableFilterComposer f) f,
  ) {
    final $$LedgerTransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ledgerTransactions,
      getReferencedColumn: (t) => t.toAccountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LedgerTransactionsTableFilterComposer(
            $db: $db,
            $table: $db.ledgerTransactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AccountsTableOrderingComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get normalizedName => $composableBuilder(
    column: $table.normalizedName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountType => $composableBuilder(
    column: $table.accountType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get openingBalanceMinor => $composableBuilder(
    column: $table.openingBalanceMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get iconCode => $composableBuilder(
    column: $table.iconCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAtMs => $composableBuilder(
    column: $table.deletedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastModifiedDeviceId => $composableBuilder(
    column: $table.lastModifiedDeviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get legacyId => $composableBuilder(
    column: $table.legacyId,
    builder: (column) => ColumnOrderings(column),
  );

  $$LedgersTableOrderingComposer get ledgerId {
    final $$LedgersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ledgerId,
      referencedTable: $db.ledgers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LedgersTableOrderingComposer(
            $db: $db,
            $table: $db.ledgers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AccountsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get normalizedName => $composableBuilder(
    column: $table.normalizedName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get accountType => $composableBuilder(
    column: $table.accountType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get openingBalanceMinor => $composableBuilder(
    column: $table.openingBalanceMinor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get iconCode =>
      $composableBuilder(column: $table.iconCode, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get deletedAtMs => $composableBuilder(
    column: $table.deletedAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get lastModifiedDeviceId => $composableBuilder(
    column: $table.lastModifiedDeviceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get legacyId =>
      $composableBuilder(column: $table.legacyId, builder: (column) => column);

  $$LedgersTableAnnotationComposer get ledgerId {
    final $$LedgersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ledgerId,
      referencedTable: $db.ledgers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LedgersTableAnnotationComposer(
            $db: $db,
            $table: $db.ledgers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> sourceTransactions<T extends Object>(
    Expression<T> Function($$LedgerTransactionsTableAnnotationComposer a) f,
  ) {
    final $$LedgerTransactionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.ledgerTransactions,
          getReferencedColumn: (t) => t.accountId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$LedgerTransactionsTableAnnotationComposer(
                $db: $db,
                $table: $db.ledgerTransactions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> targetTransactions<T extends Object>(
    Expression<T> Function($$LedgerTransactionsTableAnnotationComposer a) f,
  ) {
    final $$LedgerTransactionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.ledgerTransactions,
          getReferencedColumn: (t) => t.toAccountId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$LedgerTransactionsTableAnnotationComposer(
                $db: $db,
                $table: $db.ledgerTransactions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$AccountsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AccountsTable,
          Account,
          $$AccountsTableFilterComposer,
          $$AccountsTableOrderingComposer,
          $$AccountsTableAnnotationComposer,
          $$AccountsTableCreateCompanionBuilder,
          $$AccountsTableUpdateCompanionBuilder,
          (Account, $$AccountsTableReferences),
          Account,
          PrefetchHooks Function({
            bool ledgerId,
            bool sourceTransactions,
            bool targetTransactions,
          })
        > {
  $$AccountsTableTableManager(_$AppDatabase db, $AccountsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> ledgerId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> normalizedName = const Value.absent(),
                Value<String> accountType = const Value.absent(),
                Value<int> openingBalanceMinor = const Value.absent(),
                Value<String?> iconCode = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<int> createdAtMs = const Value.absent(),
                Value<int> updatedAtMs = const Value.absent(),
                Value<int?> deletedAtMs = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String?> lastModifiedDeviceId = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int?> legacyId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AccountsCompanion(
                id: id,
                ledgerId: ledgerId,
                name: name,
                normalizedName: normalizedName,
                accountType: accountType,
                openingBalanceMinor: openingBalanceMinor,
                iconCode: iconCode,
                sortOrder: sortOrder,
                enabled: enabled,
                createdAtMs: createdAtMs,
                updatedAtMs: updatedAtMs,
                deletedAtMs: deletedAtMs,
                version: version,
                lastModifiedDeviceId: lastModifiedDeviceId,
                syncStatus: syncStatus,
                legacyId: legacyId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String ledgerId,
                required String name,
                required String normalizedName,
                Value<String> accountType = const Value.absent(),
                Value<int> openingBalanceMinor = const Value.absent(),
                Value<String?> iconCode = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                required int createdAtMs,
                required int updatedAtMs,
                Value<int?> deletedAtMs = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String?> lastModifiedDeviceId = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int?> legacyId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AccountsCompanion.insert(
                id: id,
                ledgerId: ledgerId,
                name: name,
                normalizedName: normalizedName,
                accountType: accountType,
                openingBalanceMinor: openingBalanceMinor,
                iconCode: iconCode,
                sortOrder: sortOrder,
                enabled: enabled,
                createdAtMs: createdAtMs,
                updatedAtMs: updatedAtMs,
                deletedAtMs: deletedAtMs,
                version: version,
                lastModifiedDeviceId: lastModifiedDeviceId,
                syncStatus: syncStatus,
                legacyId: legacyId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AccountsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                ledgerId = false,
                sourceTransactions = false,
                targetTransactions = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (sourceTransactions) db.ledgerTransactions,
                    if (targetTransactions) db.ledgerTransactions,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (ledgerId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.ledgerId,
                                    referencedTable: $$AccountsTableReferences
                                        ._ledgerIdTable(db),
                                    referencedColumn: $$AccountsTableReferences
                                        ._ledgerIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (sourceTransactions)
                        await $_getPrefetchedData<
                          Account,
                          $AccountsTable,
                          LedgerTransaction
                        >(
                          currentTable: table,
                          referencedTable: $$AccountsTableReferences
                              ._sourceTransactionsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).sourceTransactions,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.accountId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (targetTransactions)
                        await $_getPrefetchedData<
                          Account,
                          $AccountsTable,
                          LedgerTransaction
                        >(
                          currentTable: table,
                          referencedTable: $$AccountsTableReferences
                              ._targetTransactionsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).targetTransactions,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.toAccountId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$AccountsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AccountsTable,
      Account,
      $$AccountsTableFilterComposer,
      $$AccountsTableOrderingComposer,
      $$AccountsTableAnnotationComposer,
      $$AccountsTableCreateCompanionBuilder,
      $$AccountsTableUpdateCompanionBuilder,
      (Account, $$AccountsTableReferences),
      Account,
      PrefetchHooks Function({
        bool ledgerId,
        bool sourceTransactions,
        bool targetTransactions,
      })
    >;
typedef $$CategoriesTableCreateCompanionBuilder =
    CategoriesCompanion Function({
      required String id,
      required String ledgerId,
      required String categoryType,
      required String name,
      required String normalizedName,
      Value<String?> iconCode,
      Value<String?> colorToken,
      Value<int> sortOrder,
      Value<bool> enabled,
      Value<String?> systemKey,
      required int createdAtMs,
      required int updatedAtMs,
      Value<int?> deletedAtMs,
      Value<int> version,
      Value<String?> lastModifiedDeviceId,
      Value<String> syncStatus,
      Value<int?> legacyId,
      Value<int> rowid,
    });
typedef $$CategoriesTableUpdateCompanionBuilder =
    CategoriesCompanion Function({
      Value<String> id,
      Value<String> ledgerId,
      Value<String> categoryType,
      Value<String> name,
      Value<String> normalizedName,
      Value<String?> iconCode,
      Value<String?> colorToken,
      Value<int> sortOrder,
      Value<bool> enabled,
      Value<String?> systemKey,
      Value<int> createdAtMs,
      Value<int> updatedAtMs,
      Value<int?> deletedAtMs,
      Value<int> version,
      Value<String?> lastModifiedDeviceId,
      Value<String> syncStatus,
      Value<int?> legacyId,
      Value<int> rowid,
    });

final class $$CategoriesTableReferences
    extends BaseReferences<_$AppDatabase, $CategoriesTable, Category> {
  $$CategoriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $LedgersTable _ledgerIdTable(_$AppDatabase db) =>
      db.ledgers.createAlias('categories__ledger_id__ledgers__id');

  $$LedgersTableProcessedTableManager get ledgerId {
    final $_column = $_itemColumn<String>('ledger_id')!;

    final manager = $$LedgersTableTableManager(
      $_db,
      $_db.ledgers,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_ledgerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$LedgerTransactionsTable, List<LedgerTransaction>>
  _ledgerTransactionsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.ledgerTransactions,
        aliasName: 'categories__id__transactions__category_id',
      );

  $$LedgerTransactionsTableProcessedTableManager get ledgerTransactionsRefs {
    final manager = $$LedgerTransactionsTableTableManager(
      $_db,
      $_db.ledgerTransactions,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _ledgerTransactionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$BudgetsTable, List<Budget>> _budgetsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.budgets,
    aliasName: 'categories__id__budgets__category_id',
  );

  $$BudgetsTableProcessedTableManager get budgetsRefs {
    final manager = $$BudgetsTableTableManager(
      $_db,
      $_db.budgets,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_budgetsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryType => $composableBuilder(
    column: $table.categoryType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get normalizedName => $composableBuilder(
    column: $table.normalizedName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get iconCode => $composableBuilder(
    column: $table.iconCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get colorToken => $composableBuilder(
    column: $table.colorToken,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get systemKey => $composableBuilder(
    column: $table.systemKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAtMs => $composableBuilder(
    column: $table.deletedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastModifiedDeviceId => $composableBuilder(
    column: $table.lastModifiedDeviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get legacyId => $composableBuilder(
    column: $table.legacyId,
    builder: (column) => ColumnFilters(column),
  );

  $$LedgersTableFilterComposer get ledgerId {
    final $$LedgersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ledgerId,
      referencedTable: $db.ledgers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LedgersTableFilterComposer(
            $db: $db,
            $table: $db.ledgers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> ledgerTransactionsRefs(
    Expression<bool> Function($$LedgerTransactionsTableFilterComposer f) f,
  ) {
    final $$LedgerTransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.ledgerTransactions,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LedgerTransactionsTableFilterComposer(
            $db: $db,
            $table: $db.ledgerTransactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> budgetsRefs(
    Expression<bool> Function($$BudgetsTableFilterComposer f) f,
  ) {
    final $$BudgetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.budgets,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BudgetsTableFilterComposer(
            $db: $db,
            $table: $db.budgets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryType => $composableBuilder(
    column: $table.categoryType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get normalizedName => $composableBuilder(
    column: $table.normalizedName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get iconCode => $composableBuilder(
    column: $table.iconCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get colorToken => $composableBuilder(
    column: $table.colorToken,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get systemKey => $composableBuilder(
    column: $table.systemKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAtMs => $composableBuilder(
    column: $table.deletedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastModifiedDeviceId => $composableBuilder(
    column: $table.lastModifiedDeviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get legacyId => $composableBuilder(
    column: $table.legacyId,
    builder: (column) => ColumnOrderings(column),
  );

  $$LedgersTableOrderingComposer get ledgerId {
    final $$LedgersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ledgerId,
      referencedTable: $db.ledgers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LedgersTableOrderingComposer(
            $db: $db,
            $table: $db.ledgers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get categoryType => $composableBuilder(
    column: $table.categoryType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get normalizedName => $composableBuilder(
    column: $table.normalizedName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get iconCode =>
      $composableBuilder(column: $table.iconCode, builder: (column) => column);

  GeneratedColumn<String> get colorToken => $composableBuilder(
    column: $table.colorToken,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<String> get systemKey =>
      $composableBuilder(column: $table.systemKey, builder: (column) => column);

  GeneratedColumn<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get deletedAtMs => $composableBuilder(
    column: $table.deletedAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get lastModifiedDeviceId => $composableBuilder(
    column: $table.lastModifiedDeviceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get legacyId =>
      $composableBuilder(column: $table.legacyId, builder: (column) => column);

  $$LedgersTableAnnotationComposer get ledgerId {
    final $$LedgersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ledgerId,
      referencedTable: $db.ledgers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LedgersTableAnnotationComposer(
            $db: $db,
            $table: $db.ledgers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> ledgerTransactionsRefs<T extends Object>(
    Expression<T> Function($$LedgerTransactionsTableAnnotationComposer a) f,
  ) {
    final $$LedgerTransactionsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.ledgerTransactions,
          getReferencedColumn: (t) => t.categoryId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$LedgerTransactionsTableAnnotationComposer(
                $db: $db,
                $table: $db.ledgerTransactions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> budgetsRefs<T extends Object>(
    Expression<T> Function($$BudgetsTableAnnotationComposer a) f,
  ) {
    final $$BudgetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.budgets,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BudgetsTableAnnotationComposer(
            $db: $db,
            $table: $db.budgets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoriesTable,
          Category,
          $$CategoriesTableFilterComposer,
          $$CategoriesTableOrderingComposer,
          $$CategoriesTableAnnotationComposer,
          $$CategoriesTableCreateCompanionBuilder,
          $$CategoriesTableUpdateCompanionBuilder,
          (Category, $$CategoriesTableReferences),
          Category,
          PrefetchHooks Function({
            bool ledgerId,
            bool ledgerTransactionsRefs,
            bool budgetsRefs,
          })
        > {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> ledgerId = const Value.absent(),
                Value<String> categoryType = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> normalizedName = const Value.absent(),
                Value<String?> iconCode = const Value.absent(),
                Value<String?> colorToken = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<String?> systemKey = const Value.absent(),
                Value<int> createdAtMs = const Value.absent(),
                Value<int> updatedAtMs = const Value.absent(),
                Value<int?> deletedAtMs = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String?> lastModifiedDeviceId = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int?> legacyId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion(
                id: id,
                ledgerId: ledgerId,
                categoryType: categoryType,
                name: name,
                normalizedName: normalizedName,
                iconCode: iconCode,
                colorToken: colorToken,
                sortOrder: sortOrder,
                enabled: enabled,
                systemKey: systemKey,
                createdAtMs: createdAtMs,
                updatedAtMs: updatedAtMs,
                deletedAtMs: deletedAtMs,
                version: version,
                lastModifiedDeviceId: lastModifiedDeviceId,
                syncStatus: syncStatus,
                legacyId: legacyId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String ledgerId,
                required String categoryType,
                required String name,
                required String normalizedName,
                Value<String?> iconCode = const Value.absent(),
                Value<String?> colorToken = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<String?> systemKey = const Value.absent(),
                required int createdAtMs,
                required int updatedAtMs,
                Value<int?> deletedAtMs = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String?> lastModifiedDeviceId = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int?> legacyId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion.insert(
                id: id,
                ledgerId: ledgerId,
                categoryType: categoryType,
                name: name,
                normalizedName: normalizedName,
                iconCode: iconCode,
                colorToken: colorToken,
                sortOrder: sortOrder,
                enabled: enabled,
                systemKey: systemKey,
                createdAtMs: createdAtMs,
                updatedAtMs: updatedAtMs,
                deletedAtMs: deletedAtMs,
                version: version,
                lastModifiedDeviceId: lastModifiedDeviceId,
                syncStatus: syncStatus,
                legacyId: legacyId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CategoriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                ledgerId = false,
                ledgerTransactionsRefs = false,
                budgetsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (ledgerTransactionsRefs) db.ledgerTransactions,
                    if (budgetsRefs) db.budgets,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (ledgerId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.ledgerId,
                                    referencedTable: $$CategoriesTableReferences
                                        ._ledgerIdTable(db),
                                    referencedColumn:
                                        $$CategoriesTableReferences
                                            ._ledgerIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (ledgerTransactionsRefs)
                        await $_getPrefetchedData<
                          Category,
                          $CategoriesTable,
                          LedgerTransaction
                        >(
                          currentTable: table,
                          referencedTable: $$CategoriesTableReferences
                              ._ledgerTransactionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CategoriesTableReferences(
                                db,
                                table,
                                p0,
                              ).ledgerTransactionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.categoryId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (budgetsRefs)
                        await $_getPrefetchedData<
                          Category,
                          $CategoriesTable,
                          Budget
                        >(
                          currentTable: table,
                          referencedTable: $$CategoriesTableReferences
                              ._budgetsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CategoriesTableReferences(
                                db,
                                table,
                                p0,
                              ).budgetsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.categoryId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$CategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoriesTable,
      Category,
      $$CategoriesTableFilterComposer,
      $$CategoriesTableOrderingComposer,
      $$CategoriesTableAnnotationComposer,
      $$CategoriesTableCreateCompanionBuilder,
      $$CategoriesTableUpdateCompanionBuilder,
      (Category, $$CategoriesTableReferences),
      Category,
      PrefetchHooks Function({
        bool ledgerId,
        bool ledgerTransactionsRefs,
        bool budgetsRefs,
      })
    >;
typedef $$LedgerTransactionsTableCreateCompanionBuilder =
    LedgerTransactionsCompanion Function({
      required String id,
      required String ledgerId,
      required String transactionType,
      required String accountId,
      Value<String?> toAccountId,
      Value<String?> categoryId,
      required int amountMinor,
      required int occurredAtUtcMs,
      required String timeZoneId,
      Value<String?> note,
      Value<String?> merchant,
      Value<String> sourceType,
      Value<String?> transferGroupId,
      required int createdAtMs,
      required int updatedAtMs,
      Value<int?> deletedAtMs,
      Value<int> version,
      Value<String?> lastModifiedDeviceId,
      Value<String> syncStatus,
      Value<int?> legacyId,
      Value<int> rowid,
    });
typedef $$LedgerTransactionsTableUpdateCompanionBuilder =
    LedgerTransactionsCompanion Function({
      Value<String> id,
      Value<String> ledgerId,
      Value<String> transactionType,
      Value<String> accountId,
      Value<String?> toAccountId,
      Value<String?> categoryId,
      Value<int> amountMinor,
      Value<int> occurredAtUtcMs,
      Value<String> timeZoneId,
      Value<String?> note,
      Value<String?> merchant,
      Value<String> sourceType,
      Value<String?> transferGroupId,
      Value<int> createdAtMs,
      Value<int> updatedAtMs,
      Value<int?> deletedAtMs,
      Value<int> version,
      Value<String?> lastModifiedDeviceId,
      Value<String> syncStatus,
      Value<int?> legacyId,
      Value<int> rowid,
    });

final class $$LedgerTransactionsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $LedgerTransactionsTable,
          LedgerTransaction
        > {
  $$LedgerTransactionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $LedgersTable _ledgerIdTable(_$AppDatabase db) =>
      db.ledgers.createAlias('transactions__ledger_id__ledgers__id');

  $$LedgersTableProcessedTableManager get ledgerId {
    final $_column = $_itemColumn<String>('ledger_id')!;

    final manager = $$LedgersTableTableManager(
      $_db,
      $_db.ledgers,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_ledgerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $AccountsTable _accountIdTable(_$AppDatabase db) =>
      db.accounts.createAlias('transactions__account_id__accounts__id');

  $$AccountsTableProcessedTableManager get accountId {
    final $_column = $_itemColumn<String>('account_id')!;

    final manager = $$AccountsTableTableManager(
      $_db,
      $_db.accounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $AccountsTable _toAccountIdTable(_$AppDatabase db) =>
      db.accounts.createAlias('transactions__to_account_id__accounts__id');

  $$AccountsTableProcessedTableManager? get toAccountId {
    final $_column = $_itemColumn<String>('to_account_id');
    if ($_column == null) return null;
    final manager = $$AccountsTableTableManager(
      $_db,
      $_db.accounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_toAccountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CategoriesTable _categoryIdTable(_$AppDatabase db) =>
      db.categories.createAlias('transactions__category_id__categories__id');

  $$CategoriesTableProcessedTableManager? get categoryId {
    final $_column = $_itemColumn<String>('category_id');
    if ($_column == null) return null;
    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LedgerTransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $LedgerTransactionsTable> {
  $$LedgerTransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transactionType => $composableBuilder(
    column: $table.transactionType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get occurredAtUtcMs => $composableBuilder(
    column: $table.occurredAtUtcMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timeZoneId => $composableBuilder(
    column: $table.timeZoneId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get merchant => $composableBuilder(
    column: $table.merchant,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get transferGroupId => $composableBuilder(
    column: $table.transferGroupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAtMs => $composableBuilder(
    column: $table.deletedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastModifiedDeviceId => $composableBuilder(
    column: $table.lastModifiedDeviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get legacyId => $composableBuilder(
    column: $table.legacyId,
    builder: (column) => ColumnFilters(column),
  );

  $$LedgersTableFilterComposer get ledgerId {
    final $$LedgersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ledgerId,
      referencedTable: $db.ledgers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LedgersTableFilterComposer(
            $db: $db,
            $table: $db.ledgers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableFilterComposer get accountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableFilterComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableFilterComposer get toAccountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.toAccountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableFilterComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LedgerTransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $LedgerTransactionsTable> {
  $$LedgerTransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transactionType => $composableBuilder(
    column: $table.transactionType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get occurredAtUtcMs => $composableBuilder(
    column: $table.occurredAtUtcMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timeZoneId => $composableBuilder(
    column: $table.timeZoneId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get merchant => $composableBuilder(
    column: $table.merchant,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get transferGroupId => $composableBuilder(
    column: $table.transferGroupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAtMs => $composableBuilder(
    column: $table.deletedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastModifiedDeviceId => $composableBuilder(
    column: $table.lastModifiedDeviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get legacyId => $composableBuilder(
    column: $table.legacyId,
    builder: (column) => ColumnOrderings(column),
  );

  $$LedgersTableOrderingComposer get ledgerId {
    final $$LedgersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ledgerId,
      referencedTable: $db.ledgers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LedgersTableOrderingComposer(
            $db: $db,
            $table: $db.ledgers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableOrderingComposer get accountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableOrderingComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableOrderingComposer get toAccountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.toAccountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableOrderingComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LedgerTransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LedgerTransactionsTable> {
  $$LedgerTransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get transactionType => $composableBuilder(
    column: $table.transactionType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => column,
  );

  GeneratedColumn<int> get occurredAtUtcMs => $composableBuilder(
    column: $table.occurredAtUtcMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get timeZoneId => $composableBuilder(
    column: $table.timeZoneId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get merchant =>
      $composableBuilder(column: $table.merchant, builder: (column) => column);

  GeneratedColumn<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get transferGroupId => $composableBuilder(
    column: $table.transferGroupId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get deletedAtMs => $composableBuilder(
    column: $table.deletedAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get lastModifiedDeviceId => $composableBuilder(
    column: $table.lastModifiedDeviceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get legacyId =>
      $composableBuilder(column: $table.legacyId, builder: (column) => column);

  $$LedgersTableAnnotationComposer get ledgerId {
    final $$LedgersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ledgerId,
      referencedTable: $db.ledgers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LedgersTableAnnotationComposer(
            $db: $db,
            $table: $db.ledgers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableAnnotationComposer get accountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableAnnotationComposer get toAccountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.toAccountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LedgerTransactionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LedgerTransactionsTable,
          LedgerTransaction,
          $$LedgerTransactionsTableFilterComposer,
          $$LedgerTransactionsTableOrderingComposer,
          $$LedgerTransactionsTableAnnotationComposer,
          $$LedgerTransactionsTableCreateCompanionBuilder,
          $$LedgerTransactionsTableUpdateCompanionBuilder,
          (LedgerTransaction, $$LedgerTransactionsTableReferences),
          LedgerTransaction,
          PrefetchHooks Function({
            bool ledgerId,
            bool accountId,
            bool toAccountId,
            bool categoryId,
          })
        > {
  $$LedgerTransactionsTableTableManager(
    _$AppDatabase db,
    $LedgerTransactionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LedgerTransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LedgerTransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LedgerTransactionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> ledgerId = const Value.absent(),
                Value<String> transactionType = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<String?> toAccountId = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<int> amountMinor = const Value.absent(),
                Value<int> occurredAtUtcMs = const Value.absent(),
                Value<String> timeZoneId = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> merchant = const Value.absent(),
                Value<String> sourceType = const Value.absent(),
                Value<String?> transferGroupId = const Value.absent(),
                Value<int> createdAtMs = const Value.absent(),
                Value<int> updatedAtMs = const Value.absent(),
                Value<int?> deletedAtMs = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String?> lastModifiedDeviceId = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int?> legacyId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LedgerTransactionsCompanion(
                id: id,
                ledgerId: ledgerId,
                transactionType: transactionType,
                accountId: accountId,
                toAccountId: toAccountId,
                categoryId: categoryId,
                amountMinor: amountMinor,
                occurredAtUtcMs: occurredAtUtcMs,
                timeZoneId: timeZoneId,
                note: note,
                merchant: merchant,
                sourceType: sourceType,
                transferGroupId: transferGroupId,
                createdAtMs: createdAtMs,
                updatedAtMs: updatedAtMs,
                deletedAtMs: deletedAtMs,
                version: version,
                lastModifiedDeviceId: lastModifiedDeviceId,
                syncStatus: syncStatus,
                legacyId: legacyId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String ledgerId,
                required String transactionType,
                required String accountId,
                Value<String?> toAccountId = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                required int amountMinor,
                required int occurredAtUtcMs,
                required String timeZoneId,
                Value<String?> note = const Value.absent(),
                Value<String?> merchant = const Value.absent(),
                Value<String> sourceType = const Value.absent(),
                Value<String?> transferGroupId = const Value.absent(),
                required int createdAtMs,
                required int updatedAtMs,
                Value<int?> deletedAtMs = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String?> lastModifiedDeviceId = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int?> legacyId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LedgerTransactionsCompanion.insert(
                id: id,
                ledgerId: ledgerId,
                transactionType: transactionType,
                accountId: accountId,
                toAccountId: toAccountId,
                categoryId: categoryId,
                amountMinor: amountMinor,
                occurredAtUtcMs: occurredAtUtcMs,
                timeZoneId: timeZoneId,
                note: note,
                merchant: merchant,
                sourceType: sourceType,
                transferGroupId: transferGroupId,
                createdAtMs: createdAtMs,
                updatedAtMs: updatedAtMs,
                deletedAtMs: deletedAtMs,
                version: version,
                lastModifiedDeviceId: lastModifiedDeviceId,
                syncStatus: syncStatus,
                legacyId: legacyId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LedgerTransactionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                ledgerId = false,
                accountId = false,
                toAccountId = false,
                categoryId = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (ledgerId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.ledgerId,
                                    referencedTable:
                                        $$LedgerTransactionsTableReferences
                                            ._ledgerIdTable(db),
                                    referencedColumn:
                                        $$LedgerTransactionsTableReferences
                                            ._ledgerIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (accountId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.accountId,
                                    referencedTable:
                                        $$LedgerTransactionsTableReferences
                                            ._accountIdTable(db),
                                    referencedColumn:
                                        $$LedgerTransactionsTableReferences
                                            ._accountIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (toAccountId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.toAccountId,
                                    referencedTable:
                                        $$LedgerTransactionsTableReferences
                                            ._toAccountIdTable(db),
                                    referencedColumn:
                                        $$LedgerTransactionsTableReferences
                                            ._toAccountIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (categoryId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.categoryId,
                                    referencedTable:
                                        $$LedgerTransactionsTableReferences
                                            ._categoryIdTable(db),
                                    referencedColumn:
                                        $$LedgerTransactionsTableReferences
                                            ._categoryIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$LedgerTransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LedgerTransactionsTable,
      LedgerTransaction,
      $$LedgerTransactionsTableFilterComposer,
      $$LedgerTransactionsTableOrderingComposer,
      $$LedgerTransactionsTableAnnotationComposer,
      $$LedgerTransactionsTableCreateCompanionBuilder,
      $$LedgerTransactionsTableUpdateCompanionBuilder,
      (LedgerTransaction, $$LedgerTransactionsTableReferences),
      LedgerTransaction,
      PrefetchHooks Function({
        bool ledgerId,
        bool accountId,
        bool toAccountId,
        bool categoryId,
      })
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      required String key,
      required String valueType,
      Value<String?> valueText,
      required int updatedAtMs,
      Value<String> syncScope,
      Value<int> rowid,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<String> key,
      Value<String> valueType,
      Value<String?> valueText,
      Value<int> updatedAtMs,
      Value<String> syncScope,
      Value<int> rowid,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get valueType => $composableBuilder(
    column: $table.valueType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get valueText => $composableBuilder(
    column: $table.valueText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncScope => $composableBuilder(
    column: $table.syncScope,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get valueType => $composableBuilder(
    column: $table.valueType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get valueText => $composableBuilder(
    column: $table.valueText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncScope => $composableBuilder(
    column: $table.syncScope,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get valueType =>
      $composableBuilder(column: $table.valueType, builder: (column) => column);

  GeneratedColumn<String> get valueText =>
      $composableBuilder(column: $table.valueText, builder: (column) => column);

  GeneratedColumn<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncScope =>
      $composableBuilder(column: $table.syncScope, builder: (column) => column);
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSetting,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSetting,
            BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
          ),
          AppSetting,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> valueType = const Value.absent(),
                Value<String?> valueText = const Value.absent(),
                Value<int> updatedAtMs = const Value.absent(),
                Value<String> syncScope = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion(
                key: key,
                valueType: valueType,
                valueText: valueText,
                updatedAtMs: updatedAtMs,
                syncScope: syncScope,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String valueType,
                Value<String?> valueText = const Value.absent(),
                required int updatedAtMs,
                Value<String> syncScope = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                key: key,
                valueType: valueType,
                valueText: valueText,
                updatedAtMs: updatedAtMs,
                syncScope: syncScope,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSetting,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSetting,
        BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
      ),
      AppSetting,
      PrefetchHooks Function()
    >;
typedef $$BudgetsTableCreateCompanionBuilder =
    BudgetsCompanion Function({
      required String id,
      required String ledgerId,
      required String name,
      required String scopeType,
      Value<String?> categoryId,
      required String yearMonth,
      required int amountMinor,
      required String currencyCode,
      required String timeZoneId,
      Value<String> periodType,
      required String startDateLocal,
      required String endDateLocal,
      Value<String?> alertThresholdsJson,
      Value<bool> isActive,
      required int createdAtMs,
      required int updatedAtMs,
      Value<int?> deletedAtMs,
      Value<int> version,
      Value<String?> lastModifiedDeviceId,
      Value<String> syncStatus,
      Value<int?> legacyId,
      Value<int> rowid,
    });
typedef $$BudgetsTableUpdateCompanionBuilder =
    BudgetsCompanion Function({
      Value<String> id,
      Value<String> ledgerId,
      Value<String> name,
      Value<String> scopeType,
      Value<String?> categoryId,
      Value<String> yearMonth,
      Value<int> amountMinor,
      Value<String> currencyCode,
      Value<String> timeZoneId,
      Value<String> periodType,
      Value<String> startDateLocal,
      Value<String> endDateLocal,
      Value<String?> alertThresholdsJson,
      Value<bool> isActive,
      Value<int> createdAtMs,
      Value<int> updatedAtMs,
      Value<int?> deletedAtMs,
      Value<int> version,
      Value<String?> lastModifiedDeviceId,
      Value<String> syncStatus,
      Value<int?> legacyId,
      Value<int> rowid,
    });

final class $$BudgetsTableReferences
    extends BaseReferences<_$AppDatabase, $BudgetsTable, Budget> {
  $$BudgetsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $LedgersTable _ledgerIdTable(_$AppDatabase db) =>
      db.ledgers.createAlias('budgets__ledger_id__ledgers__id');

  $$LedgersTableProcessedTableManager get ledgerId {
    final $_column = $_itemColumn<String>('ledger_id')!;

    final manager = $$LedgersTableTableManager(
      $_db,
      $_db.ledgers,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_ledgerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CategoriesTable _categoryIdTable(_$AppDatabase db) =>
      db.categories.createAlias('budgets__category_id__categories__id');

  $$CategoriesTableProcessedTableManager? get categoryId {
    final $_column = $_itemColumn<String>('category_id');
    if ($_column == null) return null;
    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$BudgetsTableFilterComposer
    extends Composer<_$AppDatabase, $BudgetsTable> {
  $$BudgetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scopeType => $composableBuilder(
    column: $table.scopeType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get yearMonth => $composableBuilder(
    column: $table.yearMonth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timeZoneId => $composableBuilder(
    column: $table.timeZoneId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get periodType => $composableBuilder(
    column: $table.periodType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startDateLocal => $composableBuilder(
    column: $table.startDateLocal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endDateLocal => $composableBuilder(
    column: $table.endDateLocal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get alertThresholdsJson => $composableBuilder(
    column: $table.alertThresholdsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAtMs => $composableBuilder(
    column: $table.deletedAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastModifiedDeviceId => $composableBuilder(
    column: $table.lastModifiedDeviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get legacyId => $composableBuilder(
    column: $table.legacyId,
    builder: (column) => ColumnFilters(column),
  );

  $$LedgersTableFilterComposer get ledgerId {
    final $$LedgersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ledgerId,
      referencedTable: $db.ledgers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LedgersTableFilterComposer(
            $db: $db,
            $table: $db.ledgers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BudgetsTableOrderingComposer
    extends Composer<_$AppDatabase, $BudgetsTable> {
  $$BudgetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scopeType => $composableBuilder(
    column: $table.scopeType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get yearMonth => $composableBuilder(
    column: $table.yearMonth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timeZoneId => $composableBuilder(
    column: $table.timeZoneId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get periodType => $composableBuilder(
    column: $table.periodType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startDateLocal => $composableBuilder(
    column: $table.startDateLocal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endDateLocal => $composableBuilder(
    column: $table.endDateLocal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get alertThresholdsJson => $composableBuilder(
    column: $table.alertThresholdsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAtMs => $composableBuilder(
    column: $table.deletedAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastModifiedDeviceId => $composableBuilder(
    column: $table.lastModifiedDeviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get legacyId => $composableBuilder(
    column: $table.legacyId,
    builder: (column) => ColumnOrderings(column),
  );

  $$LedgersTableOrderingComposer get ledgerId {
    final $$LedgersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ledgerId,
      referencedTable: $db.ledgers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LedgersTableOrderingComposer(
            $db: $db,
            $table: $db.ledgers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BudgetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BudgetsTable> {
  $$BudgetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get scopeType =>
      $composableBuilder(column: $table.scopeType, builder: (column) => column);

  GeneratedColumn<String> get yearMonth =>
      $composableBuilder(column: $table.yearMonth, builder: (column) => column);

  GeneratedColumn<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get timeZoneId => $composableBuilder(
    column: $table.timeZoneId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get periodType => $composableBuilder(
    column: $table.periodType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get startDateLocal => $composableBuilder(
    column: $table.startDateLocal,
    builder: (column) => column,
  );

  GeneratedColumn<String> get endDateLocal => $composableBuilder(
    column: $table.endDateLocal,
    builder: (column) => column,
  );

  GeneratedColumn<String> get alertThresholdsJson => $composableBuilder(
    column: $table.alertThresholdsJson,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAtMs => $composableBuilder(
    column: $table.updatedAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get deletedAtMs => $composableBuilder(
    column: $table.deletedAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get lastModifiedDeviceId => $composableBuilder(
    column: $table.lastModifiedDeviceId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get legacyId =>
      $composableBuilder(column: $table.legacyId, builder: (column) => column);

  $$LedgersTableAnnotationComposer get ledgerId {
    final $$LedgersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.ledgerId,
      referencedTable: $db.ledgers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LedgersTableAnnotationComposer(
            $db: $db,
            $table: $db.ledgers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BudgetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BudgetsTable,
          Budget,
          $$BudgetsTableFilterComposer,
          $$BudgetsTableOrderingComposer,
          $$BudgetsTableAnnotationComposer,
          $$BudgetsTableCreateCompanionBuilder,
          $$BudgetsTableUpdateCompanionBuilder,
          (Budget, $$BudgetsTableReferences),
          Budget,
          PrefetchHooks Function({bool ledgerId, bool categoryId})
        > {
  $$BudgetsTableTableManager(_$AppDatabase db, $BudgetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BudgetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BudgetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BudgetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> ledgerId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> scopeType = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<String> yearMonth = const Value.absent(),
                Value<int> amountMinor = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                Value<String> timeZoneId = const Value.absent(),
                Value<String> periodType = const Value.absent(),
                Value<String> startDateLocal = const Value.absent(),
                Value<String> endDateLocal = const Value.absent(),
                Value<String?> alertThresholdsJson = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> createdAtMs = const Value.absent(),
                Value<int> updatedAtMs = const Value.absent(),
                Value<int?> deletedAtMs = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String?> lastModifiedDeviceId = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int?> legacyId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BudgetsCompanion(
                id: id,
                ledgerId: ledgerId,
                name: name,
                scopeType: scopeType,
                categoryId: categoryId,
                yearMonth: yearMonth,
                amountMinor: amountMinor,
                currencyCode: currencyCode,
                timeZoneId: timeZoneId,
                periodType: periodType,
                startDateLocal: startDateLocal,
                endDateLocal: endDateLocal,
                alertThresholdsJson: alertThresholdsJson,
                isActive: isActive,
                createdAtMs: createdAtMs,
                updatedAtMs: updatedAtMs,
                deletedAtMs: deletedAtMs,
                version: version,
                lastModifiedDeviceId: lastModifiedDeviceId,
                syncStatus: syncStatus,
                legacyId: legacyId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String ledgerId,
                required String name,
                required String scopeType,
                Value<String?> categoryId = const Value.absent(),
                required String yearMonth,
                required int amountMinor,
                required String currencyCode,
                required String timeZoneId,
                Value<String> periodType = const Value.absent(),
                required String startDateLocal,
                required String endDateLocal,
                Value<String?> alertThresholdsJson = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                required int createdAtMs,
                required int updatedAtMs,
                Value<int?> deletedAtMs = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String?> lastModifiedDeviceId = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int?> legacyId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BudgetsCompanion.insert(
                id: id,
                ledgerId: ledgerId,
                name: name,
                scopeType: scopeType,
                categoryId: categoryId,
                yearMonth: yearMonth,
                amountMinor: amountMinor,
                currencyCode: currencyCode,
                timeZoneId: timeZoneId,
                periodType: periodType,
                startDateLocal: startDateLocal,
                endDateLocal: endDateLocal,
                alertThresholdsJson: alertThresholdsJson,
                isActive: isActive,
                createdAtMs: createdAtMs,
                updatedAtMs: updatedAtMs,
                deletedAtMs: deletedAtMs,
                version: version,
                lastModifiedDeviceId: lastModifiedDeviceId,
                syncStatus: syncStatus,
                legacyId: legacyId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$BudgetsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({ledgerId = false, categoryId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (ledgerId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.ledgerId,
                                referencedTable: $$BudgetsTableReferences
                                    ._ledgerIdTable(db),
                                referencedColumn: $$BudgetsTableReferences
                                    ._ledgerIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (categoryId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.categoryId,
                                referencedTable: $$BudgetsTableReferences
                                    ._categoryIdTable(db),
                                referencedColumn: $$BudgetsTableReferences
                                    ._categoryIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$BudgetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BudgetsTable,
      Budget,
      $$BudgetsTableFilterComposer,
      $$BudgetsTableOrderingComposer,
      $$BudgetsTableAnnotationComposer,
      $$BudgetsTableCreateCompanionBuilder,
      $$BudgetsTableUpdateCompanionBuilder,
      (Budget, $$BudgetsTableReferences),
      Budget,
      PrefetchHooks Function({bool ledgerId, bool categoryId})
    >;
typedef $$AnalyticsEventQueueTableCreateCompanionBuilder =
    AnalyticsEventQueueCompanion Function({
      required String eventId,
      required String eventName,
      required String sessionId,
      required int occurredAtMs,
      Value<int> schemaVersion,
      Value<String?> userId,
      Value<String> identityScope,
      Value<String> propertiesJson,
      Value<int> attemptCount,
      Value<int?> nextRetryAtMs,
      required int createdAtMs,
      Value<int> rowid,
    });
typedef $$AnalyticsEventQueueTableUpdateCompanionBuilder =
    AnalyticsEventQueueCompanion Function({
      Value<String> eventId,
      Value<String> eventName,
      Value<String> sessionId,
      Value<int> occurredAtMs,
      Value<int> schemaVersion,
      Value<String?> userId,
      Value<String> identityScope,
      Value<String> propertiesJson,
      Value<int> attemptCount,
      Value<int?> nextRetryAtMs,
      Value<int> createdAtMs,
      Value<int> rowid,
    });

class $$AnalyticsEventQueueTableFilterComposer
    extends Composer<_$AppDatabase, $AnalyticsEventQueueTable> {
  $$AnalyticsEventQueueTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get eventId => $composableBuilder(
    column: $table.eventId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eventName => $composableBuilder(
    column: $table.eventName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get occurredAtMs => $composableBuilder(
    column: $table.occurredAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get identityScope => $composableBuilder(
    column: $table.identityScope,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get propertiesJson => $composableBuilder(
    column: $table.propertiesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get nextRetryAtMs => $composableBuilder(
    column: $table.nextRetryAtMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AnalyticsEventQueueTableOrderingComposer
    extends Composer<_$AppDatabase, $AnalyticsEventQueueTable> {
  $$AnalyticsEventQueueTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get eventId => $composableBuilder(
    column: $table.eventId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventName => $composableBuilder(
    column: $table.eventName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sessionId => $composableBuilder(
    column: $table.sessionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get occurredAtMs => $composableBuilder(
    column: $table.occurredAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get identityScope => $composableBuilder(
    column: $table.identityScope,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get propertiesJson => $composableBuilder(
    column: $table.propertiesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get nextRetryAtMs => $composableBuilder(
    column: $table.nextRetryAtMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AnalyticsEventQueueTableAnnotationComposer
    extends Composer<_$AppDatabase, $AnalyticsEventQueueTable> {
  $$AnalyticsEventQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get eventId =>
      $composableBuilder(column: $table.eventId, builder: (column) => column);

  GeneratedColumn<String> get eventName =>
      $composableBuilder(column: $table.eventName, builder: (column) => column);

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<int> get occurredAtMs => $composableBuilder(
    column: $table.occurredAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get identityScope => $composableBuilder(
    column: $table.identityScope,
    builder: (column) => column,
  );

  GeneratedColumn<String> get propertiesJson => $composableBuilder(
    column: $table.propertiesJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get nextRetryAtMs => $composableBuilder(
    column: $table.nextRetryAtMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAtMs => $composableBuilder(
    column: $table.createdAtMs,
    builder: (column) => column,
  );
}

class $$AnalyticsEventQueueTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AnalyticsEventQueueTable,
          AnalyticsEventQueueData,
          $$AnalyticsEventQueueTableFilterComposer,
          $$AnalyticsEventQueueTableOrderingComposer,
          $$AnalyticsEventQueueTableAnnotationComposer,
          $$AnalyticsEventQueueTableCreateCompanionBuilder,
          $$AnalyticsEventQueueTableUpdateCompanionBuilder,
          (
            AnalyticsEventQueueData,
            BaseReferences<
              _$AppDatabase,
              $AnalyticsEventQueueTable,
              AnalyticsEventQueueData
            >,
          ),
          AnalyticsEventQueueData,
          PrefetchHooks Function()
        > {
  $$AnalyticsEventQueueTableTableManager(
    _$AppDatabase db,
    $AnalyticsEventQueueTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AnalyticsEventQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AnalyticsEventQueueTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$AnalyticsEventQueueTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> eventId = const Value.absent(),
                Value<String> eventName = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<int> occurredAtMs = const Value.absent(),
                Value<int> schemaVersion = const Value.absent(),
                Value<String?> userId = const Value.absent(),
                Value<String> identityScope = const Value.absent(),
                Value<String> propertiesJson = const Value.absent(),
                Value<int> attemptCount = const Value.absent(),
                Value<int?> nextRetryAtMs = const Value.absent(),
                Value<int> createdAtMs = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AnalyticsEventQueueCompanion(
                eventId: eventId,
                eventName: eventName,
                sessionId: sessionId,
                occurredAtMs: occurredAtMs,
                schemaVersion: schemaVersion,
                userId: userId,
                identityScope: identityScope,
                propertiesJson: propertiesJson,
                attemptCount: attemptCount,
                nextRetryAtMs: nextRetryAtMs,
                createdAtMs: createdAtMs,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String eventId,
                required String eventName,
                required String sessionId,
                required int occurredAtMs,
                Value<int> schemaVersion = const Value.absent(),
                Value<String?> userId = const Value.absent(),
                Value<String> identityScope = const Value.absent(),
                Value<String> propertiesJson = const Value.absent(),
                Value<int> attemptCount = const Value.absent(),
                Value<int?> nextRetryAtMs = const Value.absent(),
                required int createdAtMs,
                Value<int> rowid = const Value.absent(),
              }) => AnalyticsEventQueueCompanion.insert(
                eventId: eventId,
                eventName: eventName,
                sessionId: sessionId,
                occurredAtMs: occurredAtMs,
                schemaVersion: schemaVersion,
                userId: userId,
                identityScope: identityScope,
                propertiesJson: propertiesJson,
                attemptCount: attemptCount,
                nextRetryAtMs: nextRetryAtMs,
                createdAtMs: createdAtMs,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AnalyticsEventQueueTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AnalyticsEventQueueTable,
      AnalyticsEventQueueData,
      $$AnalyticsEventQueueTableFilterComposer,
      $$AnalyticsEventQueueTableOrderingComposer,
      $$AnalyticsEventQueueTableAnnotationComposer,
      $$AnalyticsEventQueueTableCreateCompanionBuilder,
      $$AnalyticsEventQueueTableUpdateCompanionBuilder,
      (
        AnalyticsEventQueueData,
        BaseReferences<
          _$AppDatabase,
          $AnalyticsEventQueueTable,
          AnalyticsEventQueueData
        >,
      ),
      AnalyticsEventQueueData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LedgersTableTableManager get ledgers =>
      $$LedgersTableTableManager(_db, _db.ledgers);
  $$AccountsTableTableManager get accounts =>
      $$AccountsTableTableManager(_db, _db.accounts);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$LedgerTransactionsTableTableManager get ledgerTransactions =>
      $$LedgerTransactionsTableTableManager(_db, _db.ledgerTransactions);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$BudgetsTableTableManager get budgets =>
      $$BudgetsTableTableManager(_db, _db.budgets);
  $$AnalyticsEventQueueTableTableManager get analyticsEventQueue =>
      $$AnalyticsEventQueueTableTableManager(_db, _db.analyticsEventQueue);
}
