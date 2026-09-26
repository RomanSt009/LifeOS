import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/application/search/lifeos_search_result.dart';
import 'package:lifeos/application/search/lifeos_unified_search_reader.dart';
import 'package:lifeos/application/use_cases/search_lifeos_entities.dart';

void main() {
  test('trims a non-empty query and delegates the positive limit', () async {
    final reader = _RecordingReader();

    final results = await SearchLifeOsEntities(reader)(
      '  searchable text  ',
      limit: 50,
    );

    expect(results, isEmpty);
    expect(reader.queries, ['searchable text']);
    expect(reader.limits, [50]);
  });

  for (final query in ['', '   ', '\t\r\n']) {
    test(
      'empty query returns no results without reading persistence',
      () async {
        final reader = _RecordingReader();

        final results = await SearchLifeOsEntities(reader)(query, limit: 50);

        expect(results, isEmpty);
        expect(reader.queries, isEmpty);
      },
    );
  }

  test('rejects a non-positive limit before reading persistence', () {
    final reader = _RecordingReader();

    expect(
      () => SearchLifeOsEntities(reader)('query', limit: 0),
      throwsArgumentError,
    );
    expect(reader.queries, isEmpty);
  });
}

final class _RecordingReader implements LifeOsUnifiedSearchReader {
  final List<String> queries = [];
  final List<int> limits = [];

  @override
  Future<List<LifeOsSearchResult>> search({
    required String query,
    required int limit,
  }) async {
    queries.add(query);
    limits.add(limit);
    return const [];
  }
}
