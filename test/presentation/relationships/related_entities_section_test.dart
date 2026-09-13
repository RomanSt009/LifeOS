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
    expect(find.text('Remove relationship?'), findsOneWidget);
    expect(
      find.text(
        'The relationship will be removed from Related. The Task or Note will not be deleted.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('cancel-relationship-unlink')));
    await tester.pumpAndSettle();
    expect(
      relationshipRepository.items.single.lifecycle,
      LifeOsEntityLifecycle.active,
    );

    await tester.tap(
      find.byKey(const ValueKey('unlink-relationship-relationship-created')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-relationship-unlink')));
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

  testWidgets('unlink failure stays open and retries without hiding the link', (
    tester,
  ) async {
    final taskRepository = _TaskRepository([_task('task-a', 'Task A')]);
    final noteRepository = _NoteRepository([_note('note-a', 'Note A')]);
    final relationshipRepository = _RelationshipRepository()
      ..items.add(_relationship())
      ..failNextSave = true;
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

    await tester.tap(
      find.byKey(const ValueKey('unlink-relationship-relationship-a')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-relationship-unlink')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('relationship-unlink-error')), findsOneWidget);
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(
      relationshipRepository.items.single.lifecycle,
      LifeOsEntityLifecycle.active,
    );

    await tester.tap(find.byKey(const Key('confirm-relationship-unlink')));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('No related Tasks or Notes'), findsOneWidget);
  });

  testWidgets('Relationship list failure has a bounded retry', (tester) async {
    final taskRepository = _TaskRepository([_task('task-a', 'Task A')]);
    final noteRepository = _NoteRepository([_note('note-a', 'Note A')]);
    final relationshipRepository = _RelationshipRepository()
      ..failNextGetForEntity = true;
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

    expect(find.text('Unable to load relationships'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('retry-relationships-note-a')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('retry-relationships-note-a')));
    await tester.pumpAndSettle();
    expect(find.text('No related Tasks or Notes'), findsOneWidget);
  });

  testWidgets('Endpoint label failure stops loading and can retry', (
    tester,
  ) async {
    final taskRepository = _TaskRepository([_task('task-a', 'Task A')])
      ..failNextLifecycleRead = true;
    final noteRepository = _NoteRepository([_note('note-a', 'Note A')]);
    final relationshipRepository = _RelationshipRepository()
      ..items.add(_relationship());
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

    expect(find.text('Unable to load related item'), findsOneWidget);
    expect(find.text('Loading related item…'), findsNothing);
    await tester.tap(
      find.byKey(const ValueKey('retry-relationship-endpoint-relationship-a')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Task: Task A'), findsOneWidget);
  });

  testWidgets('Relationship picker endpoint failure has a bounded retry', (
    tester,
  ) async {
    final taskRepository = _TaskRepository([_task('task-a', 'Task A')])
      ..failNextLifecycleRead = true;
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

    await tester.tap(find.byKey(const ValueKey('add-relationship-note-a')));
    await tester.pumpAndSettle();
    expect(
      find.text('Unable to load available Tasks and Notes'),
      findsOneWidget,
    );
    expect(find.byType(SimpleDialog), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey('retry-relationship-choices-note-a')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(SimpleDialog), findsOneWidget);
    expect(
      find.byKey(const ValueKey('relationship-choice-task-a')),
      findsOneWidget,
    );
  });
}

LifeOsRelationship _relationship() => LifeOsRelationship.createUserRelationship(
  id: const LifeOsEntityId(
    value: 'relationship-a',
    entityType: LifeOsEntityType.relationship,
  ),
  firstEndpoint: const LifeOsEntityId(
    value: 'task-a',
    entityType: LifeOsEntityType.task,
  ),
  secondEndpoint: const LifeOsEntityId(
    value: 'note-a',
    entityType: LifeOsEntityType.note,
  ),
  timestamp: DateTime.utc(2026, 9, 12),
);

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
  bool failNextLifecycleRead = false;
  @override
  Future<List<LifeOsTask>> getByLifecycle(
    LifeOsEntityLifecycle lifecycle,
  ) async {
    if (failNextLifecycleRead) {
      failNextLifecycleRead = false;
      throw StateError('Expected endpoint load failure.');
    }
    return items.where((item) => item.lifecycle == lifecycle).toList();
  }

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
  Future<List<LifeOsNote>> getByLifecycle(
    LifeOsEntityLifecycle lifecycle,
  ) async => items.where((item) => item.lifecycle == lifecycle).toList();
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
  bool failNextSave = false;
  bool failNextGetForEntity = false;
  @override
  Future<List<LifeOsRelationship>> getAll() async => List.of(items);
  @override
  Future<LifeOsRelationship?> getById(LifeOsEntityId id) async =>
      items.where((item) => item.id == id).firstOrNull;
  @override
  Future<List<LifeOsRelationship>> getForEntity(LifeOsEntityId entityId) async {
    if (failNextGetForEntity) {
      failNextGetForEntity = false;
      throw StateError('Expected relationship load failure.');
    }
    return items
        .where(
          (item) =>
              item.lifecycle == LifeOsEntityLifecycle.active &&
              (item.firstEntityId == entityId ||
                  item.secondEntityId == entityId),
        )
        .toList();
  }

  @override
  Future<void> save(LifeOsRelationship relationship) async {
    if (failNextSave) {
      failNextSave = false;
      throw StateError('Expected relationship save failure.');
    }
    items.removeWhere((item) => item.id == relationship.id);
    items.add(relationship);
  }
}
