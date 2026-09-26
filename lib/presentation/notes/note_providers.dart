import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/use_cases/create_lifeos_note.dart';
import '../../application/use_cases/edit_lifeos_note.dart';
import '../../application/use_cases/delete_lifeos_note.dart';
import '../../application/use_cases/restore_lifeos_note.dart';
import '../../application/use_cases/get_lifeos_notes.dart';
import '../../domain/entities/lifeos_entity.dart';
import '../../domain/entities/lifeos_note.dart';
import '../../domain/repositories/lifeos_note_repository.dart';
import '../relationships/relationship_providers.dart';
import '../workspaces/workspace_member_refresh.dart';

final lifeOsNoteRepositoryProvider = Provider<LifeOsNoteRepository>((ref) {
  throw UnimplementedError(
    'lifeOsNoteRepositoryProvider must be overridden by app composition.',
  );
});

final createLifeOsNoteProvider = Provider<CreateLifeOsNote>((ref) {
  throw UnimplementedError(
    'createLifeOsNoteProvider must be overridden by app composition.',
  );
});

final editLifeOsNoteProvider = Provider<EditLifeOsNote>((ref) {
  throw UnimplementedError(
    'editLifeOsNoteProvider must be overridden by app composition.',
  );
});

final deleteLifeOsNoteProvider = Provider<DeleteLifeOsNote>((ref) {
  throw UnimplementedError(
    'deleteLifeOsNoteProvider must be overridden by app composition.',
  );
});

final restoreLifeOsNoteProvider = Provider<RestoreLifeOsNote>((ref) {
  throw UnimplementedError(
    'restoreLifeOsNoteProvider must be overridden by app composition.',
  );
});

final getLifeOsNotesProvider = Provider<GetLifeOsNotes>((ref) {
  return GetLifeOsNotes(ref.watch(lifeOsNoteRepositoryProvider));
});

final getDeletedLifeOsNotesProvider = Provider<GetDeletedLifeOsNotes>((ref) {
  return GetDeletedLifeOsNotes(ref.watch(lifeOsNoteRepositoryProvider));
});

final noteListControllerProvider =
    AsyncNotifierProvider<NoteListController, List<LifeOsNote>>(
      NoteListController.new,
    );

class NoteListController extends AsyncNotifier<List<LifeOsNote>> {
  @override
  Future<List<LifeOsNote>> build() => ref.watch(getLifeOsNotesProvider)();

  Future<LifeOsNote> create({
    required String title,
    required String content,
  }) async {
    final note = await ref.read(createLifeOsNoteProvider)(
      title: title,
      content: content,
    );
    state = AsyncData(_sorted([...state.requireValue, note]));
    return note;
  }

  Future<LifeOsNote?> edit(
    LifeOsEntityId id, {
    required String title,
    required String content,
  }) async {
    final note = await ref.read(editLifeOsNoteProvider)(
      id,
      title: title,
      content: content,
    );
    if (note != null) {
      state = AsyncData(
        _sorted([
          for (final current in state.requireValue)
            if (current.id == id) note else current,
        ]),
      );
      ref.invalidate(directLifeOsRelatedNeighborsProvider);
    }
    return note;
  }

  Future<void> delete(LifeOsEntityId id) async {
    final deleted = await ref.read(deleteLifeOsNoteProvider)(id);
    if (deleted == null) {
      throw StateError('The selected Note no longer exists.');
    }
    state = AsyncData([
      for (final note in state.requireValue)
        if (note.id != id) note,
    ]);
    ref.invalidate(noteTrashControllerProvider);
    ref.invalidate(directLifeOsRelatedNeighborsProvider);
    ref.read(workspaceMemberRevisionProvider.notifier).advance();
  }
}

final noteTrashControllerProvider =
    AsyncNotifierProvider<NoteTrashController, List<LifeOsNote>>(
      NoteTrashController.new,
    );

class NoteTrashController extends AsyncNotifier<List<LifeOsNote>> {
  @override
  Future<List<LifeOsNote>> build() =>
      ref.watch(getDeletedLifeOsNotesProvider)();

  Future<void> restore(LifeOsEntityId id) async {
    final restored = await ref.read(restoreLifeOsNoteProvider)(id);
    if (restored == null) {
      throw StateError('The selected Note no longer exists.');
    }
    state = AsyncData([
      for (final note in state.requireValue)
        if (note.id != id) note,
    ]);
    ref.invalidate(noteListControllerProvider);
    ref.invalidate(directLifeOsRelatedNeighborsProvider);
    ref.read(workspaceMemberRevisionProvider.notifier).advance();
  }
}

List<LifeOsNote> _sorted(List<LifeOsNote> notes) {
  notes.sort((first, second) {
    final timestamp = second.updatedAt.compareTo(first.updatedAt);
    return timestamp != 0
        ? timestamp
        : first.id.value.compareTo(second.id.value);
  });
  return notes;
}
