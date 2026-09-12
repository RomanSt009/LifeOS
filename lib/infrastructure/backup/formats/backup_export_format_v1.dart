import 'dart:convert';

import '../../../domain/entities/lifeos_entity.dart';
import '../../../domain/entities/lifeos_task.dart';

const lifeOsApplicationId = 'lifeos';
const lifeOsBackupFormatKind = 'lifeos-backup';
const lifeOsExportFormatKind = 'lifeos-export';
const lifeOsBackupFormatVersion = 1;
const lifeOsExportFormatVersion = 1;
const lifeOsBackupManifestFileName = 'manifest.json';
const lifeOsBackupDataFileName = 'data.json';

enum LifeOsDataFormatErrorCode {
  malformedJson,
  missingField,
  invalidField,
  unsupportedVersion,
  duplicateEntityId,
}

class LifeOsDataFormatException implements Exception {
  const LifeOsDataFormatException({required this.code, required this.message});

  final LifeOsDataFormatErrorCode code;
  final String message;

  @override
  String toString() => 'LifeOsDataFormatException($code): $message';
}

class BackupManifestV1 {
  BackupManifestV1({
    required this.createdAt,
    required this.applicationVersion,
    required this.sourceDatabaseSchemaVersion,
    required Iterable<String> requiredSections,
    required this.dataSha256,
    this.applicationId = lifeOsApplicationId,
    this.formatVersion = lifeOsBackupFormatVersion,
  }) : requiredSections = List.unmodifiable(requiredSections) {
    _validateBackupManifest(this);
  }

  final int formatVersion;
  final DateTime createdAt;
  final String applicationId;
  final String applicationVersion;
  final int sourceDatabaseSchemaVersion;
  final List<String> requiredSections;
  final String dataSha256;

  Map<String, Object> toJson() => {
    'format': lifeOsBackupFormatKind,
    'formatVersion': formatVersion,
    'createdAt': _writeUtcTimestamp(createdAt, 'createdAt'),
    'applicationId': applicationId,
    'applicationVersion': applicationVersion,
    'sourceDatabaseSchemaVersion': sourceDatabaseSchemaVersion,
    'requiredSections': requiredSections,
    'dataSha256': dataSha256,
  };
}

class BackupSnapshotV1 {
  BackupSnapshotV1({required Iterable<BackupTaskRecordV1> tasks})
    : tasks = _validatedSortedTasks(tasks);

  final List<BackupTaskRecordV1> tasks;

  Map<String, Object> toJson() => {
    'tasks': tasks.map((task) => task.toJson()).toList(growable: false),
  };
}

class BackupTaskRecordV1 {
  BackupTaskRecordV1({
    required this.id,
    required this.entityType,
    required this.createdAt,
    required this.updatedAt,
    required this.lifecycle,
    required this.version,
    required this.source,
    required this.title,
    required this.isCompleted,
  }) {
    _validateTask(this);
  }

  factory BackupTaskRecordV1.fromDomain(LifeOsTask task) {
    return BackupTaskRecordV1(
      id: task.id.value,
      entityType: task.entityType,
      createdAt: task.createdAt,
      updatedAt: task.updatedAt,
      lifecycle: task.lifecycle,
      version: task.version,
      source: task.source,
      title: task.title,
      isCompleted: task.isCompleted,
    );
  }

  final String id;
  final LifeOsEntityType entityType;
  final DateTime createdAt;
  final DateTime updatedAt;
  final LifeOsEntityLifecycle lifecycle;
  final int version;
  final LifeOsEntitySource source;
  final String title;
  final bool isCompleted;

  LifeOsTask toDomain() => LifeOsTask(
    id: LifeOsEntityId(value: id, entityType: entityType),
    title: title,
    isCompleted: isCompleted,
    createdAt: createdAt,
    updatedAt: updatedAt,
    lifecycle: lifecycle,
    version: version,
    source: source,
  );

  Map<String, Object> toJson() => {
    'id': id,
    'entityType': _writeEntityType(entityType),
    'createdAt': _writeUtcTimestamp(createdAt, 'createdAt'),
    'updatedAt': _writeUtcTimestamp(updatedAt, 'updatedAt'),
    'lifecycle': _writeLifecycle(lifecycle),
    'version': version,
    'source': _writeSource(source),
    'title': title,
    'isCompleted': isCompleted,
  };
}

