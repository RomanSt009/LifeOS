import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/application/use_cases/create_lifeos_task.dart';
import 'package:lifeos/application/use_cases/delete_lifeos_task.dart';
import 'package:lifeos/application/use_cases/edit_lifeos_task_title.dart';
import 'package:lifeos/application/use_cases/restore_lifeos_task.dart';
import 'package:lifeos/domain/entities/lifeos_entity.dart';
import 'package:lifeos/domain/entities/lifeos_task.dart';
import 'package:lifeos/domain/repositories/lifeos_task_repository.dart';
import 'package:lifeos/l10n/app_localizations.dart';
import 'package:lifeos/presentation/tasks/task_completion_providers.dart';
import 'package:lifeos/presentation/tasks/task_list.dart';
import 'package:lifeos/presentation/tasks/task_list_providers.dart';

void main() {
  testWidgets('renders loading and empty Task states', (tester) async {
    final pendingTasks = Completer<List<LifeOsTask>>();
    final repository = FakeLifeOsTaskRepository(() => pendingTasks.future);

    await tester.pumpWidget(testApp(repository));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    pendingTasks.complete([]);
    await tester.pumpAndSettle();

    expect(find.text('No Tasks yet'), findsOneWidget);
  });

  testWidgets('renders persisted Tasks', (tester) async {
    final repository = FakeLifeOsTaskRepository(
      () async => [
        createTask('task-1', 'Plan the day', isCompleted: false),
        createTask('task-2', 'Review progress', isCompleted: true),
      ],
    );

    await tester.pumpWidget(testApp(repository));
    await tester.pumpAndSettle();

    expect(find.text('Plan the day'), findsOneWidget);
    expect(find.text('Review progress'), findsOneWidget);
    expect(find.byIcon(Icons.radio_button_unchecked), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
  });

  testWidgets('renders a bounded Task loading error', (tester) async {
    final repository = FakeLifeOsTaskRepository(
      () => Future.error(StateError('database details')),
    );

    await tester.pumpWidget(testApp(repository));
    await tester.pumpAndSettle();

    expect(find.text('Unable to load Tasks'), findsOneWidget);
    expect(find.textContaining('database details'), findsNothing);
  });

  testWidgets('creates a Task and adds the persisted result to the list', (
    tester,
  ) async {
    final repository = FakeLifeOsTaskRepository(() async => []);

    await tester.pumpWidget(testApp(repository));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('task-title-field')),
      'Create through the UI',
    );
    await tester.tap(find.byKey(const Key('create-task-button')));
    await tester.pumpAndSettle();

    expect(find.text('Create through the UI'), findsOneWidget);
    expect(repository.savedTasks, hasLength(1));
    expect(repository.savedTasks.single.id.value, 'task-created');
    expect(repository.savedTasks.single.createdAt.isUtc, isTrue);
    expect(
      repository.savedTasks.single.updatedAt,
      DateTime.utc(2026, 9, 9, 16),
    );
  });

  testWidgets('toggles persisted completion from the Task list', (
    tester,
  ) async {
    final task = createTask(
      'task-1',
      'Toggle from the list',
      isCompleted: false,
    );
    final repository = FakeLifeOsTaskRepository(
      () async => [task],
      storedTask: task,
    );

    await tester.pumpWidget(testApp(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Mark complete'));
    await tester.pumpAndSettle();

    expect(repository.savedTasks.last.isCompleted, isTrue);
    expect(find.byTooltip('Mark incomplete'), findsOneWidget);

    await tester.tap(find.byTooltip('Mark incomplete'));
    await tester.pumpAndSettle();

    expect(repository.savedTasks.last.isCompleted, isFalse);
    expect(find.byTooltip('Mark complete'), findsOneWidget);
  });

  testWidgets('edits a Task title through the localized dialog', (
    tester,
  ) async {
    final task = createTask('task-1', 'Original title', isCompleted: false);
    final repository = FakeLifeOsTaskRepository(
      () async => [task],
      storedTask: task,
    );
    await tester.pumpWidget(testApp(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('edit-task-task-1')));
    await tester.pumpAndSettle();
    final field = tester.widget<TextField>(
      find.byKey(const Key('task-edit-title-field')),
    );
    expect(field.controller?.text, 'Original title');

    await tester.enterText(
      find.byKey(const Key('task-edit-title-field')),
      '  Edited title  ',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.text('Edited title'), findsOneWidget);
    expect(repository.savedTasks.single.title, 'Edited title');
    expect(repository.savedTasks.single.version, 2);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('validates an empty title and cancels without mutation', (
    tester,
  ) async {
    final task = createTask('task-1', 'Original title', isCompleted: false);
    final repository = FakeLifeOsTaskRepository(
      () async => [task],
      storedTask: task,
    );
    await tester.pumpWidget(testApp(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('edit-task-task-1')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('task-edit-title-field')),
      '   ',
    );
    await tester.tap(find.byKey(const Key('save-task-edit-button')));
    await tester.pump();

    expect(find.text('Enter a Task title'), findsOneWidget);
    expect(repository.savedTasks, isEmpty);
    await tester.tap(find.byKey(const Key('cancel-task-edit-button')));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Original title'), findsOneWidget);
  });

  testWidgets('keeps the dialog open on failure and allows retry', (
    tester,
  ) async {
    final task = createTask('task-1', 'Original title', isCompleted: false);
    var attempts = 0;
    final repository = FakeLifeOsTaskRepository(
      () async => [task],
      storedTask: task,
      beforeSave: (_) async {
        attempts++;
        if (attempts == 1) {
          throw StateError('write failed');
        }
      },
    );
    await tester.pumpWidget(testApp(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('edit-task-task-1')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('task-edit-title-field')),
      'Recovered title',
    );
    await tester.tap(find.byKey(const Key('save-task-edit-button')));
    await tester.pumpAndSettle();

    expect(find.text('Unable to save Task'), findsOneWidget);
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(repository.savedTasks, isEmpty);

    await tester.tap(find.byKey(const Key('save-task-edit-button')));
    await tester.pumpAndSettle();
    expect(find.text('Recovered title'), findsOneWidget);
    expect(repository.savedTasks, hasLength(1));
  });

  testWidgets('Escape closes Task edit without mutation', (tester) async {
    final task = createTask('task-1', 'Original title', isCompleted: false);
    final repository = FakeLifeOsTaskRepository(
      () async => [task],
      storedTask: task,
    );
    await tester.pumpWidget(testApp(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('edit-task-task-1')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('task-edit-title-field')),
      'Unsaved title',
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Original title'), findsOneWidget);
    expect(repository.savedTasks, isEmpty);
  });

  testWidgets('disables edit actions while one save is in flight', (
    tester,
  ) async {
    final task = createTask('task-1', 'Original title', isCompleted: false);
    final saveStarted = Completer<void>();
    final releaseSave = Completer<void>();
    final repository = FakeLifeOsTaskRepository(
      () async => [task],
      storedTask: task,
      beforeSave: (_) async {
        saveStarted.complete();
        await releaseSave.future;
      },
    );
    await tester.pumpWidget(testApp(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('edit-task-task-1')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('task-edit-title-field')),
      'Only once',
    );
    await tester.tap(find.byKey(const Key('save-task-edit-button')));
    await tester.pump();
    await saveStarted.future;

    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('save-task-edit-button')))
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<TextButton>(find.byKey(const Key('cancel-task-edit-button')))
          .onPressed,
      isNull,
    );
    releaseSave.complete();
    await tester.pumpAndSettle();
    expect(repository.savedTasks, hasLength(1));
  });

  testWidgets('confirms delete and restores a Task from feature Trash', (
    tester,
  ) async {
    final task = createTask('task-1', 'Lifecycle Task', isCompleted: false);
    final repository = FakeLifeOsTaskRepository(
      () async => [task],
      storedTask: task,
    );
    await tester.pumpWidget(testApp(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('delete-task-task-1')));
    await tester.pumpAndSettle();
    expect(find.text('Move Task to Trash?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(repository.savedTasks, isEmpty);

    await tester.tap(find.byKey(const ValueKey('delete-task-task-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-delete-task-button')));
    await tester.pumpAndSettle();
    expect(find.text('Lifecycle Task'), findsNothing);
    expect(
      repository.savedTasks.single.lifecycle,
      LifeOsEntityLifecycle.deleted,
    );

    await tester.tap(find.byKey(const Key('task-trash-toggle')));
    await tester.pumpAndSettle();
    expect(find.text('Lifecycle Task'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('restore-task-task-1')));
    await tester.pumpAndSettle();
    expect(repository.savedTasks.last.lifecycle, LifeOsEntityLifecycle.active);
    expect(find.text('Lifecycle Task'), findsNothing);

    await tester.tap(find.byKey(const Key('task-trash-toggle')));
    await tester.pumpAndSettle();
    expect(find.text('Lifecycle Task'), findsOneWidget);
  });

  testWidgets('keeps Task delete confirmation open on failure for retry', (
    tester,
  ) async {
    final task = createTask('task-1', 'Retry delete', isCompleted: false);
    var attempts = 0;
    final repository = FakeLifeOsTaskRepository(
      () async => [task],
      storedTask: task,
      beforeSave: (_) async {
        attempts += 1;
        if (attempts == 1) throw StateError('write failed');
      },
    );
    await tester.pumpWidget(testApp(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('delete-task-task-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-delete-task-button')));
    await tester.pumpAndSettle();
    expect(find.text('Unable to delete Task'), findsOneWidget);
    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.tap(find.byKey(const Key('confirm-delete-task-button')));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(
      repository.savedTasks.single.lifecycle,
      LifeOsEntityLifecycle.deleted,
    );
  });

  testWidgets('Task context menu targets the right-clicked Task by id', (
    tester,
  ) async {
    final first = createTask('task-1', 'First Task', isCompleted: false);
    final second = createTask('task-2', 'Second Task', isCompleted: false);
    final repository = FakeLifeOsTaskRepository(
      () async => [first, second],
      storedTask: second,
    );
    await tester.pumpWidget(testApp(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('First Task'));
    await tester.pumpAndSettle();
    await _secondaryTap(tester, find.text('Second Task'));

    expect(find.text('Edit Task'), findsOneWidget);
    expect(find.text('Mark complete'), findsWidgets);
    expect(find.byKey(const Key('task-context-relationships')), findsOneWidget);
    expect(find.text('Move to Trash'), findsOneWidget);
    await tester.tap(find.text('Mark complete').last);
    await tester.pumpAndSettle();

    expect(repository.savedTasks.single.id.value, 'task-2');
    expect(repository.savedTasks.single.isCompleted, isTrue);

    await _secondaryTap(tester, find.text('Second Task'));
    await tester.tap(find.byKey(const Key('task-context-relationships')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('add-relationship-task-2')).hitTestable(),
      findsOneWidget,
    );
  });

  testWidgets('Delete requires selection and never fires in the title field', (
    tester,
  ) async {
    final task = createTask('task-1', 'Keyboard Task', isCompleted: false);
    final repository = FakeLifeOsTaskRepository(
      () async => [task],
      storedTask: task,
    );
    await tester.pumpWidget(testApp(repository));
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);

    await tester.tap(find.text('Keyboard Task'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('task-title-field')),
      'Draft title',
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await tester.pump();
    expect(find.byType(AlertDialog), findsNothing);

    await tester.tap(find.text('Keyboard Task'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await tester.pumpAndSettle();
    expect(find.text('Move Task to Trash?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await _pressControlN(tester);
    await tester.pump();
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('task-title-field')))
          .focusNode
          ?.hasFocus,
      isTrue,
    );
  });

  testWidgets('Task Trash context menu exposes Restore only', (tester) async {
    final task = createTask('task-1', 'Trash Task', isCompleted: false);
    final repository = FakeLifeOsTaskRepository(
      () async => [task],
      storedTask: task,
    );
    await tester.pumpWidget(testApp(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('delete-task-task-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-delete-task-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('task-trash-toggle')));
    await tester.pumpAndSettle();
    await _secondaryTap(tester, find.text('Trash Task'));

    expect(find.byKey(const Key('task-context-restore')), findsOneWidget);
    expect(find.byKey(const Key('task-context-edit')), findsNothing);
    expect(find.byKey(const Key('task-context-move-to-trash')), findsNothing);
    await tester.tap(find.byKey(const Key('task-context-restore')));
    await tester.pumpAndSettle();
    expect(repository.savedTasks.last.lifecycle, LifeOsEntityLifecycle.active);
  });

  testWidgets('completion failure is visible, truthful, and retryable', (
    tester,
  ) async {
    final task = createTask('task-1', 'Retry completion', isCompleted: false);
    var attempts = 0;
    final repository = FakeLifeOsTaskRepository(
      () async => [task],
      storedTask: task,
      beforeSave: (_) async {
        attempts += 1;
        if (attempts == 1) throw StateError('Expected toggle failure.');
      },
    );
    await tester.pumpWidget(testApp(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Mark complete'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('task-completion-error')), findsOneWidget);
    expect(find.byTooltip('Mark complete'), findsOneWidget);
    expect(repository.savedTasks, isEmpty);

    await tester.tap(find.byTooltip('Mark complete'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('task-completion-error')), findsNothing);
    expect(repository.savedTasks.single.isCompleted, isTrue);
  });

  testWidgets('completion blocks duplicate requests while saving', (
    tester,
  ) async {
    final task = createTask('task-1', 'One toggle', isCompleted: false);
    final saveStarted = Completer<void>();
    final releaseSave = Completer<void>();
    var attempts = 0;
    final repository = FakeLifeOsTaskRepository(
      () async => [task],
      storedTask: task,
      beforeSave: (_) async {
        attempts += 1;
        saveStarted.complete();
        await releaseSave.future;
      },
    );
    await tester.pumpWidget(testApp(repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Mark complete'));
    await tester.pump();
    await saveStarted.future;
    expect(
      tester
          .widget<IconButton>(find.byKey(const ValueKey('toggle-task-task-1')))
          .onPressed,
      isNull,
    );
    expect(attempts, 1);

    releaseSave.complete();
    await tester.pumpAndSettle();
    expect(repository.savedTasks, hasLength(1));
  });

  testWidgets('Task list load failure exposes a working retry', (tester) async {
    var attempts = 0;
    final repository = FakeLifeOsTaskRepository(() async {
      attempts += 1;
      if (attempts == 1) throw StateError('Expected read failure.');
      return [];
    });
    await tester.pumpWidget(testApp(repository));
    await tester.pumpAndSettle();

    expect(find.text('Unable to load Tasks'), findsOneWidget);
    await tester.tap(find.byKey(const Key('retry-task-list')));
    await tester.pumpAndSettle();
    expect(find.text('No Tasks yet'), findsOneWidget);
    expect(attempts, 2);
  });

  testWidgets('restore failure keeps the Task in Trash and allows retry', (
    tester,
  ) async {
    final deleted = createTask(
      'task-1',
      'Restore retry',
      isCompleted: false,
    ).delete(updatedAt: DateTime.utc(2026, 9, 9, 11));
    var attempts = 0;
    final repository = FakeLifeOsTaskRepository(
      () async => [deleted],
      storedTask: deleted,
      beforeSave: (_) async {
        attempts += 1;
        if (attempts == 1) throw StateError('Expected restore failure.');
      },
    );
    await tester.pumpWidget(testApp(repository));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('task-trash-toggle')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('restore-task-task-1')));
    await tester.pumpAndSettle();
    expect(find.text('Unable to restore Task'), findsOneWidget);
    expect(find.text('Restore retry'), findsOneWidget);
    expect(repository.savedTasks, isEmpty);

    await tester.tap(find.byKey(const ValueKey('restore-task-task-1')));
    await tester.pumpAndSettle();
    expect(find.text('Restore retry'), findsNothing);
    expect(
      repository.savedTasks.single.lifecycle,
      LifeOsEntityLifecycle.active,
    );
  });

  testWidgets('provider refresh clears a stale Task selection', (tester) async {
    final task = createTask('task-1', 'Transient Task', isCompleted: false);
    final source = <LifeOsTask>[task];
    final repository = FakeLifeOsTaskRepository(() async => List.of(source));
    await tester.pumpWidget(testApp(repository));
    await tester.pumpAndSettle();

    await _secondaryTap(tester, find.text('Transient Task'));
    await tester.tapAt(const Offset(790, 590));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<ExpansionTile>(find.byKey(const ValueKey('task-task-1')))
          .backgroundColor,
      isNotNull,
    );

    final container = ProviderScope.containerOf(
      tester.element(find.byType(TaskList)),
    );
    source.clear();
    container.invalidate(taskListControllerProvider);
    await tester.pumpAndSettle();
    source.add(task);
    container.invalidate(taskListControllerProvider);
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<ExpansionTile>(find.byKey(const ValueKey('task-task-1')))
          .backgroundColor,
      isNull,
    );
  });
}

Future<void> _secondaryTap(WidgetTester tester, Finder finder) async {
  await tester.tapAt(tester.getCenter(finder), buttons: kSecondaryMouseButton);
  await tester.pumpAndSettle();
}

Future<void> _pressControlN(WidgetTester tester) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
}

Widget testApp(LifeOsTaskRepository repository) {
  final createTask = CreateLifeOsTask(
    repository: repository,
    entityIdGenerator: () => 'task-created',
    utcClock: () => DateTime.utc(2026, 9, 9, 16),
  );
  final editTaskTitle = EditLifeOsTaskTitle(
    repository: repository,
    utcClock: () => DateTime.utc(2026, 9, 9, 17),
  );
  final deleteTask = DeleteLifeOsTask(
    repository: repository,
    utcClock: () => DateTime.utc(2026, 9, 9, 18),
  );
  final restoreTask = RestoreLifeOsTask(
    repository: repository,
    utcClock: () => DateTime.utc(2026, 9, 9, 19),
  );

  return ProviderScope(
    overrides: [
      lifeOsTaskRepositoryProvider.overrideWithValue(repository),
      createLifeOsTaskProvider.overrideWithValue(createTask),
      editLifeOsTaskTitleProvider.overrideWithValue(editTaskTitle),
      deleteLifeOsTaskProvider.overrideWithValue(deleteTask),
      restoreLifeOsTaskProvider.overrideWithValue(restoreTask),
    ],
    child: const MaterialApp(
      locale: Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: TaskList()),
    ),
  );
}

LifeOsTask createTask(String id, String title, {required bool isCompleted}) {
  return LifeOsTask(
    id: LifeOsEntityId(value: id, entityType: LifeOsEntityType.task),
    title: title,
    isCompleted: isCompleted,
    createdAt: DateTime.utc(2026, 9, 9, 10),
    updatedAt: DateTime.utc(2026, 9, 9, 10),
    lifecycle: LifeOsEntityLifecycle.active,
    version: 1,
    source: LifeOsEntitySource.user,
  );
}

class FakeLifeOsTaskRepository implements LifeOsTaskRepository {
  FakeLifeOsTaskRepository(this._loadTasks, {this.storedTask, this.beforeSave});

  final Future<List<LifeOsTask>> Function() _loadTasks;
  LifeOsTask? storedTask;
  final Future<void> Function(LifeOsTask task)? beforeSave;
  final List<LifeOsTask> savedTasks = [];

  @override
  Future<List<LifeOsTask>> getByLifecycle(
    LifeOsEntityLifecycle lifecycle,
  ) async {
    final values = await getAll();
    final stored = storedTask;
    if (stored != null) {
      values
        ..removeWhere((task) => task.id == stored.id)
        ..add(stored);
    }
    return values.where((task) => task.lifecycle == lifecycle).toList();
  }

  @override
  Future<List<LifeOsTask>> getAll() => _loadTasks();

  @override
  Future<LifeOsTask?> getById(LifeOsEntityId id) async {
    return storedTask?.id == id ? storedTask : null;
  }

  @override
  Future<List<LifeOsTask>> searchByTitle(String query) async => [];

  @override
  Future<void> save(LifeOsTask task) async {
    await beforeSave?.call(task);
    storedTask = task;
    savedTasks.add(task);
  }
}
