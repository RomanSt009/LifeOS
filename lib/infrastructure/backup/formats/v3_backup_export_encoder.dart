import '../../../application/backup/lifeos_backup_export_contracts.dart';
import 'backup_export_format_v1.dart';
import 'backup_export_format_v2.dart';
import 'backup_export_format_v3.dart';

class V3BackupExportEncoder implements LifeOsBackupExportEncoder {
  const V3BackupExportEncoder();

  @override
  String encodeBackupData(LifeOsDataSnapshot snapshot) =>
      LifeOsDataFormatV3.encodeBackupData(_snapshot(snapshot));

  @override
  String encodeExport({
    required DateTime createdAt,
    required String applicationVersion,
    required LifeOsDataSnapshot snapshot,
  }) => LifeOsDataFormatV3.encodeExport(
    createdAt: createdAt,
    applicationVersion: applicationVersion,
    snapshot: _snapshot(snapshot),
  );
}

BackupSnapshotV3 _snapshot(LifeOsDataSnapshot snapshot) => BackupSnapshotV3(
  tasks: snapshot.tasks.map(BackupTaskRecordV1.fromDomain).toList(),
  notes: snapshot.notes.map(BackupNoteRecordV2.fromDomain).toList(),
  relationships: snapshot.relationships
      .map(BackupRelationshipRecordV3.fromDomain)
      .toList(),
);
