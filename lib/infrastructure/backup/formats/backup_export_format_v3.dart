import 'dart:convert';

import '../../../domain/entities/lifeos_entity.dart';
import '../../../domain/entities/lifeos_relationship.dart';
import 'backup_export_format_v1.dart';
import 'backup_export_format_v2.dart';

const lifeOsBackupFormatVersionV3 = 3;
const lifeOsExportFormatVersionV3 = 3;

class BackupManifestV3 {
  const BackupManifestV3({
    required this.createdAt,
    required this.applicationVersion,
    required this.sourceDatabaseSchemaVersion,
    required this.dataSha256,
  });

  final DateTime createdAt;
  final String applicationVersion;
  final int sourceDatabaseSchemaVersion;
  final String dataSha256;

  Map<String, Object> toJson() => {
    'format': lifeOsBackupFormatKind,
    'formatVersion': lifeOsBackupFormatVersionV3,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'applicationId': lifeOsApplicationId,
    'applicationVersion': applicationVersion,
    'sourceDatabaseSchemaVersion': sourceDatabaseSchemaVersion,
    'requiredSections': [lifeOsBackupDataFileName],
    'dataSha256': dataSha256,
  };
}

class BackupRelationshipRecordV3 {
  BackupRelationshipRecordV3({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.lifecycle,
    required this.version,
    required this.source,
    required this.firstEntityId,
    required this.secondEntityId,
    required this.kind,
  }) {
    if (!_uuidPattern.hasMatch(id) ||
        !_uuidPattern.hasMatch(firstEntityId) ||
        !_uuidPattern.hasMatch(secondEntityId) ||
        firstEntityId.compareTo(secondEntityId) >= 0 ||
        !createdAt.isUtc ||
        !updatedAt.isUtc ||
        updatedAt.isBefore(createdAt) ||
        version < 1) {
      throw const LifeOsDataFormatException(
        code: LifeOsDataFormatErrorCode.invalidField,
        message: 'Invalid Relationship record.',
      );
    }
  }

  factory BackupRelationshipRecordV3.fromDomain(
    LifeOsRelationship relationship,
  ) => BackupRelationshipRecordV3(
    id: relationship.id.value,
    createdAt: relationship.createdAt,
    updatedAt: relationship.updatedAt,
    lifecycle: relationship.lifecycle,
    version: relationship.version,
    source: relationship.source,
    firstEntityId: relationship.firstEntityId.value,
    secondEntityId: relationship.secondEntityId.value,
    kind: relationship.kind,
  );

  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final LifeOsEntityLifecycle lifecycle;
  final int version;
  final LifeOsEntitySource source;
  final String firstEntityId;
  final String secondEntityId;
  final LifeOsRelationshipKind kind;

  Map<String, Object> toJson() => {
    'id': id,
    'entityType': 'relationship',
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'lifecycle': lifecycle.name,
    'version': version,
    'source': source.name,
    'firstEntityId': firstEntityId,
    'secondEntityId': secondEntityId,
    'kind': kind.name,
  };

  LifeOsRelationship toDomain({
    required LifeOsEntityType firstEntityType,
    required LifeOsEntityType secondEntityType,
  }) => LifeOsRelationship(
    id: LifeOsEntityId(value: id, entityType: LifeOsEntityType.relationship),
    firstEntityId: LifeOsEntityId(
      value: firstEntityId,
      entityType: firstEntityType,
    ),
    secondEntityId: LifeOsEntityId(
      value: secondEntityId,
      entityType: secondEntityType,
    ),
    kind: kind,
    createdAt: createdAt,
    updatedAt: updatedAt,
    lifecycle: lifecycle,
    version: version,
    source: source,
  );
}

