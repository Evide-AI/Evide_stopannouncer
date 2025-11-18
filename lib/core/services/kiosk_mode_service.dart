import 'package:evide_stop_announcer_app/core/app_imports.dart';
import 'package:evide_stop_announcer_app/core/services/launch_permission.dart';
import 'package:kiosk_mode/kiosk_mode.dart';

class KioskModeService {
  static Future<void> enableKioskMode() async {
    try {
      await startKioskMode();
      await LauncherPermission.requestSetDefaultLauncher();
      debugPrint("✅ Kiosk mode enabled successfully");
    } catch (e) {
      debugPrint("❌ Error enabling kiosk mode: $e");
    }
  }

  static Future<void> disableKioskMode() async {
    try {
      await stopKioskMode();
      debugPrint("✅ Kiosk mode disabled successfully");
    } catch (e) {
      debugPrint("❌ Error disabling kiosk mode: $e");
    }
  }
}
