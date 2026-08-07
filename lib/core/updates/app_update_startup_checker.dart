import 'dart:async';

import 'package:flutter/material.dart';
import 'package:runearn/core/updates/app_update_service.dart';

class AppUpdateStartupChecker extends StatefulWidget {
  const AppUpdateStartupChecker({
    required this.navigatorKey,
    required this.child,
    super.key,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  @override
  State<AppUpdateStartupChecker> createState() =>
      _AppUpdateStartupCheckerState();
}

class _AppUpdateStartupCheckerState extends State<AppUpdateStartupChecker> {
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_checkForUpdate());
    });
  }

  Future<void> _checkForUpdate() async {
    if (_checked) return;
    _checked = true;

    final result = await AppUpdateService.instance
        .checkAndAutomaticallyUpdate();
    if (!mounted || result != AppUpdateResult.updateAvailable) return;

    final context = widget.navigatorKey.currentContext;
    if (context == null || !context.mounted) return;
    final updateNow = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.system_update_rounded),
        title: const Text('New update available'),
        content: const Text(
          'RunEarn could not download the update automatically. '
          'Would you like to download it now?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Skip'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.download_rounded),
            label: const Text('Download now'),
          ),
        ],
      ),
    );
    if (updateNow != true || !mounted) return;

    final started = await AppUpdateService.instance.updateNow();
    final currentContext = widget.navigatorKey.currentContext;
    if (!started && currentContext != null && currentContext.mounted) {
      ScaffoldMessenger.of(currentContext).showSnackBar(
        const SnackBar(
          content: Text(
            'The update could not be started. Please update from Google Play.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