class BackupSnapshotV3 {
  BackupSnapshotV3({
    required this.tasks,
    required this.notes,
    required this.relationships,
  }) {
    final entityTypes = <String, LifeOsEntityType>{};
    for (final task in tasks) {
      _addEntity(entityTypes, task.id, LifeOsEntityType.task);
    }
    for (final note in notes) {
      _addEntity(entityTypes, note.id, LifeOsEntityType.note);
    }
    for (final relationship in relationships) {
      _addEntity(entityTypes, relationship.id, LifeOsEntityType.relationship);
    }
    final pairs = <String>{};
    for (final relationship in relationships) {
      final firstType = entityTypes[relationship.firstEntityId];
      final secondType = entityTypes[relationship.secondEntityId];
      if (!_supportedEndpoint(firstType) || !_supportedEndpoint(secondType)) {
        throw const LifeOsDataFormatException(
          code: LifeOsDataFormatErrorCode.invalidField,
          message: 'Relationship endpoint is missing or unsupported.',
        );
      }
      final key =
          '${relationship.firstEntityId}\u0000${relationship.secondEntityId}\u0000${relationship.kind.name}';
      if (!pairs.add(key)) {
        throw const LifeOsDataFormatException(
          code: LifeOsDataFormatErrorCode.invalidField,
          message: 'Duplicate Relationship pair and kind.',
        );
      }
    }
    entityTypesById = Map.unmodifiable(entityTypes);
  }

  final List<BackupTaskRecordV1> tasks;
  final List<BackupNoteRecordV2> notes;
  final List<BackupRelationshipRecordV3> relationships;
  late final Map<String, LifeOsEntityType> entityTypesById;

  Map<String, Object> toJson() => {
    'tasks': tasks.map((item) => item.toJson()).toList(),
    'notes': notes.map((item) => item.toJson()).toList(),
    'relationships': relationships.map((item) => item.toJson()).toList(),
  };
}

abstract final class LifeOsDataFormatV3 {
  static String encodeManifest(BackupManifestV3 value) =>
      jsonEncode(value.toJson());
  static String encodeBackupData(BackupSnapshotV3 value) =>
      jsonEncode(value.toJson());
  static String encodeExport({
    required DateTime createdAt,
    required String applicationVersion,
    required BackupSnapshotV3 snapshot,
  }) => const JsonEncoder.withIndent('  ').convert({
    'format': lifeOsExportFormatKind,
    'formatVersion': lifeOsExportFormatVersionV3,
    'createdAt': createdAt.toIso8601String(),
    'applicationId': lifeOsApplicationId,
    'applicationVersion': applicationVersion,
    ...snapshot.toJson(),
  });

  static BackupManifestV3 decodeManifest(String source) {
    final json = _object(source);
    _exact(json, 'format', lifeOsBackupFormatKind);
    _version(json, lifeOsBackupFormatVersionV3);
    _exact(json, 'applicationId', lifeOsApplicationId);
    final sections = json['requiredSections'];
    if (sections is! List ||
        sections.length != 1 ||
        sections.single != lifeOsBackupDataFileName) {
      _invalid('Invalid requiredSections.');
    }
    final value = BackupManifestV3(
      createdAt: _date(json, 'createdAt'),
      applicationVersion: _string(json, 'applicationVersion'),
      sourceDatabaseSchemaVersion: _integer(
        json,
        'sourceDatabaseSchemaVersion',
      ),
      dataSha256: _string(json, 'dataSha256'),
    );
    if (value.applicationVersion.trim().isEmpty ||
        value.sourceDatabaseSchemaVersion < 1 ||
        !RegExp(r'^[0-9a-f]{64}$').hasMatch(value.dataSha256)) {
      _invalid('Invalid manifest metadata.');
    }
    return value;
  }

  static BackupSnapshotV3 decodeBackupData(String source) {
    final json = _object(source);
    final v2 = LifeOsDataFormatV2.decodeBackupData(
      jsonEncode({'tasks': json['tasks'], 'notes': json['notes']}),
    );
    return BackupSnapshotV3(
      tasks: v2.tasks,
      notes: v2.notes,
      relationships: _list(json, 'relationships').map(_relationship).toList(),
    );
  }

