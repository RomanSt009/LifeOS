import '../../../application/backup/lifeos_backup_export_contracts.dart';
import 'backup_export_format_v1.dart';
import 'backup_export_format_v2.dart';

class V2BackupExportEncoder implements LifeOsBackupExportEncoder {
  const V2BackupExportEncoder();

  @override
  String encodeBackupData(LifeOsDataSnapshot snapshot) {
    return LifeOsDataFormatV2.encodeBackupData(_snapshot(snapshot));
  }

  @override
  String encodeExport({
    required DateTime createdAt,
    required String applicationVersion,
    required LifeOsDataSnapshot snapshot,
  }) {
    return LifeOsDataFormatV2.encodeExport(
      createdAt: createdAt,
      applicationVersion: applicationVersion,
      snapshot: _snapshot(snapshot),
    );
  }
}

BackupSnapshotV2 _snapshot(LifeOsDataSnapshot snapshot) {
  return BackupSnapshotV2(
    tasks: snapshot.tasks.map(BackupTaskRecordV1.fromDomain).toList(),
    notes: snapshot.notes.map(BackupNoteRecordV2.fromDomain).toList(),
  );
}
