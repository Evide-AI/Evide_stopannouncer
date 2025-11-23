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




// static Future<List<String>> downloadVideosToLocal(List<String> urls) async {
//   if (urls.isEmpty) return [];

//   final appDir = await getApplicationDocumentsDirectory(); // getting application document directory
//   // all valid extension for check
//   const validExts = {
//     '.mp4', '.webm', '.mov', '.mkv', '.avi',
//     '.flv', '.wmv', '.3gp', '.m4v', '.ts', '.ogv'
//   };

//   const maxRetries = 3; // retry for 3 times

//   Future<String?> downloadSingle(String url, int index) async {
//     final uri = Uri.parse(url);
//     final hashed = md5.convert(url.codeUnits).toString();

//     String fileName = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : "video_$index.mp4";
//     fileName = fileName.split("%2F").last;

//     String ext = p.extension(fileName).toLowerCase();
//     if (!validExts.contains(ext)) ext = ".mp4"; // if ext not in validextension adding ext .mp4

//     final filePath = p.join(appDir.path, "$hashed$ext");
//     final file = File(filePath);

//     // -------------------------------
//     // CACHE VALIDATION - checking file exits or not if exist, will check valid or not, if valid returning the file path, else deleting the file
//     // -------------------------------
//     if (await file.exists()) {
//       if (await _isValidVideoFile(file)) {
//         return filePath;
//       } else {
//         await file.delete().catchError((_) {});
//       }
//     }

//     // -------------------------------
//     // DOWNLOAD WITH RETRIES
//     // -------------------------------
//     for (int attempt = 1; attempt <= maxRetries; attempt++) {
//       try {
//         final response = await serviceLocator<Dio>().get<List<int>>(
//           url,
//           options: Options(
//             responseType: ResponseType.bytes,
//             followRedirects: true,
//             receiveTimeout: const Duration(seconds: 20),
//           ),
//         );

//         if (response.statusCode != 200 || response.data == null) {
//           throw Exception("Bad status");
//         }
//         debugPrint("✅ Response 200");

//         await file.writeAsBytes(response.data!, flush: true); // writing response data as bytes to file

//         // -------------------------------
//         // Validate real video
//         // -------------------------------
//         if (await _isValidVideoFile(file)) {
//           return filePath;
//         } else {
//           await file.delete().catchError((_) {});
//           debugPrint("⚠️ Invalid video header");
//         }

//       } catch (e) {
//         debugPrint("⚠️ Download failed attempt $attempt → $e");

//         if (attempt == maxRetries) return null;

//         await Future.delayed(Duration(milliseconds: 500 * attempt));
//       }
//     }

//     return null;
//   }

//   // -------------------------------
//   // PROCESS IN PARALLEL (3/BATCH)
//   // -------------------------------
//   const batchSize = 3;
//   List<String> result = [];

//   for (int i = 0; i < urls.length; i += batchSize) {
//     final batchUrls = urls.skip(i).take(batchSize).toList();

//     final batchResults = await Future.wait(
//       List.generate(
//         batchUrls.length,
//         (j) => downloadSingle(batchUrls[j], i + j),
//       ),
//       eagerError: false,
//     );

//     result.addAll(batchResults.whereType<String>());
//   }

//   debugPrint("✅ All downloaded videos: $result");

//   return result;
// }


// /// ------------------------------------------------------
// /// VALIDATE VIDEO FILE HEADER
// /// Small videos ALSO ALLOWED
// /// ------------------------------------------------------
// static Future<bool> _isValidVideoFile(File file) async {
//   if (!await file.exists()) return false;

//   final raf = await file.open();
//   final header = await raf.read(64);
//   await raf.close();

//   if (header.isEmpty) return false;

//   final str = String.fromCharCodes(header).toLowerCase();

