import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/application/use_cases/search_lifeos_tasks.dart';
import 'package:lifeos/domain/entities/lifeos_entity.dart';
import 'package:lifeos/domain/entities/lifeos_task.dart';
import 'package:lifeos/domain/repositories/lifeos_task_repository.dart';

void main() {
  final task = LifeOsTask(
    id: const LifeOsEntityId(
      value: 'task-search-result',
      entityType: LifeOsEntityType.task,
    ),
    title: 'Search Tasks locally',
    isCompleted: false,
    createdAt: DateTime.utc(2026, 9, 10, 10),
    updatedAt: DateTime.utc(2026, 9, 10, 11),
    lifecycle: LifeOsEntityLifecycle.active,
    version: 1,
    source: LifeOsEntitySource.user,
  );

  test('passes a normalized query and returns Domain Tasks', () async {
    final repository = StubLifeOsTaskRepository([task]);

    final result = await SearchLifeOsTasks(repository)('  Tasks locally  ');

    expect(repository.queries, ['Tasks locally']);
    expect(result, same(repository.results));
    expect(result, everyElement(isA<LifeOsTask>()));
  });

  for (final query in ['', '   ', '\t\r\n']) {
    test(
      'returns no results without querying the repository for "$query"',
      () async {
        final repository = StubLifeOsTaskRepository([task]);

        final result = await SearchLifeOsTasks(repository)(query);

        expect(result, isEmpty);
        expect(repository.queries, isEmpty);
      },
    );
  }
}

class StubLifeOsTaskRepository implements LifeOsTaskRepository {
  StubLifeOsTaskRepository(this.results);

  final List<LifeOsTask> results;
  final List<String> queries = [];

  @override
  Future<List<LifeOsTask>> getAll() async => [];

  @override
  Future<LifeOsTask?> getById(LifeOsEntityId id) async => null;

  @override
  Future<List<LifeOsTask>> searchByTitle(String query) async {
    queries.add(query);
    return results;
  }

  @override
  Future<void> save(LifeOsTask task) async {}
}