class ExportDocumentV1 {
  ExportDocumentV1({
    required this.createdAt,
    required this.applicationVersion,
    required Iterable<BackupTaskRecordV1> tasks,
    this.applicationId = lifeOsApplicationId,
    this.formatVersion = lifeOsExportFormatVersion,
  }) : tasks = _validatedSortedTasks(tasks) {
    _validateExportDocument(this);
  }

  final int formatVersion;
  final DateTime createdAt;
  final String applicationId;
  final String applicationVersion;
  final List<BackupTaskRecordV1> tasks;

  Map<String, Object> toJson() => {
    'format': lifeOsExportFormatKind,
    'formatVersion': formatVersion,
    'createdAt': _writeUtcTimestamp(createdAt, 'createdAt'),
    'applicationId': applicationId,
    'applicationVersion': applicationVersion,
    'tasks': tasks.map((task) => task.toJson()).toList(growable: false),
  };
}

abstract final class LifeOsDataFormatV1 {
  static String encodeBackupManifest(BackupManifestV1 manifest) {
    _validateBackupManifest(manifest);
    return jsonEncode(manifest.toJson());
  }

  static BackupManifestV1 decodeBackupManifest(String source) {
    final json = _decodeObject(source);
    _requireExactString(json, 'format', lifeOsBackupFormatKind);
    final formatVersion = _requireInt(json, 'formatVersion');
    _requireSupportedVersion(formatVersion, lifeOsBackupFormatVersion);

    return BackupManifestV1(
      formatVersion: formatVersion,
      createdAt: _requireUtcTimestamp(json, 'createdAt'),
      applicationId: _requireString(json, 'applicationId'),
      applicationVersion: _requireString(json, 'applicationVersion'),
      sourceDatabaseSchemaVersion: _requireInt(
        json,
        'sourceDatabaseSchemaVersion',
      ),
      requiredSections: _requireStringList(json, 'requiredSections'),
      dataSha256: _requireString(json, 'dataSha256'),
    );
  }

  static String encodeBackupData(BackupSnapshotV1 snapshot) {
    return jsonEncode(snapshot.toJson());
  }

  static BackupSnapshotV1 decodeBackupData(String source) {
    final json = _decodeObject(source);
    return BackupSnapshotV1(tasks: _requireTasks(json, 'tasks'));
  }

  static String encodeExport(ExportDocumentV1 document) {
    _validateExportDocument(document);
    return const JsonEncoder.withIndent('  ').convert(document.toJson());
  }

  static ExportDocumentV1 decodeExport(String source) {
    final json = _decodeObject(source);
    _requireExactString(json, 'format', lifeOsExportFormatKind);
    final formatVersion = _requireInt(json, 'formatVersion');
    _requireSupportedVersion(formatVersion, lifeOsExportFormatVersion);

    return ExportDocumentV1(
      formatVersion: formatVersion,
      createdAt: _requireUtcTimestamp(json, 'createdAt'),
      applicationId: _requireString(json, 'applicationId'),
      applicationVersion: _requireString(json, 'applicationVersion'),
      tasks: _requireTasks(json, 'tasks'),
    );
  }
}

Map<String, Object?> _decodeObject(String source) {
  try {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const LifeOsDataFormatException(
        code: LifeOsDataFormatErrorCode.invalidField,
        message: 'The document root must be a JSON object.',
      );
    }
    return decoded;
  } on LifeOsDataFormatException {
    rethrow;
  } on FormatException catch (error) {
    throw LifeOsDataFormatException(
      code: LifeOsDataFormatErrorCode.malformedJson,
      message: 'Malformed JSON: ${error.message}',
    );
  }
}

List<BackupTaskRecordV1> _requireTasks(
  Map<String, Object?> json,
  String field,
) {
  final value = _requireField(json, field);
  if (value is! List<Object?>) {
    throw _invalidField(field, 'must be a JSON array');
  }

  return value.indexed
      .map((entry) {
        final (index, item) = entry;
        if (item is! Map<String, dynamic>) {
          throw _invalidField('$field[$index]', 'must be a JSON object');
        }
        return _decodeTask(item, '$field[$index]');
      })
      .toList(growable: false);
}

