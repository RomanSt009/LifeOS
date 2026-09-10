import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

class HomePlaceholder extends StatelessWidget {
  const HomePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        AppLocalizations.of(context).navigationHome,
        key: const Key('home-placeholder-title'),
        style: Theme.of(context).textTheme.headlineMedium,
      ),
    );
  }
}
