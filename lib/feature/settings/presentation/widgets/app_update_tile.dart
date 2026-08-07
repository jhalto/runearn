import 'package:flutter/material.dart';
import 'package:runearn/core/updates/app_update_service.dart';

class AppUpdateTile extends StatefulWidget {
  const AppUpdateTile({super.key});

  @override
  State<AppUpdateTile> createState() => _AppUpdateTileState();
}

class _AppUpdateTileState extends State<AppUpdateTile> {
  bool _checking = false;

  Future<void> _checkForUpdate() async {
    if (_checking) return;
    setState(() => _checking = true);

    final result = await AppUpdateService.instance
        .checkAndAutomaticallyUpdate();
    if (!mounted) return;
    setState(() => _checking = false);

    switch (result) {
      case AppUpdateResult.upToDate:
        _showMessage('RunEarn is up to date.');
        return;
      case AppUpdateResult.updateInstalled:
        _showMessage('Update downloaded. RunEarn will finish installing it.');
        return;
      case AppUpdateResult.unsupported:
        _showMessage(
          'Automatic update checking is available for the Google Play version.',
        );
        return;
      case AppUpdateResult.failed:
        _showMessage(
          'Could not check for updates. Check your connection and try again.',
        );
        return;
      case AppUpdateResult.updateAvailable:
        await _showUpdateFallback();
        return;
    }
  }

  Future<void> _showUpdateFallback() async {
    final updateNow = await showDialog<bool>(
      context: context,
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

    setState(() => _checking = true);
    final started = await AppUpdateService.instance.updateNow();
    if (!mounted) return;
    setState(() => _checking = false);
    if (!started) {
      _showMessage(
        'The update could not be started. Please update from Google Play.',
      );
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.system_update_alt_rounded),
      title: const Text('Check for updates'),
      subtitle: const Text('Download the latest Google Play version'),
      trailing: _checking
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.chevron_right_rounded),
      enabled: !_checking,
      onTap: _checkForUpdate,
    );
  }
}
