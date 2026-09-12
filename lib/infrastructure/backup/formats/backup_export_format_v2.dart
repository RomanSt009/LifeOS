import 'dart:convert';

import '../../../domain/entities/lifeos_entity.dart';
import '../../../domain/entities/lifeos_note.dart';
import 'backup_export_format_v1.dart';

const lifeOsBackupFormatVersionV2 = 2;
const lifeOsExportFormatVersionV2 = 2;

class BackupManifestV2 {
  BackupManifestV2({
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
    'formatVersion': lifeOsBackupFormatVersionV2,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'applicationId': lifeOsApplicationId,
    'applicationVersion': applicationVersion,
    'sourceDatabaseSchemaVersion': sourceDatabaseSchemaVersion,
    'requiredSections': [lifeOsBackupDataFileName],
    'dataSha256': dataSha256,
  };
}

class BackupNoteRecordV2 {
  BackupNoteRecordV2({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.lifecycle,
    required this.version,
    required this.source,
    required this.title,
    required this.content,
  }) {
    if (!_uuidPattern.hasMatch(id) ||
        !createdAt.isUtc ||
        !updatedAt.isUtc ||
        updatedAt.isBefore(createdAt) ||
        version < 1 ||
        title != title.trim() ||
        (title.isEmpty && content.trim().isEmpty)) {
      throw const LifeOsDataFormatException(
        code: LifeOsDataFormatErrorCode.invalidField,
        message: 'Invalid Note record.',
      );
    }
  }

  factory BackupNoteRecordV2.fromDomain(LifeOsNote note) => BackupNoteRecordV2(
    id: note.id.value,
    createdAt: note.createdAt,
    updatedAt: note.updatedAt,
    lifecycle: note.lifecycle,
    version: note.version,
    source: note.source,
    title: note.title,
    content: note.content,
  );

  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final LifeOsEntityLifecycle lifecycle;
  final int version;
  final LifeOsEntitySource source;
  final String title;
  final String content;

  LifeOsNote toDomain() => LifeOsNote(
    id: LifeOsEntityId(value: id, entityType: LifeOsEntityType.note),
    title: title,
    content: content,
    createdAt: createdAt,
    updatedAt: updatedAt,
    lifecycle: lifecycle,
    version: version,
    source: source,
  );

  Map<String, Object> toJson() => {
    'id': id,
    'entityType': 'note',
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'lifecycle': lifecycle.name,
    'version': version,
    'source': source.name,
    'title': title,
    'content': content,
  };
}

class BackupSnapshotV2 {
  BackupSnapshotV2({required this.tasks, required this.notes}) {
    final ids = [...tasks.map((e) => e.id), ...notes.map((e) => e.id)];
    if (ids.toSet().length != ids.length) {
      throw const LifeOsDataFormatException(
        code: LifeOsDataFormatErrorCode.duplicateEntityId,
        message: 'Duplicate Entity UUID.',
      );
    }
  }
  final List<BackupTaskRecordV1> tasks;
  final List<BackupNoteRecordV2> notes;
  Map<String, Object> toJson() => {
    'tasks': tasks.map((e) => e.toJson()).toList(),
    'notes': notes.map((e) => e.toJson()).toList(),
  };
}

abstract final class LifeOsDataFormatV2 {
  static String encodeManifest(BackupManifestV2 value) =>
      jsonEncode(value.toJson());
  static String encodeBackupData(BackupSnapshotV2 value) =>
      jsonEncode(value.toJson());
  static String encodeExport({
    required DateTime createdAt,
    required String applicationVersion,
    required BackupSnapshotV2 snapshot,
  }) => const JsonEncoder.withIndent('  ').convert({
    'format': lifeOsExportFormatKind,
    'formatVersion': lifeOsExportFormatVersionV2,
    'createdAt': createdAt.toIso8601String(),
    'applicationId': lifeOsApplicationId,
    'applicationVersion': applicationVersion,
    ...snapshot.toJson(),
  });

