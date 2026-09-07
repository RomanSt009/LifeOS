// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lifeos_database.dart';

// ignore_for_file: type=lint
class $EntitiesTable extends Entities
    with TableInfo<$EntitiesTable, EntityRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EntitiesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lifecycleMeta = const VerificationMeta(
    'lifecycle',
  );
  @override
  late final GeneratedColumn<String> lifecycle = GeneratedColumn<String>(
    'lifecycle',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    entityType,
    createdAt,
    updatedAt,
    lifecycle,
    version,
    source,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'entities';
  @override
  VerificationContext validateIntegrity(
    Insertable<EntityRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('lifecycle')) {
      context.handle(
        _lifecycleMeta,
        lifecycle.isAcceptableOrUnknown(data['lifecycle']!, _lifecycleMeta),
      );
    } else if (isInserting) {
      context.missing(_lifecycleMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    } else if (isInserting) {
      context.missing(_versionMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EntityRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EntityRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      lifecycle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lifecycle'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
    );
  }

  @override
  $EntitiesTable createAlias(String alias) {
    return $EntitiesTable(attachedDatabase, alias);
  }
}

class EntityRecord extends DataClass implements Insertable<EntityRecord> {
  final String id;
  final String entityType;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String lifecycle;
  final int version;
  final String source;
  const EntityRecord({
    required this.id,
    required this.entityType,
    required this.createdAt,
    required this.updatedAt,
    required this.lifecycle,
    required this.version,
    required this.source,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['entity_type'] = Variable<String>(entityType);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['lifecycle'] = Variable<String>(lifecycle);
    map['version'] = Variable<int>(version);
    map['source'] = Variable<String>(source);
    return map;
  }

  EntitiesCompanion toCompanion(bool nullToAbsent) {
    return EntitiesCompanion(
      id: Value(id),
      entityType: Value(entityType),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      lifecycle: Value(lifecycle),
      version: Value(version),
      source: Value(source),
    );
  }

  factory EntityRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EntityRecord(
      id: serializer.fromJson<String>(json['id']),
      entityType: serializer.fromJson<String>(json['entityType']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      lifecycle: serializer.fromJson<String>(json['lifecycle']),
      version: serializer.fromJson<int>(json['version']),
      source: serializer.fromJson<String>(json['source']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'entityType': serializer.toJson<String>(entityType),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'lifecycle': serializer.toJson<String>(lifecycle),
      'version': serializer.toJson<int>(version),
      'source': serializer.toJson<String>(source),
    };
  }

  EntityRecord copyWith({
    String? id,
    String? entityType,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? lifecycle,
    int? version,
    String? source,
  }) => EntityRecord(
    id: id ?? this.id,
    entityType: entityType ?? this.entityType,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    lifecycle: lifecycle ?? this.lifecycle,
    version: version ?? this.version,
    source: source ?? this.source,
  );
  EntityRecord copyWithCompanion(EntitiesCompanion data) {
    return EntityRecord(
      id: data.id.present ? data.id.value : this.id,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      lifecycle: data.lifecycle.present ? data.lifecycle.value : this.lifecycle,
      version: data.version.present ? data.version.value : this.version,
      source: data.source.present ? data.source.value : this.source,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EntityRecord(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lifecycle: $lifecycle, ')
          ..write('version: $version, ')
          ..write('source: $source')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    entityType,
    createdAt,
    updatedAt,
    lifecycle,
    version,
    source,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EntityRecord &&
          other.id == this.id &&
          other.entityType == this.entityType &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.lifecycle == this.lifecycle &&
          other.version == this.version &&
          other.source == this.source);
}

class EntitiesCompanion extends UpdateCompanion<EntityRecord> {
  final Value<String> id;
  final Value<String> entityType;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> lifecycle;
  final Value<int> version;
  final Value<String> source;
  final Value<int> rowid;
  const EntitiesCompanion({
    this.id = const Value.absent(),
    this.entityType = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.lifecycle = const Value.absent(),
    this.version = const Value.absent(),
    this.source = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EntitiesCompanion.insert({
    required String id,
    required String entityType,
    required DateTime createdAt,
    required DateTime updatedAt,
    required String lifecycle,
    required int version,
    required String source,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       entityType = Value(entityType),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       lifecycle = Value(lifecycle),
       version = Value(version),
       source = Value(source);
  static Insertable<EntityRecord> custom({
    Expression<String>? id,
    Expression<String>? entityType,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? lifecycle,
    Expression<int>? version,
    Expression<String>? source,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entityType != null) 'entity_type': entityType,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (lifecycle != null) 'lifecycle': lifecycle,
      if (version != null) 'version': version,
      if (source != null) 'source': source,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EntitiesCompanion copyWith({
    Value<String>? id,
    Value<String>? entityType,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? lifecycle,
    Value<int>? version,
    Value<String>? source,
    Value<int>? rowid,
  }) {
    return EntitiesCompanion(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lifecycle: lifecycle ?? this.lifecycle,
      version: version ?? this.version,
      source: source ?? this.source,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (lifecycle.present) {
      map['lifecycle'] = Variable<String>(lifecycle.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EntitiesCompanion(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lifecycle: $lifecycle, ')
          ..write('version: $version, ')
          ..write('source: $source, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TaskRecordsTable extends TaskRecords
    with TableInfo<$TaskRecordsTable, TaskRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TaskRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES entities (id)',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isCompletedMeta = const VerificationMeta(
    'isCompleted',
  );
  @override
  late final GeneratedColumn<bool> isCompleted = GeneratedColumn<bool>(
    'is_completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_completed" IN (0, 1))',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [entityId, title, isCompleted];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<TaskRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('is_completed')) {
      context.handle(
        _isCompletedMeta,
        isCompleted.isAcceptableOrUnknown(
          data['is_completed']!,
          _isCompletedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_isCompletedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {entityId};
  @override
  TaskRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskRecord(
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      isCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_completed'],
      )!,
    );
  }

  @override
  $TaskRecordsTable createAlias(String alias) {
    return $TaskRecordsTable(attachedDatabase, alias);
  }
}

class TaskRecord extends DataClass implements Insertable<TaskRecord> {
  final String entityId;
  final String title;
  final bool isCompleted;
  const TaskRecord({
    required this.entityId,
    required this.title,
    required this.isCompleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['entity_id'] = Variable<String>(entityId);
    map['title'] = Variable<String>(title);
    map['is_completed'] = Variable<bool>(isCompleted);
    return map;
  }

  TaskRecordsCompanion toCompanion(bool nullToAbsent) {
    return TaskRecordsCompanion(
      entityId: Value(entityId),
      title: Value(title),
      isCompleted: Value(isCompleted),
    );
  }

  factory TaskRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskRecord(
      entityId: serializer.fromJson<String>(json['entityId']),
      title: serializer.fromJson<String>(json['title']),
      isCompleted: serializer.fromJson<bool>(json['isCompleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'entityId': serializer.toJson<String>(entityId),
      'title': serializer.toJson<String>(title),
      'isCompleted': serializer.toJson<bool>(isCompleted),
    };
  }

  TaskRecord copyWith({String? entityId, String? title, bool? isCompleted}) =>
      TaskRecord(
        entityId: entityId ?? this.entityId,
        title: title ?? this.title,
        isCompleted: isCompleted ?? this.isCompleted,
      );
  TaskRecord copyWithCompanion(TaskRecordsCompanion data) {
    return TaskRecord(
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      title: data.title.present ? data.title.value : this.title,
      isCompleted: data.isCompleted.present
          ? data.isCompleted.value
          : this.isCompleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskRecord(')
          ..write('entityId: $entityId, ')
          ..write('title: $title, ')
          ..write('isCompleted: $isCompleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(entityId, title, isCompleted);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskRecord &&
          other.entityId == this.entityId &&
          other.title == this.title &&
          other.isCompleted == this.isCompleted);
}

class TaskRecordsCompanion extends UpdateCompanion<TaskRecord> {
  final Value<String> entityId;
  final Value<String> title;
  final Value<bool> isCompleted;
  final Value<int> rowid;
  const TaskRecordsCompanion({
    this.entityId = const Value.absent(),
    this.title = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TaskRecordsCompanion.insert({
    required String entityId,
    required String title,
    required bool isCompleted,
    this.rowid = const Value.absent(),
  }) : entityId = Value(entityId),
       title = Value(title),
       isCompleted = Value(isCompleted);
  static Insertable<TaskRecord> custom({
    Expression<String>? entityId,
    Expression<String>? title,
    Expression<bool>? isCompleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (entityId != null) 'entity_id': entityId,
      if (title != null) 'title': title,
      if (isCompleted != null) 'is_completed': isCompleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TaskRecordsCompanion copyWith({
    Value<String>? entityId,
    Value<String>? title,
    Value<bool>? isCompleted,
    Value<int>? rowid,
  }) {
    return TaskRecordsCompanion(
      entityId: entityId ?? this.entityId,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<bool>(isCompleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TaskRecordsCompanion(')
          ..write('entityId: $entityId, ')
          ..write('title: $title, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OutboxEntriesTable extends OutboxEntries
    with TableInfo<$OutboxEntriesTable, OutboxEntryRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OutboxEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _changeIdMeta = const VerificationMeta(
    'changeId',
  );
  @override
  late final GeneratedColumn<String> changeId = GeneratedColumn<String>(
    'change_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES entities (id)',
    ),
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _operationMeta = const VerificationMeta(
    'operation',
  );
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
    'operation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _baseVersionMeta = const VerificationMeta(
    'baseVersion',
  );
  @override
  late final GeneratedColumn<int> baseVersion = GeneratedColumn<int>(
    'base_version',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _newVersionMeta = const VerificationMeta(
    'newVersion',
  );
  @override
  late final GeneratedColumn<int> newVersion = GeneratedColumn<int>(
    'new_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastAttemptAtMeta = const VerificationMeta(
    'lastAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastAttemptAt =
      GeneratedColumn<DateTime>(
        'last_attempt_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    changeId,
    entityId,
    deviceId,
    operation,
    baseVersion,
    newVersion,
    payload,
    schemaVersion,
    status,
    attemptCount,
    createdAt,
    lastAttemptAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'outbox';
  @override
  VerificationContext validateIntegrity(
    Insertable<OutboxEntryRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('change_id')) {
      context.handle(
        _changeIdMeta,
        changeId.isAcceptableOrUnknown(data['change_id']!, _changeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_changeIdMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('operation')) {
      context.handle(
        _operationMeta,
        operation.isAcceptableOrUnknown(data['operation']!, _operationMeta),
      );
    } else if (isInserting) {
      context.missing(_operationMeta);
    }
    if (data.containsKey('base_version')) {
      context.handle(
        _baseVersionMeta,
        baseVersion.isAcceptableOrUnknown(
          data['base_version']!,
          _baseVersionMeta,
        ),
      );
    }
    if (data.containsKey('new_version')) {
      context.handle(
        _newVersionMeta,
        newVersion.isAcceptableOrUnknown(data['new_version']!, _newVersionMeta),
      );
    } else if (isInserting) {
      context.missing(_newVersionMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('schema_version')) {
      context.handle(
        _schemaVersionMeta,
        schemaVersion.isAcceptableOrUnknown(
          data['schema_version']!,
          _schemaVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_schemaVersionMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('attempt_count')) {
      context.handle(
        _attemptCountMeta,
        attemptCount.isAcceptableOrUnknown(
          data['attempt_count']!,
          _attemptCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_attemptCountMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('last_attempt_at')) {
      context.handle(
        _lastAttemptAtMeta,
        lastAttemptAt.isAcceptableOrUnknown(
          data['last_attempt_at']!,
          _lastAttemptAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {changeId};
  @override
  OutboxEntryRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OutboxEntryRecord(
      changeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}change_id'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      operation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation'],
      )!,
      baseVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}base_version'],
      ),
      newVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}new_version'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      schemaVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}schema_version'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      attemptCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempt_count'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      lastAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_attempt_at'],
      ),
    );
  }

  @override
  $OutboxEntriesTable createAlias(String alias) {
    return $OutboxEntriesTable(attachedDatabase, alias);
  }
}

class OutboxEntryRecord extends DataClass
    implements Insertable<OutboxEntryRecord> {
  final String changeId;
  final String entityId;
  final String deviceId;
  final String operation;
  final int? baseVersion;
  final int newVersion;
  final String payload;
  final int schemaVersion;
  final String status;
  final int attemptCount;
  final DateTime createdAt;
  final DateTime? lastAttemptAt;
  const OutboxEntryRecord({
    required this.changeId,
    required this.entityId,
    required this.deviceId,
    required this.operation,
    this.baseVersion,
    required this.newVersion,
    required this.payload,
    required this.schemaVersion,
    required this.status,
    required this.attemptCount,
    required this.createdAt,
    this.lastAttemptAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['change_id'] = Variable<String>(changeId);
    map['entity_id'] = Variable<String>(entityId);
    map['device_id'] = Variable<String>(deviceId);
    map['operation'] = Variable<String>(operation);
    if (!nullToAbsent || baseVersion != null) {
      map['base_version'] = Variable<int>(baseVersion);
    }
    map['new_version'] = Variable<int>(newVersion);
    map['payload'] = Variable<String>(payload);
    map['schema_version'] = Variable<int>(schemaVersion);
    map['status'] = Variable<String>(status);
    map['attempt_count'] = Variable<int>(attemptCount);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || lastAttemptAt != null) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt);
    }
    return map;
  }

  OutboxEntriesCompanion toCompanion(bool nullToAbsent) {
    return OutboxEntriesCompanion(
      changeId: Value(changeId),
      entityId: Value(entityId),
      deviceId: Value(deviceId),
      operation: Value(operation),
      baseVersion: baseVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(baseVersion),
      newVersion: Value(newVersion),
      payload: Value(payload),
      schemaVersion: Value(schemaVersion),
      status: Value(status),
      attemptCount: Value(attemptCount),
      createdAt: Value(createdAt),
      lastAttemptAt: lastAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAttemptAt),
    );
  }

  factory OutboxEntryRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OutboxEntryRecord(
      changeId: serializer.fromJson<String>(json['changeId']),
      entityId: serializer.fromJson<String>(json['entityId']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      operation: serializer.fromJson<String>(json['operation']),
      baseVersion: serializer.fromJson<int?>(json['baseVersion']),
      newVersion: serializer.fromJson<int>(json['newVersion']),
      payload: serializer.fromJson<String>(json['payload']),
      schemaVersion: serializer.fromJson<int>(json['schemaVersion']),
      status: serializer.fromJson<String>(json['status']),
      attemptCount: serializer.fromJson<int>(json['attemptCount']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastAttemptAt: serializer.fromJson<DateTime?>(json['lastAttemptAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'changeId': serializer.toJson<String>(changeId),
      'entityId': serializer.toJson<String>(entityId),
      'deviceId': serializer.toJson<String>(deviceId),
      'operation': serializer.toJson<String>(operation),
      'baseVersion': serializer.toJson<int?>(baseVersion),
      'newVersion': serializer.toJson<int>(newVersion),
      'payload': serializer.toJson<String>(payload),
      'schemaVersion': serializer.toJson<int>(schemaVersion),
      'status': serializer.toJson<String>(status),
      'attemptCount': serializer.toJson<int>(attemptCount),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastAttemptAt': serializer.toJson<DateTime?>(lastAttemptAt),
    };
  }

  OutboxEntryRecord copyWith({
    String? changeId,
    String? entityId,
    String? deviceId,
    String? operation,
    Value<int?> baseVersion = const Value.absent(),
    int? newVersion,
    String? payload,
    int? schemaVersion,
    String? status,
    int? attemptCount,
    DateTime? createdAt,
    Value<DateTime?> lastAttemptAt = const Value.absent(),
  }) => OutboxEntryRecord(
    changeId: changeId ?? this.changeId,
    entityId: entityId ?? this.entityId,
    deviceId: deviceId ?? this.deviceId,
    operation: operation ?? this.operation,
    baseVersion: baseVersion.present ? baseVersion.value : this.baseVersion,
    newVersion: newVersion ?? this.newVersion,
    payload: payload ?? this.payload,
    schemaVersion: schemaVersion ?? this.schemaVersion,
    status: status ?? this.status,
    attemptCount: attemptCount ?? this.attemptCount,
    createdAt: createdAt ?? this.createdAt,
    lastAttemptAt: lastAttemptAt.present
        ? lastAttemptAt.value
        : this.lastAttemptAt,
  );
  OutboxEntryRecord copyWithCompanion(OutboxEntriesCompanion data) {
    return OutboxEntryRecord(
      changeId: data.changeId.present ? data.changeId.value : this.changeId,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      operation: data.operation.present ? data.operation.value : this.operation,
      baseVersion: data.baseVersion.present
          ? data.baseVersion.value
          : this.baseVersion,
      newVersion: data.newVersion.present
          ? data.newVersion.value
          : this.newVersion,
      payload: data.payload.present ? data.payload.value : this.payload,
      schemaVersion: data.schemaVersion.present
          ? data.schemaVersion.value
          : this.schemaVersion,
      status: data.status.present ? data.status.value : this.status,
      attemptCount: data.attemptCount.present
          ? data.attemptCount.value
          : this.attemptCount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastAttemptAt: data.lastAttemptAt.present
          ? data.lastAttemptAt.value
          : this.lastAttemptAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OutboxEntryRecord(')
          ..write('changeId: $changeId, ')
          ..write('entityId: $entityId, ')
          ..write('deviceId: $deviceId, ')
          ..write('operation: $operation, ')
          ..write('baseVersion: $baseVersion, ')
          ..write('newVersion: $newVersion, ')
          ..write('payload: $payload, ')
          ..write('schemaVersion: $schemaVersion, ')
          ..write('status: $status, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastAttemptAt: $lastAttemptAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    changeId,
    entityId,
    deviceId,
    operation,
    baseVersion,
    newVersion,
    payload,
    schemaVersion,
    status,
    attemptCount,
    createdAt,
    lastAttemptAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OutboxEntryRecord &&
          other.changeId == this.changeId &&
          other.entityId == this.entityId &&
          other.deviceId == this.deviceId &&
          other.operation == this.operation &&
          other.baseVersion == this.baseVersion &&
          other.newVersion == this.newVersion &&
          other.payload == this.payload &&
          other.schemaVersion == this.schemaVersion &&
          other.status == this.status &&
          other.attemptCount == this.attemptCount &&
          other.createdAt == this.createdAt &&
          other.lastAttemptAt == this.lastAttemptAt);
}

class OutboxEntriesCompanion extends UpdateCompanion<OutboxEntryRecord> {
  final Value<String> changeId;
  final Value<String> entityId;
  final Value<String> deviceId;
  final Value<String> operation;
  final Value<int?> baseVersion;
  final Value<int> newVersion;
  final Value<String> payload;
  final Value<int> schemaVersion;
  final Value<String> status;
  final Value<int> attemptCount;
  final Value<DateTime> createdAt;
  final Value<DateTime?> lastAttemptAt;
  final Value<int> rowid;
  const OutboxEntriesCompanion({
    this.changeId = const Value.absent(),
    this.entityId = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.operation = const Value.absent(),
    this.baseVersion = const Value.absent(),
    this.newVersion = const Value.absent(),
    this.payload = const Value.absent(),
    this.schemaVersion = const Value.absent(),
    this.status = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OutboxEntriesCompanion.insert({
    required String changeId,
    required String entityId,
    required String deviceId,
    required String operation,
    this.baseVersion = const Value.absent(),
    required int newVersion,
    required String payload,
    required int schemaVersion,
    required String status,
    required int attemptCount,
    required DateTime createdAt,
    this.lastAttemptAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : changeId = Value(changeId),
       entityId = Value(entityId),
       deviceId = Value(deviceId),
       operation = Value(operation),
       newVersion = Value(newVersion),
       payload = Value(payload),
       schemaVersion = Value(schemaVersion),
       status = Value(status),
       attemptCount = Value(attemptCount),
       createdAt = Value(createdAt);
  static Insertable<OutboxEntryRecord> custom({
    Expression<String>? changeId,
    Expression<String>? entityId,
    Expression<String>? deviceId,
    Expression<String>? operation,
    Expression<int>? baseVersion,
    Expression<int>? newVersion,
    Expression<String>? payload,
    Expression<int>? schemaVersion,
    Expression<String>? status,
    Expression<int>? attemptCount,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastAttemptAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (changeId != null) 'change_id': changeId,
      if (entityId != null) 'entity_id': entityId,
      if (deviceId != null) 'device_id': deviceId,
      if (operation != null) 'operation': operation,
      if (baseVersion != null) 'base_version': baseVersion,
      if (newVersion != null) 'new_version': newVersion,
      if (payload != null) 'payload': payload,
      if (schemaVersion != null) 'schema_version': schemaVersion,
      if (status != null) 'status': status,
      if (attemptCount != null) 'attempt_count': attemptCount,
      if (createdAt != null) 'created_at': createdAt,
      if (lastAttemptAt != null) 'last_attempt_at': lastAttemptAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OutboxEntriesCompanion copyWith({
    Value<String>? changeId,
    Value<String>? entityId,
    Value<String>? deviceId,
    Value<String>? operation,
    Value<int?>? baseVersion,
    Value<int>? newVersion,
    Value<String>? payload,
    Value<int>? schemaVersion,
    Value<String>? status,
    Value<int>? attemptCount,
    Value<DateTime>? createdAt,
    Value<DateTime?>? lastAttemptAt,
    Value<int>? rowid,
  }) {
    return OutboxEntriesCompanion(
      changeId: changeId ?? this.changeId,
      entityId: entityId ?? this.entityId,
      deviceId: deviceId ?? this.deviceId,
      operation: operation ?? this.operation,
      baseVersion: baseVersion ?? this.baseVersion,
      newVersion: newVersion ?? this.newVersion,
      payload: payload ?? this.payload,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      status: status ?? this.status,
      attemptCount: attemptCount ?? this.attemptCount,
      createdAt: createdAt ?? this.createdAt,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (changeId.present) {
      map['change_id'] = Variable<String>(changeId.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (baseVersion.present) {
      map['base_version'] = Variable<int>(baseVersion.value);
    }
    if (newVersion.present) {
      map['new_version'] = Variable<int>(newVersion.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (schemaVersion.present) {
      map['schema_version'] = Variable<int>(schemaVersion.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (attemptCount.present) {
      map['attempt_count'] = Variable<int>(attemptCount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastAttemptAt.present) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OutboxEntriesCompanion(')
          ..write('changeId: $changeId, ')
          ..write('entityId: $entityId, ')
          ..write('deviceId: $deviceId, ')
          ..write('operation: $operation, ')
          ..write('baseVersion: $baseVersion, ')
          ..write('newVersion: $newVersion, ')
          ..write('payload: $payload, ')
          ..write('schemaVersion: $schemaVersion, ')
          ..write('status: $status, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$LifeOsDatabase extends GeneratedDatabase {
  _$LifeOsDatabase(QueryExecutor e) : super(e);
  $LifeOsDatabaseManager get managers => $LifeOsDatabaseManager(this);
  late final $EntitiesTable entities = $EntitiesTable(this);
  late final $TaskRecordsTable taskRecords = $TaskRecordsTable(this);
  late final $OutboxEntriesTable outboxEntries = $OutboxEntriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    entities,
    taskRecords,
    outboxEntries,
  ];
}

typedef $$EntitiesTableCreateCompanionBuilder = EntitiesCompanion Function({
  required String id,
  required String entityType,
  required DateTime createdAt,
  required DateTime updatedAt,
  required String lifecycle,
  required int version,
  required String source,
  Value<int> rowid,
});
typedef $$EntitiesTableUpdateCompanionBuilder = EntitiesCompanion Function({
  Value<String> id,
  Value<String> entityType,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<String> lifecycle,
  Value<int> version,
  Value<String> source,
  Value<int> rowid,
});

final class $$EntitiesTableReferences
    extends BaseReferences<_$LifeOsDatabase, $EntitiesTable, EntityRecord> {
  $$EntitiesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TaskRecordsTable, List<TaskRecord>>
  _taskRecordsRefsTable(_$LifeOsDatabase db) => MultiTypedResultKey.fromTable(
    db.taskRecords,
    aliasName: 'entities__id__tasks__entity_id',
  );

  $$TaskRecordsTableProcessedTableManager get taskRecordsRefs {
    final manager = $$TaskRecordsTableTableManager(
      $_db,
      $_db.taskRecords,
    ).filter((f) => f.entityId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_taskRecordsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$OutboxEntriesTable, List<OutboxEntryRecord>>
  _outboxEntriesRefsTable(_$LifeOsDatabase db) => MultiTypedResultKey.fromTable(
    db.outboxEntries,
    aliasName: 'entities__id__outbox__entity_id',
  );

  $$OutboxEntriesTableProcessedTableManager get outboxEntriesRefs {
    final manager = $$OutboxEntriesTableTableManager(
      $_db,
      $_db.outboxEntries,
    ).filter((f) => f.entityId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_outboxEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$EntitiesTableFilterComposer
    extends Composer<_$LifeOsDatabase, $EntitiesTable> {
  $$EntitiesTableFilterComposer({
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

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lifecycle => $composableBuilder(
    column: $table.lifecycle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> taskRecordsRefs(
    Expression<bool> Function($$TaskRecordsTableFilterComposer f) f,
  ) {
    final $$TaskRecordsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.taskRecords,
      getReferencedColumn: (t) => t.entityId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskRecordsTableFilterComposer(
            $db: $db,
            $table: $db.taskRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> outboxEntriesRefs(
    Expression<bool> Function($$OutboxEntriesTableFilterComposer f) f,
  ) {
    final $$OutboxEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.outboxEntries,
      getReferencedColumn: (t) => t.entityId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OutboxEntriesTableFilterComposer(
            $db: $db,
            $table: $db.outboxEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$EntitiesTableOrderingComposer
    extends Composer<_$LifeOsDatabase, $EntitiesTable> {
  $$EntitiesTableOrderingComposer({
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

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lifecycle => $composableBuilder(
    column: $table.lifecycle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EntitiesTableAnnotationComposer
    extends Composer<_$LifeOsDatabase, $EntitiesTable> {
  $$EntitiesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get lifecycle =>
      $composableBuilder(column: $table.lifecycle, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  Expression<T> taskRecordsRefs<T extends Object>(
    Expression<T> Function($$TaskRecordsTableAnnotationComposer a) f,
  ) {
    final $$TaskRecordsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.taskRecords,
      getReferencedColumn: (t) => t.entityId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TaskRecordsTableAnnotationComposer(
            $db: $db,
            $table: $db.taskRecords,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> outboxEntriesRefs<T extends Object>(
    Expression<T> Function($$OutboxEntriesTableAnnotationComposer a) f,
  ) {
    final $$OutboxEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.outboxEntries,
      getReferencedColumn: (t) => t.entityId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OutboxEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.outboxEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$EntitiesTableTableManager
    extends
        RootTableManager<
          _$LifeOsDatabase,
          $EntitiesTable,
          EntityRecord,
          $$EntitiesTableFilterComposer,
          $$EntitiesTableOrderingComposer,
          $$EntitiesTableAnnotationComposer,
          $$EntitiesTableCreateCompanionBuilder,
          $$EntitiesTableUpdateCompanionBuilder,
          (EntityRecord, $$EntitiesTableReferences),
          EntityRecord,
          PrefetchHooks Function({bool taskRecordsRefs, bool outboxEntriesRefs})
        > {
  $$EntitiesTableTableManager(_$LifeOsDatabase db, $EntitiesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EntitiesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EntitiesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EntitiesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> lifecycle = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EntitiesCompanion(
                id: id,
                entityType: entityType,
                createdAt: createdAt,
                updatedAt: updatedAt,
                lifecycle: lifecycle,
                version: version,
                source: source,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String entityType,
                required DateTime createdAt,
                required DateTime updatedAt,
                required String lifecycle,
                required int version,
                required String source,
                Value<int> rowid = const Value.absent(),
              }) => EntitiesCompanion.insert(
                id: id,
                entityType: entityType,
                createdAt: createdAt,
                updatedAt: updatedAt,
                lifecycle: lifecycle,
                version: version,
                source: source,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EntitiesTable, EntityRecord>(table),
                  $$EntitiesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({taskRecordsRefs = false, outboxEntriesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (taskRecordsRefs) db.taskRecords,
                    if (outboxEntriesRefs) db.outboxEntries,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (taskRecordsRefs)
                        await $_getPrefetchedData<
                          EntityRecord,
                          $EntitiesTable,
                          TaskRecord
                        >(
                          currentTable: table,
                          referencedTable: $$EntitiesTableReferences
                              ._taskRecordsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EntitiesTableReferences(
                                db,
                                table,
                                p0,
                              ).taskRecordsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.entityId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (outboxEntriesRefs)
                        await $_getPrefetchedData<
                          EntityRecord,
                          $EntitiesTable,
                          OutboxEntryRecord
                        >(
                          currentTable: table,
                          referencedTable: $$EntitiesTableReferences
                              ._outboxEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EntitiesTableReferences(
                                db,
                                table,
                                p0,
                              ).outboxEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.entityId == item.id,
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

typedef $$EntitiesTableProcessedTableManager =
    ProcessedTableManager<
      _$LifeOsDatabase,
      $EntitiesTable,
      EntityRecord,
      $$EntitiesTableFilterComposer,
      $$EntitiesTableOrderingComposer,
      $$EntitiesTableAnnotationComposer,
      $$EntitiesTableCreateCompanionBuilder,
      $$EntitiesTableUpdateCompanionBuilder,
      (EntityRecord, $$EntitiesTableReferences),
      EntityRecord,
      PrefetchHooks Function({bool taskRecordsRefs, bool outboxEntriesRefs})
    >;
typedef $$TaskRecordsTableCreateCompanionBuilder =
    TaskRecordsCompanion Function({
      required String entityId,
      required String title,
      required bool isCompleted,
      Value<int> rowid,
    });
typedef $$TaskRecordsTableUpdateCompanionBuilder =
    TaskRecordsCompanion Function({
      Value<String> entityId,
      Value<String> title,
      Value<bool> isCompleted,
      Value<int> rowid,
    });

final class $$TaskRecordsTableReferences
    extends BaseReferences<_$LifeOsDatabase, $TaskRecordsTable, TaskRecord> {
  $$TaskRecordsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $EntitiesTable _entityIdTable(_$LifeOsDatabase db) =>
      db.entities.createAlias('tasks__entity_id__entities__id');

  $$EntitiesTableProcessedTableManager get entityId {
    final $_column = $_itemColumn<String>('entity_id')!;

    final manager = $$EntitiesTableTableManager(
      $_db,
      $_db.entities,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_entityIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TaskRecordsTableFilterComposer
    extends Composer<_$LifeOsDatabase, $TaskRecordsTable> {
  $$TaskRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnFilters(column),
  );

  $$EntitiesTableFilterComposer get entityId {
    final $$EntitiesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entityId,
      referencedTable: $db.entities,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntitiesTableFilterComposer(
            $db: $db,
            $table: $db.entities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskRecordsTableOrderingComposer
    extends Composer<_$LifeOsDatabase, $TaskRecordsTable> {
  $$TaskRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  $$EntitiesTableOrderingComposer get entityId {
    final $$EntitiesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entityId,
      referencedTable: $db.entities,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntitiesTableOrderingComposer(
            $db: $db,
            $table: $db.entities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskRecordsTableAnnotationComposer
    extends Composer<_$LifeOsDatabase, $TaskRecordsTable> {
  $$TaskRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => column,
  );

  $$EntitiesTableAnnotationComposer get entityId {
    final $$EntitiesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entityId,
      referencedTable: $db.entities,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntitiesTableAnnotationComposer(
            $db: $db,
            $table: $db.entities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TaskRecordsTableTableManager
    extends
        RootTableManager<
          _$LifeOsDatabase,
          $TaskRecordsTable,
          TaskRecord,
          $$TaskRecordsTableFilterComposer,
          $$TaskRecordsTableOrderingComposer,
          $$TaskRecordsTableAnnotationComposer,
          $$TaskRecordsTableCreateCompanionBuilder,
          $$TaskRecordsTableUpdateCompanionBuilder,
          (TaskRecord, $$TaskRecordsTableReferences),
          TaskRecord,
          PrefetchHooks Function({bool entityId})
        > {
  $$TaskRecordsTableTableManager(_$LifeOsDatabase db, $TaskRecordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TaskRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TaskRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TaskRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> entityId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TaskRecordsCompanion(
                entityId: entityId,
                title: title,
                isCompleted: isCompleted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String entityId,
                required String title,
                required bool isCompleted,
                Value<int> rowid = const Value.absent(),
              }) => TaskRecordsCompanion.insert(
                entityId: entityId,
                title: title,
                isCompleted: isCompleted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TaskRecordsTable, TaskRecord>(table),
                  $$TaskRecordsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({entityId = false}) {
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
                    if (entityId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.entityId,
                        referencedTable: $$TaskRecordsTableReferences
                            ._entityIdTable(db),
                        referencedColumn: $$TaskRecordsTableReferences
                            ._entityIdTable(db)
                            .id,
                      ) as T;
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

typedef $$TaskRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$LifeOsDatabase,
      $TaskRecordsTable,
      TaskRecord,
      $$TaskRecordsTableFilterComposer,
      $$TaskRecordsTableOrderingComposer,
      $$TaskRecordsTableAnnotationComposer,
      $$TaskRecordsTableCreateCompanionBuilder,
      $$TaskRecordsTableUpdateCompanionBuilder,
      (TaskRecord, $$TaskRecordsTableReferences),
      TaskRecord,
      PrefetchHooks Function({bool entityId})
    >;
typedef $$OutboxEntriesTableCreateCompanionBuilder =
    OutboxEntriesCompanion Function({
      required String changeId,
      required String entityId,
      required String deviceId,
      required String operation,
      Value<int?> baseVersion,
      required int newVersion,
      required String payload,
      required int schemaVersion,
      required String status,
      required int attemptCount,
      required DateTime createdAt,
      Value<DateTime?> lastAttemptAt,
      Value<int> rowid,
    });
typedef $$OutboxEntriesTableUpdateCompanionBuilder =
    OutboxEntriesCompanion Function({
      Value<String> changeId,
      Value<String> entityId,
      Value<String> deviceId,
      Value<String> operation,
      Value<int?> baseVersion,
      Value<int> newVersion,
      Value<String> payload,
      Value<int> schemaVersion,
      Value<String> status,
      Value<int> attemptCount,
      Value<DateTime> createdAt,
      Value<DateTime?> lastAttemptAt,
      Value<int> rowid,
    });

final class $$OutboxEntriesTableReferences
    extends
        BaseReferences<
          _$LifeOsDatabase,
          $OutboxEntriesTable,
          OutboxEntryRecord
        > {
  $$OutboxEntriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $EntitiesTable _entityIdTable(_$LifeOsDatabase db) =>
      db.entities.createAlias('outbox__entity_id__entities__id');

  $$EntitiesTableProcessedTableManager get entityId {
    final $_column = $_itemColumn<String>('entity_id')!;

    final manager = $$EntitiesTableTableManager(
      $_db,
      $_db.entities,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_entityIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$OutboxEntriesTableFilterComposer
    extends Composer<_$LifeOsDatabase, $OutboxEntriesTable> {
  $$OutboxEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get changeId => $composableBuilder(
    column: $table.changeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get baseVersion => $composableBuilder(
    column: $table.baseVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get newVersion => $composableBuilder(
    column: $table.newVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  $$EntitiesTableFilterComposer get entityId {
    final $$EntitiesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entityId,
      referencedTable: $db.entities,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntitiesTableFilterComposer(
            $db: $db,
            $table: $db.entities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OutboxEntriesTableOrderingComposer
    extends Composer<_$LifeOsDatabase, $OutboxEntriesTable> {
  $$OutboxEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get changeId => $composableBuilder(
    column: $table.changeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operation => $composableBuilder(
    column: $table.operation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get baseVersion => $composableBuilder(
    column: $table.baseVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get newVersion => $composableBuilder(
    column: $table.newVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$EntitiesTableOrderingComposer get entityId {
    final $$EntitiesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entityId,
      referencedTable: $db.entities,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntitiesTableOrderingComposer(
            $db: $db,
            $table: $db.entities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OutboxEntriesTableAnnotationComposer
    extends Composer<_$LifeOsDatabase, $OutboxEntriesTable> {
  $$OutboxEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get changeId =>
      $composableBuilder(column: $table.changeId, builder: (column) => column);

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<int> get baseVersion => $composableBuilder(
    column: $table.baseVersion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get newVersion => $composableBuilder(
    column: $table.newVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => column,
  );

  $$EntitiesTableAnnotationComposer get entityId {
    final $$EntitiesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.entityId,
      referencedTable: $db.entities,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EntitiesTableAnnotationComposer(
            $db: $db,
            $table: $db.entities,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OutboxEntriesTableTableManager
    extends
        RootTableManager<
          _$LifeOsDatabase,
          $OutboxEntriesTable,
          OutboxEntryRecord,
          $$OutboxEntriesTableFilterComposer,
          $$OutboxEntriesTableOrderingComposer,
          $$OutboxEntriesTableAnnotationComposer,
          $$OutboxEntriesTableCreateCompanionBuilder,
          $$OutboxEntriesTableUpdateCompanionBuilder,
          (OutboxEntryRecord, $$OutboxEntriesTableReferences),
          OutboxEntryRecord,
          PrefetchHooks Function({bool entityId})
        > {
  $$OutboxEntriesTableTableManager(
    _$LifeOsDatabase db,
    $OutboxEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OutboxEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OutboxEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OutboxEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> changeId = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<String> operation = const Value.absent(),
                Value<int?> baseVersion = const Value.absent(),
                Value<int> newVersion = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<int> schemaVersion = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> attemptCount = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> lastAttemptAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OutboxEntriesCompanion(
                changeId: changeId,
                entityId: entityId,
                deviceId: deviceId,
                operation: operation,
                baseVersion: baseVersion,
                newVersion: newVersion,
                payload: payload,
                schemaVersion: schemaVersion,
                status: status,
                attemptCount: attemptCount,
                createdAt: createdAt,
                lastAttemptAt: lastAttemptAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String changeId,
                required String entityId,
                required String deviceId,
                required String operation,
                Value<int?> baseVersion = const Value.absent(),
                required int newVersion,
                required String payload,
                required int schemaVersion,
                required String status,
                required int attemptCount,
                required DateTime createdAt,
                Value<DateTime?> lastAttemptAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OutboxEntriesCompanion.insert(
                changeId: changeId,
                entityId: entityId,
                deviceId: deviceId,
                operation: operation,
                baseVersion: baseVersion,
                newVersion: newVersion,
                payload: payload,
                schemaVersion: schemaVersion,
                status: status,
                attemptCount: attemptCount,
                createdAt: createdAt,
                lastAttemptAt: lastAttemptAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OutboxEntriesTable, OutboxEntryRecord>(table),
                  $$OutboxEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({entityId = false}) {
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
                    if (entityId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.entityId,
                        referencedTable: $$OutboxEntriesTableReferences
                            ._entityIdTable(db),
                        referencedColumn: $$OutboxEntriesTableReferences
                            ._entityIdTable(db)
                            .id,
                      ) as T;
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

typedef $$OutboxEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$LifeOsDatabase,
      $OutboxEntriesTable,
      OutboxEntryRecord,
      $$OutboxEntriesTableFilterComposer,
      $$OutboxEntriesTableOrderingComposer,
      $$OutboxEntriesTableAnnotationComposer,
      $$OutboxEntriesTableCreateCompanionBuilder,
      $$OutboxEntriesTableUpdateCompanionBuilder,
      (OutboxEntryRecord, $$OutboxEntriesTableReferences),
      OutboxEntryRecord,
      PrefetchHooks Function({bool entityId})
    >;

class $LifeOsDatabaseManager {
  final _$LifeOsDatabase _db;
  $LifeOsDatabaseManager(this._db);
  $$EntitiesTableTableManager get entities =>
      $$EntitiesTableTableManager(_db, _db.entities);
  $$TaskRecordsTableTableManager get taskRecords =>
      $$TaskRecordsTableTableManager(_db, _db.taskRecords);
  $$OutboxEntriesTableTableManager get outboxEntries =>
      $$OutboxEntriesTableTableManager(_db, _db.outboxEntries);
}
