import 'package:flutter/material.dart';

import '../../application/use_cases/get_lifeos_identity.dart';
import '../tasks/task_list.dart';

class LifeosShellPage extends StatelessWidget {
  const LifeosShellPage({required this.getLifeOsIdentity, super.key});

  final GetLifeOsIdentity getLifeOsIdentity;

  @override
  Widget build(BuildContext context) {
    final identity = getLifeOsIdentity();

    return Scaffold(
      appBar: AppBar(title: Text(identity.applicationName)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              identity.applicationName,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(identity.applicationDescription),
            const SizedBox(height: 24),
            const Text('Tasks', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 8),
            const Expanded(child: TaskList()),
          ],
        ),
      ),
    );
  }
}
