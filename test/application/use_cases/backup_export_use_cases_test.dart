import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/application/backup/lifeos_backup_export_contracts.dart';
import 'package:lifeos/application/use_cases/create_lifeos_backup.dart';
import 'package:lifeos/application/use_cases/export_lifeos_data.dart';
import 'package:lifeos/domain/entities/lifeos_entity.dart';
import 'package:lifeos/domain/entities/lifeos_note.dart';
import 'package:lifeos/domain/entities/lifeos_task.dart';
import 'package:lifeos/domain/repositories/lifeos_note_repository.dart';
import 'package:lifeos/domain/repositories/lifeos_task_repository.dart';

void main() {
  final timestamp = DateTime.utc(2026, 9, 11, 14);
  final earlierIdTask = createTask(
    id: '00000000-0000-4000-8000-000000000001',
    lifecycle: LifeOsEntityLifecycle.archived,
    version: 3,
    source: LifeOsEntitySource.import,
    isCompleted: true,
  );
  final laterIdTask = createTask(
    id: '00000000-0000-4000-8000-000000000002',
    lifecycle: LifeOsEntityLifecycle.deleted,
    version: 4,
    source: LifeOsEntitySource.sync,
    isCompleted: false,
  );

  test(
    'creates a deterministic logical Backup draft from every Task',
    () async {
      final repository = FakeLifeOsTaskRepository([laterIdTask, earlierIdTask]);
      final encoder = RecordingBackupExportEncoder();
      var clockReads = 0;
      final createBackup = CreateLifeOsBackup(
        taskRepository: repository,
        encoder: encoder,
        utcClock: () {
          clockReads += 1;
          return timestamp;
        },
        applicationVersion: '1.0.0+1',
      );

      final result = await createBackup();

      expect(repository.getAllCalls, 1);
      expect(clockReads, 1);
      expect(result.createdAt, timestamp);
      expect(result.applicationVersion, '1.0.0+1');
      expect(result.dataJson, 'backup-data');
      expect(encoder.backupSnapshots.single.tasks, [
        earlierIdTask,
        laterIdTask,
      ]);
      expect(encoder.backupSnapshots.single.tasks.first, same(earlierIdTask));
      expect(encoder.backupSnapshots.single.tasks.last, same(laterIdTask));
    },
  );

  test(
    'creates a valid logical Backup draft for an empty repository',
    () async {
      final encoder = RecordingBackupExportEncoder();
      final result = await CreateLifeOsBackup(
        taskRepository: FakeLifeOsTaskRepository([]),
        encoder: encoder,
        utcClock: () => timestamp,
        applicationVersion: '1.0.0+1',
      )();

      expect(result.dataJson, 'backup-data');
      expect(encoder.backupSnapshots.single.tasks, isEmpty);
    },
  );

  test('exports every lifecycle and preserves Domain metadata', () async {
    final repository = FakeLifeOsTaskRepository([laterIdTask, earlierIdTask]);
    final encoder = RecordingBackupExportEncoder();
    var clockReads = 0;
    final exportData = ExportLifeOsData(
      taskRepository: repository,
      encoder: encoder,
      utcClock: () {
        clockReads += 1;
        return timestamp;
      },
      applicationVersion: '1.0.0+1',
    );

    final result = await exportData();

    expect(result, 'export-data');
    expect(repository.getAllCalls, 1);
    expect(clockReads, 1);
    expect(encoder.exportCreatedAt, timestamp);
    expect(encoder.exportApplicationVersion, '1.0.0+1');
    expect(encoder.exportSnapshots.single.tasks, [earlierIdTask, laterIdTask]);
    expect(
      encoder.exportSnapshots.single.tasks.first.lifecycle,
      LifeOsEntityLifecycle.archived,
    );
    expect(encoder.exportSnapshots.single.tasks.first.version, 3);
    expect(
      encoder.exportSnapshots.single.tasks.first.source,
      LifeOsEntitySource.import,
    );
    expect(encoder.exportSnapshots.single.tasks.first.isCompleted, isTrue);
  });

  test('includes Notes in current Backup and Export snapshots', () async {
    final note = LifeOsNote.createUserNote(
      id: const LifeOsEntityId(
        value: '00000000-0000-4000-8000-000000000003',
        entityType: LifeOsEntityType.note,
      ),
      title: 'Note',
      content: ' exact content ',
      timestamp: timestamp,
    );
    final noteRepository = FakeLifeOsNoteRepository([note]);
    final encoder = RecordingBackupExportEncoder();

    final backup = await CreateLifeOsBackup(
      taskRepository: FakeLifeOsTaskRepository([earlierIdTask]),
      noteRepository: noteRepository,
      encoder: encoder,
      utcClock: () => timestamp,
      applicationVersion: '1.0.0+1',
      backupFormatVersion: 2,
    )();
    await ExportLifeOsData(
      taskRepository: FakeLifeOsTaskRepository([earlierIdTask]),
      noteRepository: noteRepository,
      encoder: encoder,
      utcClock: () => timestamp,
      applicationVersion: '1.0.0+1',
    )();

    expect(backup.formatVersion, 2);
    expect(encoder.backupSnapshots.single.notes, [note]);
    expect(encoder.exportSnapshots.single.notes, [note]);
    expect(noteRepository.getAllCalls, 2);
  });

  test('propagates repository errors without invoking serialization', () async {
    final error = StateError('repository failed');
    final repository = FakeLifeOsTaskRepository([], getAllError: error);
    final encoder = RecordingBackupExportEncoder();
    final createBackup = CreateLifeOsBackup(
      taskRepository: repository,
      encoder: encoder,
      utcClock: () => timestamp,
      applicationVersion: '1.0.0+1',
    );

    await expectLater(createBackup(), throwsA(same(error)));
    expect(encoder.backupSnapshots, isEmpty);
  });

  test('rejects a non-UTC operation timestamp before reading data', () async {
    final repository = FakeLifeOsTaskRepository([]);
    final encoder = RecordingBackupExportEncoder();
    final exportData = ExportLifeOsData(
      taskRepository: repository,
      encoder: encoder,
      utcClock: () => DateTime(2026, 9, 11, 14),
      applicationVersion: '1.0.0+1',
    );

    await expectLater(exportData(), throwsStateError);
    expect(repository.getAllCalls, 0);
    expect(encoder.exportSnapshots, isEmpty);
  });
}