  static BackupSnapshotV3 decodeExport(String source) {
    final json = _object(source);
    _exact(json, 'format', lifeOsExportFormatKind);
    _version(json, lifeOsExportFormatVersionV3);
    _date(json, 'createdAt');
    _exact(json, 'applicationId', lifeOsApplicationId);
    if (_string(json, 'applicationVersion').trim().isEmpty) {
      _invalid('Invalid applicationVersion.');
    }
    return decodeBackupData(
      jsonEncode({
        'tasks': json['tasks'],
        'notes': json['notes'],
        'relationships': json['relationships'],
      }),
    );
  }

  static void validateExport(String source) => decodeExport(source);
}

BackupRelationshipRecordV3 _relationship(Map<String, Object?> json) {
  try {
    _exact(json, 'entityType', 'relationship');
    return BackupRelationshipRecordV3(
      id: _string(json, 'id'),
      createdAt: _date(json, 'createdAt'),
      updatedAt: _date(json, 'updatedAt'),
      lifecycle: LifeOsEntityLifecycle.values.byName(
        _string(json, 'lifecycle'),
      ),
      version: _integer(json, 'version'),
      source: LifeOsEntitySource.values.byName(_string(json, 'source')),
      firstEntityId: _string(json, 'firstEntityId'),
      secondEntityId: _string(json, 'secondEntityId'),
      kind: LifeOsRelationshipKind.values.byName(_string(json, 'kind')),
    );
  } on LifeOsDataFormatException {
    rethrow;
  } on Object {
    _invalid('Invalid Relationship record.');
  }
}

void _addEntity(
  Map<String, LifeOsEntityType> values,
  String id,
  LifeOsEntityType type,
) {
  if (values.containsKey(id)) {
    throw const LifeOsDataFormatException(
      code: LifeOsDataFormatErrorCode.duplicateEntityId,
      message: 'Duplicate Entity UUID.',
    );
  }
  values[id] = type;
}

bool _supportedEndpoint(LifeOsEntityType? type) =>
    type == LifeOsEntityType.task || type == LifeOsEntityType.note;

final RegExp _uuidPattern = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
);

Map<String, Object?> _object(String source) {
  try {
    final value = jsonDecode(source);
    if (value is Map<String, dynamic>) return value;
  } on FormatException {
    // Mapped below.
  }
  throw const LifeOsDataFormatException(
    code: LifeOsDataFormatErrorCode.malformedJson,
    message: 'Malformed JSON object.',
  );
}

List<Map<String, Object?>> _list(Map<String, Object?> json, String field) {
  final value = json[field];
  if (value is List && value.every((item) => item is Map<String, dynamic>)) {
    return value.cast<Map<String, Object?>>();
  }
  _invalid('Invalid $field.');
}

String _string(Map<String, Object?> json, String field) {
  final value = json[field];
  if (value is String) return value;
  _invalid('Invalid $field.');
}

int _integer(Map<String, Object?> json, String field) {
  final value = json[field];
  if (value is int) return value;
  _invalid('Invalid $field.');
}

DateTime _date(Map<String, Object?> json, String field) {
  final value = DateTime.tryParse(_string(json, field));
  if (value != null && value.isUtc) return value;
  _invalid('Invalid $field.');
}

void _exact(Map<String, Object?> json, String field, String expected) {
  if (_string(json, field) != expected) _invalid('Invalid $field.');
}

void _version(Map<String, Object?> json, int expected) {
  if (_integer(json, 'formatVersion') != expected) {
    throw const LifeOsDataFormatException(
      code: LifeOsDataFormatErrorCode.unsupportedVersion,
      message: 'Unsupported format version.',
    );
  }
}

Never _invalid(String message) => throw LifeOsDataFormatException(
  code: LifeOsDataFormatErrorCode.invalidField,
  message: message,
);