BackupTaskRecordV1 _decodeTask(Map<String, Object?> json, String path) {
  return BackupTaskRecordV1(
    id: _requireString(json, 'id', path: path),
    entityType: _parseEntityType(
      _requireString(json, 'entityType', path: path),
      '$path.entityType',
    ),
    createdAt: _requireUtcTimestamp(json, 'createdAt', path: path),
    updatedAt: _requireUtcTimestamp(json, 'updatedAt', path: path),
    lifecycle: _parseLifecycle(
      _requireString(json, 'lifecycle', path: path),
      '$path.lifecycle',
    ),
    version: _requireInt(json, 'version', path: path),
    source: _parseSource(
      _requireString(json, 'source', path: path),
      '$path.source',
    ),
    title: _requireString(json, 'title', path: path),
    isCompleted: _requireBool(json, 'isCompleted', path: path),
  );
}

List<BackupTaskRecordV1> _validatedSortedTasks(
  Iterable<BackupTaskRecordV1> tasks,
) {
  final sortedTasks = tasks.toList(growable: false)
    ..sort((first, second) => first.id.compareTo(second.id));
  for (var index = 1; index < sortedTasks.length; index += 1) {
    if (sortedTasks[index - 1].id == sortedTasks[index].id) {
      throw LifeOsDataFormatException(
        code: LifeOsDataFormatErrorCode.duplicateEntityId,
        message: 'Duplicate Entity UUID: ${sortedTasks[index].id}.',
      );
    }
  }
  return List.unmodifiable(sortedTasks);
}

void _validateBackupManifest(BackupManifestV1 manifest) {
  _requireSupportedVersion(manifest.formatVersion, lifeOsBackupFormatVersion);
  _validateUtcTimestamp(manifest.createdAt, 'createdAt');
  _validateApplicationMetadata(
    applicationId: manifest.applicationId,
    applicationVersion: manifest.applicationVersion,
  );
  if (manifest.sourceDatabaseSchemaVersion < 1) {
    throw _invalidField(
      'sourceDatabaseSchemaVersion',
      'must be a positive integer',
    );
  }
  if (manifest.requiredSections.length != 1 ||
      manifest.requiredSections.single != lifeOsBackupDataFileName) {
    throw _invalidField(
      'requiredSections',
      'v1 requires exactly "$lifeOsBackupDataFileName"',
    );
  }
  if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(manifest.dataSha256)) {
    throw _invalidField('dataSha256', 'must be a lowercase SHA-256 hex digest');
  }
}

void _validateExportDocument(ExportDocumentV1 document) {
  _requireSupportedVersion(document.formatVersion, lifeOsExportFormatVersion);
  _validateUtcTimestamp(document.createdAt, 'createdAt');
  _validateApplicationMetadata(
    applicationId: document.applicationId,
    applicationVersion: document.applicationVersion,
  );
}

void _validateApplicationMetadata({
  required String applicationId,
  required String applicationVersion,
}) {
  if (applicationId != lifeOsApplicationId) {
    throw _invalidField('applicationId', 'must be "$lifeOsApplicationId"');
  }
  if (applicationVersion.trim().isEmpty) {
    throw _invalidField('applicationVersion', 'must not be empty');
  }
}

void _validateTask(BackupTaskRecordV1 task) {
  if (!_uuidPattern.hasMatch(task.id)) {
    throw _invalidField('id', 'must be a canonical UUID string');
  }
  if (task.entityType != LifeOsEntityType.task) {
    throw _invalidField('entityType', 'must be "task"');
  }
  _validateUtcTimestamp(task.createdAt, 'createdAt');
  _validateUtcTimestamp(task.updatedAt, 'updatedAt');
  if (task.updatedAt.isBefore(task.createdAt)) {
    throw _invalidField('updatedAt', 'must not be before createdAt');
  }
  if (task.version < 1) {
    throw _invalidField('version', 'must be a positive integer');
  }
  if (task.title.trim().isEmpty) {
    throw _invalidField('title', 'must not be empty');
  }
}

final RegExp _uuidPattern = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
);

Object? _requireField(Map<String, Object?> json, String field, {String? path}) {
  if (!json.containsKey(field) || json[field] == null) {
    throw LifeOsDataFormatException(
      code: LifeOsDataFormatErrorCode.missingField,
      message: 'Missing required field: ${_fieldPath(path, field)}.',
    );
  }
  return json[field];
}

String _requireString(Map<String, Object?> json, String field, {String? path}) {
  final value = _requireField(json, field, path: path);
  if (value is! String) {
    throw _invalidField(_fieldPath(path, field), 'must be a string');
  }
  return value;
}

