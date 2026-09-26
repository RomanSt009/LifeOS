import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/application/search/lifeos_search_result.dart';
import 'package:lifeos/application/search/lifeos_unified_search_reader.dart';
import 'package:lifeos/application/use_cases/search_lifeos_entities.dart';
import 'package:lifeos/domain/entities/lifeos_entity.dart';
import 'package:lifeos/domain/entities/lifeos_note.dart';
import 'package:lifeos/domain/entities/lifeos_task.dart';
import 'package:lifeos/domain/entities/lifeos_workspace.dart';
import 'package:lifeos/l10n/app_localizations.dart';
import 'package:lifeos/presentation/search/unified_search_page.dart';
import 'package:lifeos/presentation/search/unified_search_providers.dart';

void main() {
  testWidgets(
    'shows localized initial and empty-query states without reading',
    (tester) async {
      final reader = StubUnifiedSearchReader();
      await tester.pumpWidget(searchTestApp(reader));

      expect(find.text('Search Tasks, Notes, and Workspaces'), findsOneWidget);
      expect(
        find.text('Enter text to search your local content'),
        findsOneWidget,
      );

      await tester.enterText(
        find.byKey(const Key('search-query-field')),
        '   ',
      );
      await tester.tap(find.byKey(const Key('search-submit-button')));
      await tester.pump();

      expect(reader.queries, isEmpty);
      expect(
        find.text('Enter text to search your local content'),
        findsOneWidget,
      );
    },
  );

  testWidgets('preserves mixed order, renders typed rows, and opens typed IDs', (
    tester,
  ) async {
    final taskResult = LifeOsTaskSearchResult(task(completed: true));
    final noteResult = LifeOsNoteSearchResult(note());
    final workspaceResult = LifeOsWorkspaceSearchResult(workspace());
    final reader = StubUnifiedSearchReader(
      results: [taskResult, noteResult, workspaceResult],
    );
    final opened = <LifeOsEntityId>[];
    await tester.pumpWidget(searchTestApp(reader, opened: opened));

    await search(tester, '  shared  ');
    await tester.pumpAndSettle();

    expect(reader.queries, [('shared', 50)]);
    expect(find.text('Completed Task'), findsOneWidget);
    expect(find.text('Task'), findsOneWidget);
    expect(find.text('Note title'), findsOneWidget);
    expect(find.text('Note · First line second line'), findsOneWidget);
    expect(find.text('Personal'), findsOneWidget);
    expect(find.text('Workspace · Personal context'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Completed Task')).dy,
      lessThan(tester.getTopLeft(find.text('Note title')).dy),
    );
    expect(
      tester.getTopLeft(find.text('Note title')).dy,
      lessThan(tester.getTopLeft(find.text('Personal')).dy),
    );
    expect(
      tester.widget<Text>(find.text('Completed Task')).style?.decoration,
      TextDecoration.lineThrough,
    );

    for (final result in [taskResult, noteResult, workspaceResult]) {
      await tester.tap(
        find.byKey(
          ValueKey(
            'search-result-${result.entityType.name}-${result.entityId.value}',
          ),
        ),
      );
    }
    expect(opened, [
      taskResult.entityId,
      noteResult.entityId,
      workspaceResult.entityId,
    ]);
  });

  testWidgets(
    'shows loading, no-results, recoverable error, and newest result',
    (tester) async {
      final pending = <String, Completer<List<LifeOsSearchResult>>>{};
      final reader = StubUnifiedSearchReader(
        onSearch: (query, limit) =>
            (pending[query] ??= Completer<List<LifeOsSearchResult>>()).future,
      );
      await tester.pumpWidget(searchTestApp(reader));

      await search(tester, 'old');
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await search(tester, 'new');
      pending['new']!.complete([LifeOsTaskSearchResult(task())]);
      await tester.pumpAndSettle();
      expect(find.text('Completed Task'), findsOneWidget);

      pending['old']!.completeError(StateError('private stale failure'));
      await tester.pumpAndSettle();
      expect(find.text('Completed Task'), findsOneWidget);
      expect(find.text('Unable to search local content'), findsNothing);

      await search(tester, 'failure');
      pending['failure']!.completeError(StateError('private current failure'));
      await tester.pumpAndSettle();
      expect(find.text('Unable to search local content'), findsOneWidget);
      expect(find.textContaining('private current failure'), findsNothing);

      await search(tester, 'none');
      pending['none']!.complete(const []);
      await tester.pumpAndSettle();
      expect(find.text('No results found'), findsOneWidget);
    },
  );

  testWidgets('clear invalidates an in-flight result and restores focus', (
    tester,
  ) async {
    final pending = Completer<List<LifeOsSearchResult>>();
    final reader = StubUnifiedSearchReader(
      onSearch: (query, limit) => pending.future,
    );
    await tester.pumpWidget(searchTestApp(reader));

    await search(tester, 'pending');
    await tester.tap(find.byKey(const Key('search-clear-button')));
    await tester.pump();
    pending.complete([LifeOsTaskSearchResult(task())]);
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(
      find.byKey(const Key('search-query-field')),
    );
    expect(field.controller?.text, isEmpty);
    expect(field.focusNode?.hasFocus, isTrue);
    expect(
      find.text('Enter text to search your local content'),
      findsOneWidget,
    );
    expect(find.text('Completed Task'), findsNothing);
  });

  testWidgets('activates a result from the desktop keyboard focus order', (
    tester,
  ) async {
    final result = LifeOsTaskSearchResult(task());
    final opened = <LifeOsEntityId>[];
    await tester.pumpWidget(
      searchTestApp(StubUnifiedSearchReader(results: [result]), opened: opened),
    );
    await search(tester, 'task');
    await tester.pumpAndSettle();

    for (var index = 0; index < 3; index += 1) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(opened, [result.entityId]);
  });

  testWidgets('localizes Unified Search type markers in Russian', (
    tester,
  ) async {
    final reader = StubUnifiedSearchReader(
      results: [
        LifeOsTaskSearchResult(task()),
        LifeOsNoteSearchResult(note()),
        LifeOsWorkspaceSearchResult(workspace()),
      ],
    );
    await tester.pumpWidget(searchTestApp(reader, locale: const Locale('ru')));
    await search(tester, 'данные');
    await tester.pumpAndSettle();

    expect(find.text('Задача'), findsOneWidget);
    expect(find.text('Заметка · First line second line'), findsOneWidget);
    expect(
      find.text('Рабочее пространство · Personal context'),
      findsOneWidget,
    );
  });
}

Future<void> search(WidgetTester tester, String query) async {
  await tester.enterText(find.byKey(const Key('search-query-field')), query);
  await tester.tap(find.byKey(const Key('search-submit-button')));
  await tester.pump();
}

Widget searchTestApp(
  StubUnifiedSearchReader reader, {
  Locale locale = const Locale('en'),
  List<LifeOsEntityId>? opened,
}) {
  return ProviderScope(
    overrides: [
      searchLifeOsEntitiesProvider.overrideWithValue(
        SearchLifeOsEntities(reader),
      ),
    ],
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: UnifiedSearchPage(
          onOpenTask: (id) => opened?.add(id),
          onOpenNote: (id) => opened?.add(id),
          onOpenWorkspace: (id) => opened?.add(id),
        ),
      ),
    ),
  );
}

