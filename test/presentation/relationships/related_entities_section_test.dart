import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/application/use_cases/create_lifeos_note.dart';
import 'package:lifeos/application/use_cases/create_lifeos_relationship.dart';
import 'package:lifeos/application/use_cases/create_lifeos_task.dart';
import 'package:lifeos/application/use_cases/edit_lifeos_note.dart';
import 'package:lifeos/application/use_cases/unlink_lifeos_relationship.dart';
import 'package:lifeos/domain/entities/lifeos_entity.dart';
import 'package:lifeos/domain/entities/lifeos_note.dart';
import 'package:lifeos/domain/entities/lifeos_relationship.dart';
import 'package:lifeos/domain/entities/lifeos_task.dart';
import 'package:lifeos/domain/repositories/lifeos_note_repository.dart';
import 'package:lifeos/domain/repositories/lifeos_relationship_repository.dart';
import 'package:lifeos/domain/repositories/lifeos_task_repository.dart';
import 'package:lifeos/l10n/app_localizations.dart';
import 'package:lifeos/presentation/notes/note_page.dart';
import 'package:lifeos/presentation/notes/note_providers.dart';
import 'package:lifeos/presentation/relationships/relationship_providers.dart';
import 'package:lifeos/presentation/tasks/task_completion_providers.dart';
import 'package:lifeos/presentation/tasks/task_list.dart';
import 'package:lifeos/presentation/tasks/task_list_providers.dart';

void main() {
  testWidgets('Note context adds, displays, and unlinks a Task relationship', (
    tester,
  ) async {
    final taskRepository = _TaskRepository([_task('task-a', 'Task A')]);
    final noteRepository = _NoteRepository([_note('note-a', 'Note A')]);
    final relationshipRepository = _RelationshipRepository();

    await tester.pumpWidget(
      _app(
        const NotePage(),
        taskRepository,
        noteRepository,
        relationshipRepository,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('note-note-a')));
    await tester.pumpAndSettle();

    expect(find.text('Related'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('add-relationship-note-a')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('relationship-choice-task-a')));
    await tester.pumpAndSettle();

    expect(find.text('Task: Task A'), findsOneWidget);
    expect(relationshipRepository.items, hasLength(1));

    await tester.tap(
      find.byKey(const ValueKey('unlink-relationship-relationship-created')),
    );
    await tester.pumpAndSettle();
    expect(
      relationshipRepository.items.single.lifecycle,
      LifeOsEntityLifecycle.deleted,
    );
    expect(find.text('No related Tasks or Notes'), findsOneWidget);
  });

  testWidgets('Task context exposes localized Related section', (tester) async {
    final taskRepository = _TaskRepository([_task('task-a', 'Task A')]);
    final noteRepository = _NoteRepository([_note('note-a', 'Заметка А')]);
    final relationshipRepository = _RelationshipRepository();

    await tester.pumpWidget(
      _app(
        const TaskList(),
        taskRepository,
        noteRepository,
        relationshipRepository,
        locale: const Locale('ru'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('task-task-a')));
    await tester.pumpAndSettle();

    expect(find.text('Связанные'), findsOneWidget);
    expect(find.text('Добавить связь'), findsOneWidget);
  });
}

Widget _app(
  Widget child,
  _TaskRepository tasks,
  _NoteRepository notes,
  _RelationshipRepository relationships, {
  Locale locale = const Locale('en'),
}) {
  final createRelationship = CreateLifeOsRelationship(
    relationshipRepository: relationships,
    taskRepository: tasks,
    noteRepository: notes,
    entityIdGenerator: () => 'relationship-created',
    utcClock: () => DateTime.utc(2026, 9, 12, 12),
  );
  return ProviderScope(
    overrides: [
      lifeOsTaskRepositoryProvider.overrideWithValue(tasks),
      lifeOsNoteRepositoryProvider.overrideWithValue(notes),
      lifeOsRelationshipRepositoryProvider.overrideWithValue(relationships),
      createLifeOsTaskProvider.overrideWithValue(
        CreateLifeOsTask(
          repository: tasks,
          entityIdGenerator: () => 'task-created',
          utcClock: () => DateTime.utc(2026, 9, 12),
        ),
      ),
      createLifeOsNoteProvider.overrideWithValue(
        CreateLifeOsNote(
          repository: notes,
          entityIdGenerator: () => 'note-created',
          utcClock: () => DateTime.utc(2026, 9, 12),
        ),
      ),
      editLifeOsNoteProvider.overrideWithValue(
        EditLifeOsNote(
          repository: notes,
          utcClock: () => DateTime.utc(2026, 9, 12),
        ),
      ),
      createLifeOsRelationshipProvider.overrideWithValue(createRelationship),
      unlinkLifeOsRelationshipProvider.overrideWithValue(
        UnlinkLifeOsRelationship(
          repository: relationships,
          utcClock: () => DateTime.utc(2026, 9, 12, 13),
        ),
      ),
    ],
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

LifeOsTask _task(String id, String title) => LifeOsTask(
  id: LifeOsEntityId(value: id, entityType: LifeOsEntityType.task),
  title: title,
  isCompleted: false,
  createdAt: DateTime.utc(2026, 9, 12),
  updatedAt: DateTime.utc(2026, 9, 12),
  lifecycle: LifeOsEntityLifecycle.active,
  version: 1,
  source: LifeOsEntitySource.user,
);

LifeOsNote _note(String id, String title) => LifeOsNote(
  id: LifeOsEntityId(value: id, entityType: LifeOsEntityType.note),
  title: title,
  content: '',
  createdAt: DateTime.utc(2026, 9, 12),
  updatedAt: DateTime.utc(2026, 9, 12),
  lifecycle: LifeOsEntityLifecycle.active,
  version: 1,
  source: LifeOsEntitySource.user,
);

class _TaskRepository implements LifeOsTaskRepository {
  _TaskRepository(this.items);
  final List<LifeOsTask> items;
  @override
  Future<List<LifeOsTask>> getAll() async => List.of(items);
  @override
  Future<LifeOsTask?> getById(LifeOsEntityId id) async =>
      items.where((item) => item.id == id).firstOrNull;
  @override
  Future<void> save(LifeOsTask task) async {}
  @override
  Future<List<LifeOsTask>> searchByTitle(String query) async => [];
}

class _NoteRepository implements LifeOsNoteRepository {
  _NoteRepository(this.items);
  final List<LifeOsNote> items;
  @override
  Future<List<LifeOsNote>> getAll() async => List.of(items);
  @override
  Future<LifeOsNote?> getById(LifeOsEntityId id) async =>
      items.where((item) => item.id == id).firstOrNull;
  @override
  Future<void> save(LifeOsNote note) async {}
}

class _RelationshipRepository implements LifeOsRelationshipRepository {
  final List<LifeOsRelationship> items = [];
  @override
  Future<List<LifeOsRelationship>> getAll() async => List.of(items);
  @override
  Future<LifeOsRelationship?> getById(LifeOsEntityId id) async =>
      items.where((item) => item.id == id).firstOrNull;
  @override
  Future<List<LifeOsRelationship>> getForEntity(
    LifeOsEntityId entityId,
  ) async => items
      .where(
        (item) =>
            item.lifecycle == LifeOsEntityLifecycle.active &&
            (item.firstEntityId == entityId || item.secondEntityId == entityId),
      )
      .toList();
  @override
  Future<void> save(LifeOsRelationship relationship) async {
    items.removeWhere((item) => item.id == relationship.id);
    items.add(relationship);
  }
}
