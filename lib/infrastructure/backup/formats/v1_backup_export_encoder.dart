import '../../../application/backup/lifeos_backup_export_contracts.dart';
import 'backup_export_format_v1.dart';

class V1BackupExportEncoder implements LifeOsBackupExportEncoder {
  const V1BackupExportEncoder();

  @override
  String encodeBackupData(LifeOsDataSnapshot snapshot) {
    return LifeOsDataFormatV1.encodeBackupData(
      BackupSnapshotV1(
        tasks: snapshot.tasks.map(BackupTaskRecordV1.fromDomain),
      ),
    );
  }

  @override
  String encodeExport({
    required DateTime createdAt,
    required String applicationVersion,
    required LifeOsDataSnapshot snapshot,
  }) {
    return LifeOsDataFormatV1.encodeExport(
      ExportDocumentV1(
        createdAt: createdAt,
        applicationVersion: applicationVersion,
        tasks: snapshot.tasks.map(BackupTaskRecordV1.fromDomain),
      ),
    );
  }
}
