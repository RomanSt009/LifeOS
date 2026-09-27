import 'dart:ui' show AppExitType;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import 'app.dart';
import 'dependencies.dart';

typedef LifeOsDependenciesFactory = Future<LifeOsAppDependencies> Function();
typedef LifeOsStartupExit = Future<void> Function();

Future<void> exitLifeOsAfterStartupFailure() async {
  await ServicesBinding.instance.exitApplication(AppExitType.required);
}

class LifeOSBootstrap extends StatefulWidget {
  const LifeOSBootstrap({
    this.createDependencies = createProductionDependencies,
    this.exitApplication = exitLifeOsAfterStartupFailure,
    super.key,
  });

  final LifeOsDependenciesFactory createDependencies;
  final LifeOsStartupExit exitApplication;

  @override
  State<LifeOSBootstrap> createState() => _LifeOSBootstrapState();
}

class _LifeOSBootstrapState extends State<LifeOSBootstrap> {
  LifeOsAppDependencies? _dependencies;
  Object? _startupFailure;
  int _attempt = 0;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    final attempt = ++_attempt;
    setState(() => _startupFailure = null);
    try {
      final dependencies = await widget.createDependencies();
      if (!mounted || attempt != _attempt) {
        await dependencies.close();
        return;
      }
      setState(() => _dependencies = dependencies);
    } catch (error) {
      if (!mounted || attempt != _attempt) return;
      setState(() => _startupFailure = error);
    }
  }

  @override
  void dispose() {
    _attempt += 1;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dependencies = _dependencies;
    if (dependencies != null) {
      return LifeOSApp(dependencies: dependencies);
    }
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: resolveLifeOsLocale,
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      home: _startupFailure == null
          ? const _LifeOSStartingPage()
          : _LifeOSStartupFailurePage(
              onRetry: _start,
              onExit: widget.exitApplication,
            ),
    );
  }
}

class _LifeOSStartingPage extends StatelessWidget {
  const _LifeOSStartingPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(key: Key('lifeos-startup-progress')),
      ),
    );
  }
}

class _LifeOSStartupFailurePage extends StatelessWidget {
  const _LifeOSStartupFailurePage({
    required this.onRetry,
    required this.onExit,
  });

  final VoidCallback onRetry;
  final LifeOsStartupExit onExit;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                localizations.startupFailureTitle,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                localizations.startupFailureMessage,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  OutlinedButton(
                    key: const Key('startup-exit-button'),
                    onPressed: onExit,
                    child: Text(localizations.exitApplicationAction),
                  ),
                  FilledButton(
                    key: const Key('startup-retry-button'),
                    onPressed: onRetry,
                    child: Text(localizations.retryAction),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
