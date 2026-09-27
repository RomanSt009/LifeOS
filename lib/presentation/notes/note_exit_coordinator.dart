import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef LifeOsNoteExitHandler = Future<bool> Function();

final lifeOsNoteExitCoordinatorProvider = Provider<LifeOsNoteExitCoordinator>((
  ref,
) {
  return LifeOsNoteExitCoordinator();
});

/// Connects the app-exit request to the single mounted Note editor.
///
/// This is deliberately Note-specific presentation coordination. It does not
/// persist drafts or define a generic unsaved-state architecture.
class LifeOsNoteExitCoordinator {
  Object? _owner;
  LifeOsNoteExitHandler? _handler;
  Future<bool>? _closeRequest;

  void attach(Object owner, LifeOsNoteExitHandler handler) {
    assert(
      _owner == null || identical(_owner, owner),
      'Only one Note editor can own the app-exit guard.',
    );
    _owner = owner;
    _handler = handler;
  }

  void detach(Object owner) {
    if (!identical(_owner, owner)) return;
    _owner = null;
    _handler = null;
    _closeRequest = null;
  }

  Future<bool> requestClose() {
    return _closeRequest ??= _resolveCloseRequest();
  }

  Future<bool> _resolveCloseRequest() async {
    final handler = _handler;
    if (handler == null) {
      _closeRequest = null;
      return true;
    }
    try {
      return await handler();
    } finally {
      _closeRequest = null;
    }
  }
}