  static BackupManifestV2 decodeManifest(String source) {
    final json = _object(source);
    _exact(json, 'format', lifeOsBackupFormatKind);
    _version(json, lifeOsBackupFormatVersionV2);
    _exact(json, 'applicationId', lifeOsApplicationId);
    final sections = json['requiredSections'];
    if (sections is! List ||
        sections.length != 1 ||
        sections.single != lifeOsBackupDataFileName) {
      throw const LifeOsDataFormatException(
        code: LifeOsDataFormatErrorCode.invalidField,
        message: 'Invalid requiredSections.',
      );
    }
    final manifest = BackupManifestV2(
      createdAt: _date(json, 'createdAt'),
      applicationVersion: _string(json, 'applicationVersion'),
      sourceDatabaseSchemaVersion: _integer(
        json,
        'sourceDatabaseSchemaVersion',
      ),
      dataSha256: _string(json, 'dataSha256'),
    );
    if (manifest.applicationVersion.trim().isEmpty ||
        manifest.sourceDatabaseSchemaVersion < 1 ||
        !RegExp(r'^[0-9a-f]{64}$').hasMatch(manifest.dataSha256)) {
      throw const LifeOsDataFormatException(
        code: LifeOsDataFormatErrorCode.invalidField,
        message: 'Invalid manifest metadata.',
      );
    }
    return manifest;
  }

  static BackupSnapshotV2 decodeBackupData(String source) {
    final json = _object(source);
    final tasks = _list(json, 'tasks').map((item) {
      return LifeOsDataFormatV1.decodeBackupData(
        jsonEncode({
          'tasks': [item],
        }),
      ).tasks.single;
    }).toList();
    final notes = _list(json, 'notes').map(_note).toList();
    return BackupSnapshotV2(tasks: tasks, notes: notes);
  }

  static BackupSnapshotV2 decodeExport(String source) {
    final json = _object(source);
    _exact(json, 'format', lifeOsExportFormatKind);
    _version(json, lifeOsExportFormatVersionV2);
    _date(json, 'createdAt');
    _exact(json, 'applicationId', lifeOsApplicationId);
    if (_string(json, 'applicationVersion').trim().isEmpty) {
      throw const LifeOsDataFormatException(
        code: LifeOsDataFormatErrorCode.invalidField,
        message: 'Invalid applicationVersion.',
      );
    }
    return decodeBackupData(
      jsonEncode({'tasks': json['tasks'], 'notes': json['notes']}),
    );
  }

  static void validateExport(String source) {
    decodeExport(source);
  }
}

BackupNoteRecordV2 _note(Map<String, Object?> json) {
  try {
    _exact(json, 'entityType', 'note');
    return BackupNoteRecordV2(
      id: _string(json, 'id'),
      createdAt: _date(json, 'createdAt'),
      updatedAt: _date(json, 'updatedAt'),
      lifecycle: LifeOsEntityLifecycle.values.byName(
        _string(json, 'lifecycle'),
      ),
      version: _integer(json, 'version'),
      source: LifeOsEntitySource.values.byName(_string(json, 'source')),
      title: _string(json, 'title'),
      content: _string(json, 'content'),
    );
  } on LifeOsDataFormatException {
    rethrow;
  } on Object {
    throw const LifeOsDataFormatException(
      code: LifeOsDataFormatErrorCode.invalidField,
      message: 'Invalid Note record.',
    );
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
  if (value is! List || value.any((e) => e is! Map<String, dynamic>)) {
    throw LifeOsDataFormatException(
      code: LifeOsDataFormatErrorCode.invalidField,
      message: 'Invalid $field.',
    );
  }
  return value.cast<Map<String, Object?>>();
}

String _string(Map<String, Object?> json, String field) {
  final value = json[field];
  if (value is String) return value;
  throw LifeOsDataFormatException(
    code: LifeOsDataFormatErrorCode.invalidField,
    message: 'Invalid $field.',
  );
}

int _integer(Map<String, Object?> json, String field) {
  final value = json[field];
  if (value is int) return value;
  throw LifeOsDataFormatException(
    code: LifeOsDataFormatErrorCode.invalidField,
    message: 'Invalid $field.',
  );
}

DateTime _date(Map<String, Object?> json, String field) {
  final value = DateTime.tryParse(_string(json, field));
  if (value != null && value.isUtc) return value;
  throw LifeOsDataFormatException(
    code: LifeOsDataFormatErrorCode.invalidField,
    message: 'Invalid $field.',
  );
}

void _exact(Map<String, Object?> json, String field, String expected) {
  if (_string(json, field) != expected) {
    throw LifeOsDataFormatException(
      code: LifeOsDataFormatErrorCode.invalidField,
      message: 'Invalid $field.',
    );
  }
}

void _version(Map<String, Object?> json, int expected) {
  if (_integer(json, 'formatVersion') != expected) {
    throw LifeOsDataFormatException(
      code: LifeOsDataFormatErrorCode.unsupportedVersion,
      message: 'Unsupported format version.',
    );
  }
}