LifeOsTask task({bool completed = true}) {
  var value = LifeOsTask.createUserTask(
    id: const LifeOsEntityId(
      value: 'task-1',
      entityType: LifeOsEntityType.task,
    ),
    title: 'Completed Task',
    timestamp: DateTime.utc(2026, 9, 26, 10),
  );
  if (completed) {
    value = value.toggleCompletion(updatedAt: DateTime.utc(2026, 9, 26, 11));
  }
  return value;
}

LifeOsNote note() => LifeOsNote.createUserNote(
  id: const LifeOsEntityId(value: 'note-1', entityType: LifeOsEntityType.note),
  title: 'Note title',
  content: '  First line\n\nsecond line  ',
  timestamp: DateTime.utc(2026, 9, 26, 9),
);

LifeOsWorkspace workspace() => LifeOsWorkspace.createUserWorkspace(
  id: const LifeOsEntityId(
    value: 'workspace-1',
    entityType: LifeOsEntityType.workspace,
  ),
  title: 'Personal',
  description: 'Personal context',
  timestamp: DateTime.utc(2026, 9, 26, 8),
);

class StubUnifiedSearchReader implements LifeOsUnifiedSearchReader {
  StubUnifiedSearchReader({this.results = const [], this.onSearch});

  final List<LifeOsSearchResult> results;
  final Future<List<LifeOsSearchResult>> Function(String query, int limit)?
  onSearch;
  final List<(String, int)> queries = [];

  @override
  Future<List<LifeOsSearchResult>> search({
    required String query,
    required int limit,
  }) {
    queries.add((query, limit));
    return onSearch?.call(query, limit) ?? Future.value(results);
  }
}
