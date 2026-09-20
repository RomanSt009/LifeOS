import '../../../application/backup/lifeos_backup_export_contracts.dart';
import 'backup_export_format_v1.dart';
import 'backup_export_format_v2.dart';
import 'backup_export_format_v3.dart';
import 'backup_export_format_v4.dart';

class V4BackupExportEncoder implements LifeOsBackupExportEncoder {
  const V4BackupExportEncoder();

  @override
  String encodeBackupData(LifeOsDataSnapshot snapshot) =>
      LifeOsDataFormatV4.encodeBackupData(_snapshot(snapshot));

  @override
  String encodeExport({
    required DateTime createdAt,
    required String applicationVersion,
    required LifeOsDataSnapshot snapshot,
  }) => LifeOsDataFormatV4.encodeExport(
    createdAt: createdAt,
    applicationVersion: applicationVersion,
    snapshot: _snapshot(snapshot),
  );
}

BackupSnapshotV4 _snapshot(LifeOsDataSnapshot snapshot) => BackupSnapshotV4(
  tasks: snapshot.tasks.map(BackupTaskRecordV1.fromDomain).toList(),
  notes: snapshot.notes.map(BackupNoteRecordV2.fromDomain).toList(),
  relationships: snapshot.relationships
      .map(BackupRelationshipRecordV3.fromDomain)
      .toList(),
  workspaces: snapshot.workspaces
      .map(BackupWorkspaceRecordV4.fromDomain)
      .toList(),
  workspaceMemberships: snapshot.workspaceMemberships
      .map(BackupWorkspaceMembershipRecordV4.fromDomain)
      .toList(),
);
