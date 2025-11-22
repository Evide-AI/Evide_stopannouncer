import 'dart:math';
import 'dart:developer' as dev;
import 'dart:io';
import 'package:android_intent_plus/android_intent.dart';
import 'package:dio/dio.dart';
import 'package:evide_stop_announcer_app/core/app_imports.dart';
import 'package:evide_stop_announcer_app/core/services/api_service.dart';
import 'package:evide_stop_announcer_app/core/services/service_locator.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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

//   static Future<List<String>> downloadVideosToLocal(List<String> videoUrls) async {
//   if (videoUrls.isEmpty) return [];

//   final appDir = await getApplicationDocumentsDirectory();
//   const validVideoExtensions = {
//     '.mp4', '.webm', '.mov', '.mkv', '.avi',
//     '.flv', '.wmv', '.3gp', '.m4v', '.ts', '.ogv'
//   };

//   final List<Future<String?>> downloadFutures = [];

//   for (int i = 0; i < videoUrls.length; i++) {
//     final url = videoUrls[i];

//     downloadFutures.add(() async {
//       try {
//         final uri = Uri.parse(url);

//         // ---------------------------
//         // 1️⃣ Generate stable filename using MD5 hash (prevents duplicate downloads)
//         // ---------------------------
//         final hashedName = md5.convert(uri.path.codeUnits).toString();

//         String originalName =
//             uri.pathSegments.isNotEmpty ? uri.pathSegments.last : "video_$i.mp4";
//         originalName = originalName.split("%2F").last;

//         String ext = p.extension(originalName).toLowerCase();
//         if (!validVideoExtensions.contains(ext)) {
//           ext = ".mp4";
//         }

//         final fileName = "$hashedName$ext";

//         final filePath = p.join(appDir.path, fileName);
//         final file = File(filePath);

//         // ---------------------------
//         // 2️⃣ Use cached file if exists & valid
//         // ---------------------------
//         if (await file.exists() && await file.length() > 1024) {
//           debugPrint("📁 Using cached video: $fileName");
//           return filePath;
//         }

//         debugPrint("⬇️ Downloading: $url");

//         final response = await serviceLocator<ApiService>().download(
//           urlPath:  url,
//           savePath: filePath,
//           options: Options(
//             responseType: ResponseType.bytes,
//             extra: {
//             "isNeedToWait": true,
//           },
//           ),
//         );

//         // ---------------------------
//         // 3️⃣ Validate downloaded file
//         // ---------------------------
//         if (response?.statusCode != 200) {
//           debugPrint("❌ Invalid status: ${response?.statusCode}");
//           await file.delete().catchError((_) {});
//           return null;
//         }

//         // Ensure file exists and is not corrupted (min 1 KB)
//         final length = await file.length();
//         if (length < 1024) {
//           debugPrint("❌ Video too small (corrupt or invalid): $fileName ($length bytes)");
//           await file.delete().catchError((_) {});
//           return null;
//         }

//         // Optional deeper check: ensure file starts with video-like binary bytes
//         // (mp4 usually starts with ftyp)
//         final headerBytes = await file.openRead(0, 12).first;
//         final headerStr = String.fromCharCodes(headerBytes);
//         if (!headerStr.contains("ftyp") &&
//             !headerStr.contains("moov") &&
//             !headerStr.contains("mdat")) {
//           debugPrint("❌ Invalid video header → deleting file: $fileName");
//           await file.delete().catchError((_) {});
//           return null;
//         }

//         debugPrint("✅ Valid video saved: $fileName ($length bytes)");
//         return filePath;
//       } catch (e) {
//         debugPrint("⚠️ Error downloading $url: $e");
//         return null;
//       }
//     }());
//   }

//   // ---------------------------
//   // 4️⃣ Process in batches
//   // ---------------------------
//   const int batchSize = 3;
//   final localPaths = <String>[];

//   for (int i = 0; i < downloadFutures.length; i += batchSize) {
//     final batch = downloadFutures.skip(i).take(batchSize).toList();
//     final results = await Future.wait(batch);
//     localPaths.addAll(results.whereType<String>());
//   }

//   dev.log("🎬 All downloaded valid videos: $localPaths");
//   return localPaths;
// }


static Future<List<String>> downloadVideosToLocal(List<String> urls) async {
  if (urls.isEmpty) return [];

  final appDir = await getApplicationDocumentsDirectory();
  const validExts = {
    '.mp4', '.webm', '.mov', '.mkv', '.avi',
    '.flv', '.wmv', '.3gp', '.m4v', '.ts', '.ogv'
  };

  const maxRetries = 3;

  Future<String?> downloadSingle(String url, int index) async {
    final uri = Uri.parse(url);
    final hashed = md5.convert(url.codeUnits).toString();

    String fileName = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : "video_$index.mp4";
    fileName = fileName.split("%2F").last;

    String ext = p.extension(fileName).toLowerCase();
    if (!validExts.contains(ext)) ext = ".mp4";

    final filePath = p.join(appDir.path, "$hashed$ext");
    final file = File(filePath);

    // -------------------------------
    // CACHE VALIDATION
    // -------------------------------
    if (await file.exists()) {
      if (await _isValidVideoFile(file)) {
        return filePath;
      } else {
        await file.delete().catchError((_) {});
      }
    }

    // -------------------------------
    // DOWNLOAD WITH RETRIES
    // -------------------------------
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final response = await serviceLocator<Dio>().get<List<int>>(
          url,
          options: Options(
            responseType: ResponseType.bytes,
            followRedirects: true,
            receiveTimeout: const Duration(seconds: 20),
          ),
        );

        if (response.statusCode != 200 || response.data == null) {
          throw Exception("Bad status");
        }
        debugPrint("✅ Response 200");

        await file.writeAsBytes(response.data!, flush: true);

        // -------------------------------
        // Validate real video
        // -------------------------------
        if (await _isValidVideoFile(file)) {
          return filePath;
        } else {
          await file.delete().catchError((_) {});
          debugPrint("⚠️ Invalid video header");
        }

      } catch (e) {
        debugPrint("⚠️ Download failed attempt $attempt → $e");

        if (attempt == maxRetries) return null;

        await Future.delayed(Duration(milliseconds: 500 * attempt));
      }
    }

    return null;
  }

  // -------------------------------
  // PROCESS IN PARALLEL (3/BATCH)
  // -------------------------------
  const batchSize = 3;
  List<String> result = [];

  for (int i = 0; i < urls.length; i += batchSize) {
    final batchUrls = urls.skip(i).take(batchSize).toList();

    final batchResults = await Future.wait(
      List.generate(
        batchUrls.length,
        (j) => downloadSingle(batchUrls[j], i + j),
      ),
      eagerError: false,
    );

    result.addAll(batchResults.whereType<String>());
  }

  debugPrint("✅ All downloaded videos: $result");

  return result;
}


/// ------------------------------------------------------
/// VALIDATE VIDEO FILE HEADER
/// Small videos ALSO ALLOWED   <------- YOUR REQUIREMENT
/// ------------------------------------------------------
static Future<bool> _isValidVideoFile(File file) async {
  if (!await file.exists()) return false;

  final raf = await file.open();
  final header = await raf.read(64);
  await raf.close();

  if (header.isEmpty) return false;

  final str = String.fromCharCodes(header).toLowerCase();

  return str.contains("ftyp") ||
      str.contains("isom") ||
      str.contains("mdat") ||
      str.contains("moov") ||
      str.contains("webm") ||
      str.contains("matroska");
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
}
