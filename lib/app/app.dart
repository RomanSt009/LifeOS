import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/use_cases/get_lifeos_identity.dart';
import '../presentation/shell/lifeos_shell_page.dart';

class LifeOSApp extends StatelessWidget {
  const LifeOSApp({super.key});

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
