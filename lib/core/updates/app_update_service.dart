import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

enum AppUpdateResult {
  unsupported,
  upToDate,
  updateInstalled,
  updateAvailable,
  failed,
}

class AppUpdateService {
  AppUpdateService._();

  static final AppUpdateService instance = AppUpdateService._();

  bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<AppUpdateResult> checkAndAutomaticallyUpdate() async {
    if (!isSupported) return AppUpdateResult.unsupported;

    late final AppUpdateInfo info;
    try {
      info = await InAppUpdate.checkForUpdate();
    } catch (_) {
      return AppUpdateResult.failed;
    }
    if (info.updateAvailability != UpdateAvailability.updateAvailable) {
      return AppUpdateResult.upToDate;
    }
    if (!info.flexibleUpdateAllowed) {
      return AppUpdateResult.updateAvailable;
    }
    try {
      await InAppUpdate.startFlexibleUpdate();
      await InAppUpdate.completeFlexibleUpdate();
      return AppUpdateResult.updateInstalled;
    } catch (_) {
      return AppUpdateResult.updateAvailable;
    }
  }

  Future<bool> updateNow() async {
    if (!isSupported) return false;
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability != UpdateAvailability.updateAvailable) {
        return false;
      }
      if (info.immediateUpdateAllowed) {
        await InAppUpdate.performImmediateUpdate();
        return true;
      }
      if (info.flexibleUpdateAllowed) {
        await InAppUpdate.startFlexibleUpdate();
        await InAppUpdate.completeFlexibleUpdate();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
