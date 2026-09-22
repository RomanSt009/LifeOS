import 'package:flutter_riverpod/flutter_riverpod.dart';

final workspaceMemberRevisionProvider =
    NotifierProvider<WorkspaceMemberRevisionController, int>(
      WorkspaceMemberRevisionController.new,
    );

class WorkspaceMemberRevisionController extends Notifier<int> {
  @override
  int build() => 0;

  void advance() => state++;
}