LifeOsTask createTask({
  required String id,
  required LifeOsEntityLifecycle lifecycle,
  required int version,
  required LifeOsEntitySource source,
  required bool isCompleted,
}) {
  return LifeOsTask(
    id: LifeOsEntityId(value: id, entityType: LifeOsEntityType.task),
    title: 'Task $id',
    isCompleted: isCompleted,
    createdAt: DateTime.utc(2026, 9, 10, 10),
    updatedAt: DateTime.utc(2026, 9, 11, 11),
    lifecycle: lifecycle,
    version: version,
    source: source,
  );
}

class FakeLifeOsTaskRepository implements LifeOsTaskRepository {
  FakeLifeOsTaskRepository(this.tasks, {this.getAllError});

  final List<LifeOsTask> tasks;
  final Object? getAllError;
  int getAllCalls = 0;

  @override
  Future<List<LifeOsTask>> getAll() async {
    getAllCalls += 1;
    if (getAllError case final error?) {
      throw error;
    }
    return tasks;
  }

  @override
  Future<LifeOsTask?> getById(LifeOsEntityId id) async => null;

  @override
  Future<List<LifeOsTask>> searchByTitle(String query) async => [];

  @override
  Future<void> save(LifeOsTask task) async {}
}

class FakeLifeOsNoteRepository implements LifeOsNoteRepository {
  FakeLifeOsNoteRepository(this.notes);

  final List<LifeOsNote> notes;
  int getAllCalls = 0;

  @override
  Future<List<LifeOsNote>> getAll() async {
    getAllCalls += 1;
    return notes;
  }

  @override
  Future<LifeOsNote?> getById(LifeOsEntityId id) async => null;

  @override
  Future<void> save(LifeOsNote note) async {}
}

class RecordingBackupExportEncoder implements LifeOsBackupExportEncoder {
  final List<LifeOsDataSnapshot> backupSnapshots = [];
  final List<LifeOsDataSnapshot> exportSnapshots = [];
  DateTime? exportCreatedAt;
  String? exportApplicationVersion;

  @override
  String encodeBackupData(LifeOsDataSnapshot snapshot) {
    backupSnapshots.add(snapshot);
    return 'backup-data';
  }

  @override
  String encodeExport({
    required DateTime createdAt,
    required String applicationVersion,
    required LifeOsDataSnapshot snapshot,
  }) {
    exportCreatedAt = createdAt;
    exportApplicationVersion = applicationVersion;
    exportSnapshots.add(snapshot);
    return 'export-data';
  }
}
