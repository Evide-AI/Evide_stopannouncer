import 'dart:ui';

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
                Text(
                  "Device Installed Apps",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20),
                // App list
                Expanded(
                  child: installedApps.isEmpty
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white70,
                          ),
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

                            return GestureDetector(
                              onTap: () async {
                                await InstalledApps.startApp(app.packageName);
                              },
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.white12,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.3),
                                          blurRadius: 5,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: appIcon != null
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            child: Image.memory(
                                              appIcon, // first argument
                                              width: 60,
                                              height: 60,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                    return const Icon(
                                                      Icons.broken_image,
                                                      size: 40,
                                                      color: Colors.white70,
                                                    );
                                                  },
                                            ),
                                          )
                                        : const Icon(
                                            Icons.apps,
                                            color: Colors.white70,
                                            size: 35,
                                          ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    app.name,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
