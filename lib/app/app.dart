import 'dart:async';
import 'dart:ui' show AppExitResponse;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/use_cases/get_lifeos_identity.dart';
import '../presentation/shell/lifeos_shell_page.dart';
import 'dependencies.dart';

class LifeOSApp extends StatefulWidget {
  const LifeOSApp({required this.dependencies, super.key});

  final LifeOsAppDependencies dependencies;

  @override
  State<LifeOSApp> createState() => _LifeOSAppState();
}

class _LifeOSAppState extends State<LifeOSApp> {
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(
      onExitRequested: () async {
        await widget.dependencies.close();
        return AppExitResponse.exit;
      },
    );
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    unawaited(widget.dependencies.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        title: 'LifeOS',
        theme: ThemeData(colorSchemeSeed: Colors.indigo),
        home: const LifeosShellPage(getLifeOsIdentity: GetLifeOsIdentity()),
      ),
    );
  }
}
