import '../../domain/repositories/lifeos_task_repository.dart';
import '../backup/lifeos_backup_export_contracts.dart';
import 'create_lifeos_backup.dart';

class ExportLifeOsData {
  const ExportLifeOsData({
    required this.taskRepository,
    required this.encoder,
    required this.utcClock,
    required this.applicationVersion,
  });

  final LifeOsTaskRepository taskRepository;
  final LifeOsBackupExportEncoder encoder;
  final BackupUtcClock utcClock;
  final String applicationVersion;

  Future<String> call() async {
    final createdAt = utcClock();
    if (!createdAt.isUtc) {
      throw StateError('An Export timestamp must be UTC.');
    }
    if (applicationVersion.trim().isEmpty) {
      throw StateError('The LifeOS application version must not be empty.');
    }
    final snapshot = LifeOsDataSnapshot(tasks: await taskRepository.getAll());

    return encoder.encodeExport(
      createdAt: createdAt,
      applicationVersion: applicationVersion,
      snapshot: snapshot,
    );
  }
}