//   return str.contains("ftyp") ||
//       str.contains("isom") ||
//       str.contains("mdat") ||
//       str.contains("moov") ||
//       str.contains("webm") ||
//       str.contains("matroska");
// }


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
  if (urls.isEmpty) return [];

  final appDir = await getApplicationDocumentsDirectory();
  const validExts = {
    '.mp4', '.webm', '.mov', '.mkv', '.avi',
    '.flv', '.wmv', '.3gp', '.m4v', '.ts', '.ogv'
  };

  const maxRetries = 3;
  const batchSize = 3;

  // Filter out invalid URLs first
  final validUrls = <String>[];
  for (final url in urls) {
    try {
      final uri = Uri.parse(url);
      if (uri.isAbsolute) {
        validUrls.add(url);
      }
    } catch (e) {
      debugPrint("❌ Invalid URL skipped: $url");
    }
  }

  debugPrint("📥 Processing ${validUrls.length} valid URLs out of ${urls.length}");

  Future<String?> downloadSingle(String url, int index) async {
    try {
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
        debugPrint("🔍 Checking cache for: ${uri.pathSegments.last}");
        if (await _isValidVideoFile(file)) {
          debugPrint("✅ Using cached file: $filePath");
          return filePath;
        } else {
          debugPrint("🗑️ Deleting invalid cached file");
          await file.delete().catchError((e) {
            debugPrint("⚠️ Error deleting cached file: $e");
          });
        }
      }

      // -------------------------------
      // DOWNLOAD WITH RETRIES
      // -------------------------------
      for (int attempt = 1; attempt <= maxRetries; attempt++) {
        try {
          debugPrint("⬇️ Downloading attempt $attempt for: ${uri.pathSegments.last}");

          final response = await serviceLocator<Dio>().get<List<int>>(
            url,
            options: Options(
              responseType: ResponseType.bytes,
              followRedirects: true,
              receiveTimeout: const Duration(seconds: 30), // Increased timeout
              sendTimeout: const Duration(seconds: 30),
            ),
          );

          if (response.statusCode != 200 || response.data == null) {
            throw Exception("HTTP ${response.statusCode}");
          }

          debugPrint("✅ Downloaded ${response.data!.length} bytes for: ${uri.pathSegments.last}");

          // Create directory if it doesn't exist
          await file.parent.create(recursive: true);

          // Write file
          await file.writeAsBytes(response.data!, flush: true);

          // Validate the downloaded file
          if (await _isValidVideoFile(file)) {
            debugPrint("✅ Successfully saved: $filePath");
            return filePath;
          } else {
            await file.delete().catchError((_) {});
            debugPrint("⚠️ Invalid video file after download: ${uri.pathSegments.last}");
            
            if (attempt == maxRetries) {
              debugPrint("❌ Failed to download valid video after $maxRetries attempts: $url");
              return null;
            }
          }

        } catch (e) {
          debugPrint("⚠️ Download attempt $attempt failed for ${uri.pathSegments.last}: $e");

          if (attempt == maxRetries) {
            debugPrint("❌ All download attempts failed for: $url");
            return null;
          }

          // Exponential backoff
          await Future.delayed(Duration(seconds: 1 * attempt));
        }
      }

      return null;
    } catch (e) {
      debugPrint("💥 Unexpected error downloading $url: $e");
      return null;
    }
  }

  // -------------------------------
  // PROCESS IN PARALLEL WITH BETTER ERROR HANDLING
  // -------------------------------
  List<String> result = [];
  int successfulDownloads = 0;
  int failedDownloads = 0;

  for (int i = 0; i < validUrls.length; i += batchSize) {
    final endIndex = i + batchSize < validUrls.length ? i + batchSize : validUrls.length;
    final batchUrls = validUrls.sublist(i, endIndex);

    debugPrint("🔄 Processing batch ${(i ~/ batchSize) + 1}: ${batchUrls.length} items");

    try {
      final batchFutures = <Future<String?>>[];
      for (int j = 0; j < batchUrls.length; j++) {
        batchFutures.add(downloadSingle(batchUrls[j], i + j));
      }

      final batchResults = await Future.wait(
        batchFutures,
        eagerError: false,
      );

      for (final batchResult in batchResults) {
        if (batchResult != null) {
          result.add(batchResult);
          successfulDownloads++;
        } else {
          failedDownloads++;
        }
      }

      debugPrint("📊 Batch completed: ${batchResults.where((r) => r != null).length}/${batchUrls.length} successful");

    } catch (e) {
      debugPrint("💥 Batch processing error: $e");
      failedDownloads += batchUrls.length;
    }

    // Small delay between batches to avoid overwhelming the system
    if (endIndex < validUrls.length) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  debugPrint("🎉 Download completed: $successfulDownloads successful, $failedDownloads failed");
  debugPrint("✅ Final result: ${result.length} videos downloaded");

  return result;
}

/// Improved video validation
static Future<bool> _isValidVideoFile(File file) async {
  try {
    if (!await file.exists()) return false;

    final fileSize = await file.length();
    if (fileSize == 0) {
      debugPrint("⚠️ File is empty: ${file.path}");
      return false;
    }

    final raf = await file.open();
    try {
      final header = await raf.read(128); // Read more bytes for better detection
      await raf.close();

      if (header.isEmpty) return false;

      final headerStr = String.fromCharCodes(header).toLowerCase();

      // More comprehensive video file signatures
      final hasValidSignature = headerStr.contains("ftyp") ||
          headerStr.contains("isom") ||
          headerStr.contains("mdat") ||
          headerStr.contains("moov") ||
          headerStr.contains("webm") ||
          headerStr.contains("matroska") ||
          headerStr.contains("avc1") ||
          headerStr.contains("mp4") ||
          headerStr.contains("mov");

      if (!hasValidSignature) {
        debugPrint("⚠️ Invalid video signature in: ${file.path}");
        // Debug: print first few bytes for analysis
        debugPrint("🔍 First 32 bytes: ${header.sublist(0, min(32, header.length))}");
      }

      return hasValidSignature;
    } catch (e) {
      await raf.close();
      return false;
    }
  } catch (e) {
    debugPrint("💥 Error validating video file: $e");
    return false;
  }
}
}
