import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

class HomePlaceholder extends StatelessWidget {
  const HomePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            localizations.appTitle,
            key: const Key('home-placeholder-title'),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          Text(
            localizations.homeAlphaDescription,
            key: const Key('home-alpha-description'),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
