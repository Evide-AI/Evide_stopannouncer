import 'dart:math';
import 'dart:developer' as dev;
import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:dio/dio.dart';
import 'package:evide_stop_announcer_app/core/app_imports.dart';
import 'package:evide_stop_announcer_app/core/services/api_service.dart';
import 'package:evide_stop_announcer_app/core/services/service_locator.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:evide_stop_announcer_app/core/services/shared_prefs_services.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
class AppCommonMethods {
  static final _rnd = Random.secure();

  static String generateSecretCode() {
    // Generate a 6-digit numeric code (100000 - 999999)
    final code = 100000 + _rnd.nextInt(900000);

    // Optionally add milliseconds-based offset to reduce collisions
    final uniqueOffset = DateTime.now().millisecondsSinceEpoch % 1000;

    // Mix both and ensure only 6 digits
    final uniqueCode = ((code + uniqueOffset) % 1000000).toString().padLeft(6, '0');

    return uniqueCode;
  }

  static const videoExtensions = [
    ".mp4", ".webm", ".mov", ".mkv", ".avi", ".flv",
    ".wmv", ".3gp", ".m4v", ".ts", ".ogv",
  ];

  // commonSnackbar method
  static void commonSnackbar({required BuildContext context, required String message}) {
    final snackBar = SnackBar(
      backgroundColor: AppColors.kTransparent,
      elevation: 0,
      content: Text(
        message,
        textAlign: TextAlign.center, // Center align the text
        style: AppCommonStyles.commonTextStyle(
          fontSize: 10.sp,
          color: AppColors.kWhite,
        ),
      ),
      duration: Duration(seconds: 1),
      behavior: SnackBarBehavior.floating, // Makes it floating
      margin: EdgeInsets.only(
        left: 20, // Add some horizontal margin
        right: 20,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10), // Rounded corners
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }


  static Future<List<AppInfo>> getAllInstalledApps() async {
    List<AppInfo> apps = await InstalledApps.getInstalledApps(
      excludeSystemApps: false,
      excludeNonLaunchableApps: false,
      withIcon: true,
    );
    return apps;
  }



  static Future<void> openSystemSettings() async {
    try {
      // --- 1. Try opening Android TV Settings (most common TV devices)
      const tvIntent = AndroidIntent(
        action: 'android.intent.action.MAIN',
        category: 'android.intent.category.LAUNCHER',
        package: 'com.android.tv.settings',
        componentName: 'com.android.tv.settings.MainSettings',
      );
      await tvIntent.launch();
      return;
    } catch (_) {}

    try {
      // --- 2. Try opening generic TV Settings Activity
      const tvIntentAlt = AndroidIntent(
        action: 'android.intent.action.MAIN',
        package: 'com.android.tv.settings',
        componentName: 'com.android.tv.settings.SettingsActivity',
      );
      await tvIntentAlt.launch();
      return;
    } catch (_) {}

    try {
      // --- 3. Try opening regular Android Settings (works on ALL devices)
      const standardIntent = AndroidIntent(
        action: 'android.settings.SETTINGS',
      );
      await standardIntent.launch();
      return;
    } catch (_) {}

    // --- 4. Final fallback: Open app details as last resort
    const fallbackIntent = AndroidIntent(
      action: 'android.settings.APPLICATION_DETAILS_SETTINGS',
      data: 'package:android',
    );
    await fallbackIntent.launch();
  }

static Future<List<String>> downloadVideosToLocal(List<String> urls) async {
  final apiService = serviceLocator<ApiService>();
  if (urls.isEmpty) return [];

  final appDir = await getApplicationDocumentsDirectory();
  final downloadDir = Directory("${appDir.path}/downloaded_videos");

  /// Create folder if not exists
  if (!await downloadDir.exists()) {
    await downloadDir.create(recursive: true);
  }

  /// -------------------------
  /// 1. Extract file names from URLs
  /// -------------------------
  List<String> firebaseFileNames = urls.map((url) {
    final decoded = Uri.decodeFull(url); // decode %2F etc.
    final fileName = decoded.split("/").last.split("?").first; // atless.mp4
    return fileName;
  }).toList();

  dev.log("FirebaseFileNames: $firebaseFileNames");

  /// -------------------------
  /// 2. Delete local files not present in Firebase URLs
  /// -------------------------
  final localFiles = downloadDir.listSync();
  dev.log("localFiles: $localFiles");

  for (var file in localFiles) {
    if (file is File) {
      final name = file.uri.pathSegments.last;

      // If file not in Firebase list → delete it
      if (!firebaseFileNames.contains(name)) {
        await file.delete();
      }
    }
  }

  /// -------------------------
  /// 3. Download videos
  /// -------------------------
  List<String> savedPaths = [];

  for (int i = 0; i < urls.length; i++) {
    final url = urls[i];

    final decoded = Uri.decodeFull(url);
    final fileName = decoded.split("/").last.split("?").first;

    // Only process valid video extensions
    final ext = fileName.substring(fileName.lastIndexOf("."));
    if (!videoExtensions.contains(ext.toLowerCase())) continue;

    final savePath = "${downloadDir.path}/$fileName";
    final savedFile = File(savePath);

    // Skip download if file already exists
    if (await savedFile.exists()) {
      savedPaths.add(savedFile.path);
      continue;
    }

    try {
      final response = await apiService.get<List<int>>(
        url: url,
        options: Options(responseType: ResponseType.bytes, extra: {
          "isNeedToWait" : true,
        }),
      );

      await savedFile.writeAsBytes(response?.data!);
      dev.log("Adding file to savedPaths: ${savedFile.path}");
      savedPaths.add(savedFile.path);
    } catch (e) {
      // If download fails, skip
      continue;
    }
  }

  dev.log("SavedPaths: $savedPaths");
  return savedPaths;
}


}
