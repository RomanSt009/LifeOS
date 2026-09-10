import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/lifeos_task.dart';
import '../../l10n/app_localizations.dart';
import 'task_search_providers.dart';

class TaskSearchPage extends ConsumerStatefulWidget {
  const TaskSearchPage({super.key});

  @override
  ConsumerState<TaskSearchPage> createState() => _TaskSearchPageState();
}

class _TaskSearchPageState extends ConsumerState<TaskSearchPage> {
  final _queryController = TextEditingController();
  AsyncValue<List<LifeOsTask>>? _searchResult;
  int _latestSearchRequest = 0;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final request = ++_latestSearchRequest;
    final query = _queryController.text;
    setState(() => _searchResult = const AsyncLoading());

    final result = await AsyncValue.guard(
      () => ref.read(searchLifeOsTasksProvider)(query),
    );
    if (mounted && request == _latestSearchRequest) {
      setState(() => _searchResult = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.searchTitle,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  key: const Key('search-query-field'),
                  controller: _queryController,
                  decoration: InputDecoration(
                    labelText: localizations.searchQueryFieldLabel,
                  ),
                  onSubmitted: (_) => _search(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                key: const Key('search-submit-button'),
                onPressed: _search,
                child: Text(localizations.searchAction),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _SearchContent(searchResult: _searchResult),
          ),
        ],
      ),
    );
  }
}

class _SearchContent extends StatelessWidget {
  const _SearchContent({required this.searchResult});

  final AsyncValue<List<LifeOsTask>>? searchResult;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final result = searchResult;
    if (result == null) {
      return Center(child: Text(localizations.searchInitial));
    }

    return result.when(
      data: (tasks) {
        if (tasks.isEmpty) {
          return Center(child: Text(localizations.searchNoResults));
        }

        return ListView.builder(
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            return ListTile(
              key: ValueKey('search-result-${task.id.value}'),
              leading: Icon(
                task.isCompleted
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
              ),
              title: Text(
                task.title,
                style: task.isCompleted
                    ? const TextStyle(decoration: TextDecoration.lineThrough)
                    : null,
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) =>
          Center(child: Text(localizations.searchError)),
    );
  }
}
