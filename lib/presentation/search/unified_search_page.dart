import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/search/lifeos_search_result.dart';
import '../../domain/entities/lifeos_entity.dart';
import '../../l10n/app_localizations.dart';
import 'unified_search_providers.dart';

class UnifiedSearchPage extends ConsumerStatefulWidget {
  const UnifiedSearchPage({
    required this.onOpenTask,
    required this.onOpenNote,
    required this.onOpenWorkspace,
    super.key,
  });

  final ValueChanged<LifeOsEntityId> onOpenTask;
  final ValueChanged<LifeOsEntityId> onOpenNote;
  final ValueChanged<LifeOsEntityId> onOpenWorkspace;

  @override
  ConsumerState<UnifiedSearchPage> createState() => _UnifiedSearchPageState();
}

class _UnifiedSearchPageState extends ConsumerState<UnifiedSearchPage> {
  static const _resultLimit = 50;

  final _queryController = TextEditingController();
  final _queryFocusNode = FocusNode(debugLabel: 'Unified Search query');
  AsyncValue<List<LifeOsSearchResult>>? _searchResult;
  int _latestSearchRequest = 0;

  @override
  void dispose() {
    _queryController.dispose();
    _queryFocusNode.dispose();
    super.dispose();
  }

  void _clear() {
    _latestSearchRequest += 1;
    _queryController.clear();
    setState(() => _searchResult = null);
    _queryFocusNode.requestFocus();
  }

  Future<void> _search() async {
    final request = ++_latestSearchRequest;
    final query = _queryController.text;
    if (query.trim().isEmpty) {
      setState(() => _searchResult = null);
      return;
    }

    setState(() => _searchResult = const AsyncLoading());
    final result = await AsyncValue.guard(
      () => ref.read(searchLifeOsEntitiesProvider)(query, limit: _resultLimit),
    );
    if (mounted && request == _latestSearchRequest) {
      setState(() => _searchResult = result);
    }
  }

  void _open(LifeOsSearchResult result) {
    switch (result) {
      case LifeOsTaskSearchResult():
        widget.onOpenTask(result.entityId);
      case LifeOsNoteSearchResult():
        widget.onOpenNote(result.entityId);
      case LifeOsWorkspaceSearchResult():
        widget.onOpenWorkspace(result.entityId);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(unifiedSearchRevisionProvider, (previous, next) {
      if (previous == null || previous == next) return;
      _latestSearchRequest += 1;
      _queryController.clear();
      if (mounted) setState(() => _searchResult = null);
    });
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
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _queryController,
                  builder: (context, value, _) => TextField(
                    key: const Key('search-query-field'),
                    controller: _queryController,
                    focusNode: _queryFocusNode,
                    decoration: InputDecoration(
                      labelText: localizations.searchQueryFieldLabel,
                      suffixIcon: value.text.isEmpty
                          ? null
                          : IconButton(
                              key: const Key('search-clear-button'),
                              tooltip: localizations.searchClearAction,
                              onPressed: _clear,
                              icon: Icon(
                                Icons.clear,
                                semanticLabel: localizations.searchClearAction,
                              ),
                            ),
                    ),
                    onSubmitted: (_) => _search(),
                  ),
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
            child: _SearchContent(searchResult: _searchResult, onOpen: _open),
          ),
        ],
      ),
    );
  }
}

class _SearchContent extends StatelessWidget {
  const _SearchContent({required this.searchResult, required this.onOpen});

  final AsyncValue<List<LifeOsSearchResult>>? searchResult;
  final ValueChanged<LifeOsSearchResult> onOpen;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final result = searchResult;
    if (result == null) {
      return Center(child: Text(localizations.searchInitial));
    }

    return result.when(
      data: (results) {
        if (results.isEmpty) {
          return Center(child: Text(localizations.searchNoResults));
        }

        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final result = results[index];
            return _SearchResultTile(
              result: result,
              onTap: () => onOpen(result),
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

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({required this.result, required this.onTap});

  final LifeOsSearchResult result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final (icon, title, typeLabel, preview, completed) = switch (result) {
      LifeOsTaskSearchResult(:final task) => (
        task.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
        task.title,
        localizations.searchResultTaskType,
        null,
        task.isCompleted,
      ),
      LifeOsNoteSearchResult(:final note) => (
        Icons.notes_outlined,
        note.title.isEmpty ? localizations.noteUntitled : note.title,
        localizations.searchResultNoteType,
        _compactPreview(note.content),
        false,
      ),
      LifeOsWorkspaceSearchResult(:final workspace) => (
        Icons.workspaces_outlined,
        workspace.title,
        localizations.searchResultWorkspaceType,
        workspace.description == null
            ? null
            : _compactPreview(workspace.description!),
        false,
      ),
    };

    return ListTile(
      key: ValueKey(
        'search-result-${result.entityType.name}-${result.entityId.value}',
      ),
      leading: Icon(icon),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: completed
            ? const TextStyle(decoration: TextDecoration.lineThrough)
            : null,
      ),
      subtitle: Text(
        preview == null || preview.isEmpty
            ? typeLabel
            : '$typeLabel · $preview',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: onTap,
    );
  }
}

String _compactPreview(String value) =>
    value.trim().replaceAll(RegExp(r'\s+'), ' ');
