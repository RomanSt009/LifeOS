import 'dart:convert';

import '../../../domain/entities/lifeos_entity.dart';
import '../../../domain/entities/lifeos_workspace.dart';
import '../../../domain/entities/lifeos_workspace_membership.dart';
import 'backup_export_format_v1.dart';
import 'backup_export_format_v2.dart';
import 'backup_export_format_v3.dart';

const lifeOsBackupFormatVersionV4 = 4;
const lifeOsExportFormatVersionV4 = 4;

class BackupManifestV4 {
  const BackupManifestV4({
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
    'formatVersion': lifeOsBackupFormatVersionV4,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'applicationId': lifeOsApplicationId,
    'applicationVersion': applicationVersion,
    'sourceDatabaseSchemaVersion': sourceDatabaseSchemaVersion,
    'requiredSections': [lifeOsBackupDataFileName],
    'dataSha256': dataSha256,
  };
}

class BackupWorkspaceRecordV4 {
  BackupWorkspaceRecordV4({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.lifecycle,
    required this.version,
    required this.source,
    required this.title,
    required this.description,
  }) {
    _validateUuid(id, 'Workspace id');
    _validateMetadata(createdAt, updatedAt, version);
    if (title.isEmpty || title != title.trim()) {
      _invalid('Invalid Workspace title.');
    }
  }

  factory BackupWorkspaceRecordV4.fromDomain(LifeOsWorkspace workspace) =>
      BackupWorkspaceRecordV4(
        id: workspace.id.value,
        createdAt: workspace.createdAt,
        updatedAt: workspace.updatedAt,
        lifecycle: workspace.lifecycle,
        version: workspace.version,
        source: workspace.source,
        title: workspace.title,
        description: workspace.description,
      );

  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final LifeOsEntityLifecycle lifecycle;
  final int version;
  final LifeOsEntitySource source;
  final String title;
  final String? description;

  LifeOsWorkspace toDomain() => LifeOsWorkspace(
    id: LifeOsEntityId(value: id, entityType: LifeOsEntityType.workspace),
    title: title,
    description: description,
    createdAt: createdAt,
    updatedAt: updatedAt,
    lifecycle: lifecycle,
    version: version,
    source: source,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'entityType': 'workspace',
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'lifecycle': lifecycle.name,
    'version': version,
    'source': source.name,
    'title': title,
    'description': description,
  };
}

class BackupWorkspaceMembershipRecordV4 {
  BackupWorkspaceMembershipRecordV4({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.lifecycle,
    required this.version,
    required this.source,
    required this.workspaceId,
    required this.memberEntityId,
  }) {
    _validateUuid(id, 'Membership id');
    _validateUuid(workspaceId, 'Membership workspaceId');
    _validateUuid(memberEntityId, 'Membership memberEntityId');
    _validateMetadata(createdAt, updatedAt, version);
    if (lifecycle == LifeOsEntityLifecycle.archived ||
        workspaceId == memberEntityId) {
      _invalid('Invalid Workspace membership.');
    }
  }

  factory BackupWorkspaceMembershipRecordV4.fromDomain(
    LifeOsWorkspaceMembership membership,
  ) => BackupWorkspaceMembershipRecordV4(
    id: membership.id.value,
    createdAt: membership.createdAt,
    updatedAt: membership.updatedAt,
    lifecycle: membership.lifecycle,
    version: membership.version,
    source: membership.source,
    workspaceId: membership.workspaceId.value,
    memberEntityId: membership.memberEntityId.value,
  );

  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final LifeOsEntityLifecycle lifecycle;
  final int version;
  final LifeOsEntitySource source;
  final String workspaceId;
  final String memberEntityId;

  LifeOsWorkspaceMembership toDomain({required LifeOsEntityType memberType}) =>
      LifeOsWorkspaceMembership(
        id: LifeOsEntityId(
          value: id,
          entityType: LifeOsEntityType.workspaceMembership,
        ),
        workspaceId: LifeOsEntityId(
          value: workspaceId,
          entityType: LifeOsEntityType.workspace,
        ),
        memberEntityId: LifeOsEntityId(
          value: memberEntityId,
          entityType: memberType,
        ),
        createdAt: createdAt,
        updatedAt: updatedAt,
        lifecycle: lifecycle,
        version: version,
        source: source,
      );

  Map<String, Object> toJson() => {
    'id': id,
    'entityType': 'workspaceMembership',
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'lifecycle': lifecycle.name,
    'version': version,
    'source': source.name,
    'workspaceId': workspaceId,
    'memberEntityId': memberEntityId,
  };
}

class BackupSnapshotV4 {
  BackupSnapshotV4({
    required this.tasks,
    required this.notes,
    required this.relationships,
    required this.workspaces,
    required this.workspaceMemberships,
  }) {
    // Retain every v3 Relationship invariant before adding v4 Entity types.
    BackupSnapshotV3(tasks: tasks, notes: notes, relationships: relationships);
    final types = <String, LifeOsEntityType>{};
    for (final task in tasks) {
      _addEntity(types, task.id, LifeOsEntityType.task);
    }
    for (final note in notes) {
      _addEntity(types, note.id, LifeOsEntityType.note);
    }
    for (final relationship in relationships) {
      _addEntity(types, relationship.id, LifeOsEntityType.relationship);
    }
    for (final workspace in workspaces) {
      _addEntity(types, workspace.id, LifeOsEntityType.workspace);
    }
    for (final membership in workspaceMemberships) {
      _addEntity(types, membership.id, LifeOsEntityType.workspaceMembership);
    }

    final pairs = <String>{};
    for (final membership in workspaceMemberships) {
      if (types[membership.workspaceId] != LifeOsEntityType.workspace) {
        _invalid('Workspace membership references a missing Workspace.');
      }
      final memberType = types[membership.memberEntityId];
      if (memberType != LifeOsEntityType.task &&
          memberType != LifeOsEntityType.note) {
        _invalid('Workspace membership references an unsupported member.');
      }
      if (!pairs.add(
        '${membership.workspaceId}\u0000${membership.memberEntityId}',
      )) {
        _invalid('Duplicate Workspace membership pair.');
      }
    }
    entityTypesById = Map.unmodifiable(types);
  }

