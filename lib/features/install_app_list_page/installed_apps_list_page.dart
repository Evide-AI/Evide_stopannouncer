import 'dart:typed_data';
import 'dart:ui';

import 'package:evide_stop_announcer_app/core/services/kiosk_mode_service.dart';
import 'package:evide_stop_announcer_app/features/install_app_list_page/widgets/installed_app_widget.dart';
import 'package:flutter/material.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';

class InstalledAppsListPage extends StatelessWidget {
  const InstalledAppsListPage({super.key, required this.installedApps});
  final List<AppInfo> installedApps;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Background gradient
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color.fromARGB(255, 125, 164, 236),
                    Color(0xFF243B55),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),

            // Frosted glass overlay
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(color: Colors.white.withOpacity(0.05)),
            ),
            // Main content
            Column(
              children: [
                SizedBox(height: 20),
                // AppBar
                Row(
                  children: [
                    IconButton(onPressed: () {
                      Navigator.pop(context);
                    }, icon: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white,)),
                    Text(
                      "Device Installed Apps",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                // App list
                Expanded(
                  child: installedApps.isEmpty
                      ? const Center(
                          child: Text("Fetching Apps...."),
                        )
                      : GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 6, // More compact like macOS
                                mainAxisSpacing: 15,
                                crossAxisSpacing: 15,
                                childAspectRatio: 0.85, // Square-ish cards
                              ),
                          padding: const EdgeInsets.symmetric(horizontal: 30,vertical: 20),
                          physics: const BouncingScrollPhysics(),
                          itemCount: installedApps.length,
                          itemBuilder: (context, index) {
                            final app = installedApps[index];
                            final appIcon = app.icon;

                            return InstalledAppWidget(app: app, appIcon: appIcon);
                          },
                        ),
                ),
              ],
            ),
          ],
        ),
        floatingActionButton: TextButton(
              onPressed: () {
                // For testing: Skip to next video
                KioskModeService.disableKioskMode();
              },
              child: Text(
                "Exit Kiosk Mode",
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
      ),
    );
  }
}