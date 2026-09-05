import 'package:flutter/material.dart';

import '../presentation/shell/lifeos_shell_page.dart';

class LifeOSApp extends StatelessWidget {
  const LifeOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LifeOS',
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      home: const LifeosShellPage(),
    );
  }
}
