import 'package:evide_stop_announcer_app/core/app_imports.dart';
import 'package:flutter/services.dart';

class LauncherPermission {
  static const platform = MethodChannel('launcher_channel');

  // Check if app is default launcher
  static Future<bool> isDefaultLauncher() async {
    try {
      final bool? result = await platform.invokeMethod('isDefaultLauncher');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint("Error checking launcher: ${e.message}");
      return false;
    }
  }

  // Request user to set app as default
  static Future<void> requestSetDefaultLauncher() async {
    try {
      // await platform.invokeMethod('requestSetDefaultLauncher');
      bool newStatus = await isDefaultLauncher();
      if (!newStatus) {
        await platform.invokeMethod('requestSetDefaultLauncher');
      }
      await platform.invokeMethod('requestSetDefaultLauncher');
    } on PlatformException catch (e) {
      debugPrint("Failed to open launcher chooser: ${e.message}");
    }
  }
}