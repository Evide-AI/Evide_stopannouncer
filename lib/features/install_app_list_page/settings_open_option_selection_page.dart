import 'package:evide_stop_announcer_app/core/app_imports.dart';
import 'package:evide_stop_announcer_app/core/services/kiosk_mode_service.dart';

class SettingsOpenOptionSelectionPage extends StatelessWidget {
  const SettingsOpenOptionSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Settings",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ElevatedButton(
            onPressed: () async {
              await KioskModeService.disableKioskMode();
              AppCommonMethods.openSystemSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.kAppPrimaryColor,
              foregroundColor: AppColors.kWhite,
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 30),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 4,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.settings, size: 28),
                SizedBox(width: 12),
                Text(
                  "Open System Settings",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