int _requireInt(Map<String, Object?> json, String field, {String? path}) {
  final value = _requireField(json, field, path: path);
  if (value is! int) {
    throw _invalidField(_fieldPath(path, field), 'must be an integer');
  }
  return value;
}

bool _requireBool(Map<String, Object?> json, String field, {String? path}) {
  final value = _requireField(json, field, path: path);
  if (value is! bool) {
    throw _invalidField(_fieldPath(path, field), 'must be a boolean');
  }
  return value;
}

List<String> _requireStringList(Map<String, Object?> json, String field) {
  final value = _requireField(json, field);
  if (value is! List<Object?> || value.any((item) => item is! String)) {
    throw _invalidField(field, 'must be an array of strings');
  }
  return value.cast<String>();
}

DateTime _requireUtcTimestamp(
  Map<String, Object?> json,
  String field, {
  String? path,
}) {
  final fieldPath = _fieldPath(path, field);
  final value = _requireString(json, field, path: path);
  if (!value.endsWith('Z')) {
    throw _invalidField(fieldPath, 'must be an ISO-8601 UTC timestamp');
  }
  try {
    final timestamp = DateTime.parse(value);
    _validateUtcTimestamp(timestamp, fieldPath);
    return timestamp;
  } on FormatException {
    throw _invalidField(fieldPath, 'must be an ISO-8601 UTC timestamp');
  }
}

void _requireExactString(
  Map<String, Object?> json,
  String field,
  String expected,
) {
  final value = _requireString(json, field);
  if (value != expected) {
    throw _invalidField(field, 'must be "$expected"');
  }
}

void _requireSupportedVersion(int actual, int supported) {
  if (actual != supported) {
    throw LifeOsDataFormatException(
      code: LifeOsDataFormatErrorCode.unsupportedVersion,
      message: 'Unsupported format version: $actual.',
    );
  }
}

void _validateUtcTimestamp(DateTime timestamp, String field) {
  if (!timestamp.isUtc) {
    throw _invalidField(field, 'must be UTC');
  }
}

String _writeUtcTimestamp(DateTime timestamp, String field) {
  _validateUtcTimestamp(timestamp, field);
  return timestamp.toIso8601String();
}

String _writeEntityType(LifeOsEntityType type) => switch (type) {
  LifeOsEntityType.task => 'task',
  LifeOsEntityType.note => 'note',
};

LifeOsEntityType _parseEntityType(String value, String field) =>
    switch (value) {
      'task' => LifeOsEntityType.task,
      'note' => LifeOsEntityType.note,
      _ => throw _invalidField(field, 'contains an unknown Entity type'),
    };

String _writeLifecycle(LifeOsEntityLifecycle lifecycle) => switch (lifecycle) {
  LifeOsEntityLifecycle.active => 'active',
  LifeOsEntityLifecycle.archived => 'archived',
  LifeOsEntityLifecycle.deleted => 'deleted',
};

LifeOsEntityLifecycle _parseLifecycle(String value, String field) =>
    switch (value) {
      'active' => LifeOsEntityLifecycle.active,
      'archived' => LifeOsEntityLifecycle.archived,
      'deleted' => LifeOsEntityLifecycle.deleted,
      _ => throw _invalidField(field, 'contains an unknown lifecycle value'),
    };

String _writeSource(LifeOsEntitySource source) => switch (source) {
  LifeOsEntitySource.user => 'user',
  LifeOsEntitySource.ai => 'ai',
  LifeOsEntitySource.import => 'import',
  LifeOsEntitySource.sync => 'sync',
  LifeOsEntitySource.system => 'system',
};

LifeOsEntitySource _parseSource(String value, String field) => switch (value) {
  'user' => LifeOsEntitySource.user,
  'ai' => LifeOsEntitySource.ai,
  'import' => LifeOsEntitySource.import,
  'sync' => LifeOsEntitySource.sync,
  'system' => LifeOsEntitySource.system,
  _ => throw _invalidField(field, 'contains an unknown source value'),
};

LifeOsDataFormatException _invalidField(String field, String reason) {
  return LifeOsDataFormatException(
    code: LifeOsDataFormatErrorCode.invalidField,
    message: 'Invalid field "$field": $reason.',
  );
}

String _fieldPath(String? path, String field) {
  return path == null ? field : '$path.$field';
}