  final List<BackupTaskRecordV1> tasks;
  final List<BackupNoteRecordV2> notes;
  final List<BackupRelationshipRecordV3> relationships;
  final List<BackupWorkspaceRecordV4> workspaces;
  final List<BackupWorkspaceMembershipRecordV4> workspaceMemberships;
  late final Map<String, LifeOsEntityType> entityTypesById;

  Map<String, Object> toJson() => {
    'tasks': tasks.map((value) => value.toJson()).toList(),
    'notes': notes.map((value) => value.toJson()).toList(),
    'relationships': relationships.map((value) => value.toJson()).toList(),
    'workspaces': workspaces.map((value) => value.toJson()).toList(),
    'workspaceMemberships': workspaceMemberships
        .map((value) => value.toJson())
        .toList(),
  };
}

abstract final class LifeOsDataFormatV4 {
  static String encodeManifest(BackupManifestV4 value) =>
      jsonEncode(value.toJson());

  static String encodeBackupData(BackupSnapshotV4 value) =>
      jsonEncode(value.toJson());

  static String encodeExport({
    required DateTime createdAt,
    required String applicationVersion,
    required BackupSnapshotV4 snapshot,
  }) => const JsonEncoder.withIndent('  ').convert({
    'format': lifeOsExportFormatKind,
    'formatVersion': lifeOsExportFormatVersionV4,
    'createdAt': createdAt.toIso8601String(),
    'applicationId': lifeOsApplicationId,
    'applicationVersion': applicationVersion,
    ...snapshot.toJson(),
  });

  static BackupManifestV4 decodeManifest(String source) {
    final json = _object(source);
    _exact(json, 'format', lifeOsBackupFormatKind);
    _version(json, lifeOsBackupFormatVersionV4);
    _exact(json, 'applicationId', lifeOsApplicationId);
    final sections = json['requiredSections'];
    if (sections is! List ||
        sections.length != 1 ||
        sections.single != lifeOsBackupDataFileName) {
      _invalid('Invalid requiredSections.');
    }
    final value = BackupManifestV4(
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

  static BackupSnapshotV4 decodeBackupData(String source) {
    final json = _object(source);
    final v3 = LifeOsDataFormatV3.decodeBackupData(
      jsonEncode({
        'tasks': json['tasks'],
        'notes': json['notes'],
        'relationships': json['relationships'],
      }),
    );
    return BackupSnapshotV4(
      tasks: v3.tasks,
      notes: v3.notes,
      relationships: v3.relationships,
      workspaces: _list(json, 'workspaces').map(_workspace).toList(),
      workspaceMemberships: _list(
        json,
        'workspaceMemberships',
      ).map(_membership).toList(),
    );
  }

  static BackupSnapshotV4 decodeExport(String source) {
    final json = _object(source);
    _exact(json, 'format', lifeOsExportFormatKind);
    _version(json, lifeOsExportFormatVersionV4);
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
        'workspaces': json['workspaces'],
        'workspaceMemberships': json['workspaceMemberships'],
      }),
    );
  }

  static void validateExport(String source) => decodeExport(source);
}

BackupWorkspaceRecordV4 _workspace(Map<String, Object?> json) {
  try {
    _exact(json, 'entityType', 'workspace');
    return BackupWorkspaceRecordV4(
      id: _string(json, 'id'),
      createdAt: _date(json, 'createdAt'),
      updatedAt: _date(json, 'updatedAt'),
      lifecycle: LifeOsEntityLifecycle.values.byName(
        _string(json, 'lifecycle'),
      ),
      version: _integer(json, 'version'),
      source: LifeOsEntitySource.values.byName(_string(json, 'source')),
      title: _string(json, 'title'),
      description: _nullableString(json, 'description'),
    );
  } on LifeOsDataFormatException {
    rethrow;
  } on Object {
    _invalid('Invalid Workspace record.');
  }
}

BackupWorkspaceMembershipRecordV4 _membership(Map<String, Object?> json) {
  try {
    _exact(json, 'entityType', 'workspaceMembership');
    return BackupWorkspaceMembershipRecordV4(
      id: _string(json, 'id'),
      createdAt: _date(json, 'createdAt'),
      updatedAt: _date(json, 'updatedAt'),
      lifecycle: LifeOsEntityLifecycle.values.byName(
        _string(json, 'lifecycle'),
      ),
      version: _integer(json, 'version'),
      source: LifeOsEntitySource.values.byName(_string(json, 'source')),
      workspaceId: _string(json, 'workspaceId'),
      memberEntityId: _string(json, 'memberEntityId'),
    );
  } on LifeOsDataFormatException {
    rethrow;
  } on Object {
    _invalid('Invalid Workspace membership record.');
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

void _validateUuid(String value, String field) {
  if (!_uuidPattern.hasMatch(value)) _invalid('$field is invalid.');
}

void _validateMetadata(DateTime createdAt, DateTime updatedAt, int version) {
  if (!createdAt.isUtc ||
      !updatedAt.isUtc ||
      updatedAt.isBefore(createdAt) ||
      version < 1) {
    _invalid('Invalid Entity metadata.');
  }
}

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

String? _nullableString(Map<String, Object?> json, String field) {
  if (!json.containsKey(field)) _invalid('Missing $field.');
  final value = json[field];
  if (value == null || value is String) return value as String?;
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
