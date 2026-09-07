import 'package:flutter/material.dart';

import '../../application/use_cases/get_lifeos_identity.dart';

class LifeosShellPage extends StatelessWidget {
  const LifeosShellPage({
    required this.getLifeOsIdentity,
    super.key,
  });

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
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(identity.applicationDescription),
          ],
        ),
      ),
    );
  }
}
