import '../../domain/repositories/lifeos_task_repository.dart';
import '../../domain/repositories/lifeos_note_repository.dart';
import '../../domain/repositories/lifeos_relationship_repository.dart';
import '../backup/lifeos_backup_export_contracts.dart';

typedef BackupUtcClock = DateTime Function();

class CreateLifeOsBackup {
  const CreateLifeOsBackup({
    required this.taskRepository,
    required this.encoder,
    required this.utcClock,
    required this.applicationVersion,
    this.noteRepository,
    this.relationshipRepository,
    this.backupFormatVersion = 1,
  });

  final LifeOsTaskRepository taskRepository;
  final LifeOsBackupExportEncoder encoder;
  final BackupUtcClock utcClock;
  final String applicationVersion;
  final LifeOsNoteRepository? noteRepository;
  final LifeOsRelationshipRepository? relationshipRepository;
  final int backupFormatVersion;

  Future<LifeOsBackupDraft> call() async {
    final createdAt = utcClock();
    _validateMetadata(createdAt, applicationVersion);
    final snapshot = LifeOsDataSnapshot(
      tasks: await taskRepository.getAll(),
      notes: await noteRepository?.getAll() ?? const [],
      relationships: await relationshipRepository?.getAll() ?? const [],
    );

    return LifeOsBackupDraft(
      createdAt: createdAt,
      applicationVersion: applicationVersion,
      dataJson: encoder.encodeBackupData(snapshot),
      formatVersion: backupFormatVersion,
    );
  }
}

void _validateMetadata(DateTime createdAt, String applicationVersion) {
  if (!createdAt.isUtc) {
    throw StateError('A Backup timestamp must be UTC.');
  }
  if (applicationVersion.trim().isEmpty) {
    throw StateError('The LifeOS application version must not be empty.');
  }
}
