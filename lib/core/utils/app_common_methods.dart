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
  const validExts = { // valid extensions for video
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
        validUrls.add(url); // collecting valid video urls
      }
    } catch (e) {
      debugPrint("❌ Invalid URL skipped: $url");
    }
  }

  debugPrint("📥 Processing ${validUrls.length} valid URLs out of ${urls.length}");
  // method to download each video in url one by one
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
          await file.writeAsBytes(response.data!, flush: true); // writing response data as bytes to file

          // Validate the downloaded file
          if (await _isValidVideoFile(file)) {
            debugPrint("✅ Successfully saved: $filePath");
            return filePath;
          } else {
            await file.delete().catchError((_) {}); // delete file if not valid
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

/// Improved video validation - method for checking file is valid or not
static Future<bool> _isValidVideoFile(File file) async {
  try {
    if (!await file.exists()) return false; // if not exists return false

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


  // static Future<List<String>> downloadVideosToLocal(List<String> urls) async {
//   if (urls.isEmpty) return [];

//   final appDir = await getApplicationDocumentsDirectory();

//   const mimeMap = {
//     "video/mp4": ".mp4",
//     "video/webm": ".webm",
//     "video/quicktime": ".mov",
//     "video/x-matroska": ".mkv",
//     "video/x-msvideo": ".avi",
//     "video/x-flv": ".flv",
//     "video/x-ms-wmv": ".wmv",
//     "video/3gpp": ".3gp",
//     "video/x-m4v": ".m4v",
//     "video/mp2t": ".ts",
//     "video/ogg": ".ogv",
//   };

//   const maxRetries = 3;
//   const batchSize = 3;

//   final dio = serviceLocator<Dio>();

//   String normalizeUrl(String url) {
//     final uri = Uri.parse(url);
//     return uri.replace(queryParameters: {}).toString();
//   }

//   String? extractFileNameFromHeader(String? header) {
//     if (header == null) return null;
//     final regex = RegExp(r'filename="([^"]+)"');
//     final match = regex.firstMatch(header);
//     return match != null ? match.group(1) : null;
//   }

//   // ----------------------------------------------------------
//   // DOWNLOAD A SINGLE VIDEO WITH RESUME SUPPORT
//   // ----------------------------------------------------------
//   Future<String?> downloadSingle(String url) async {
//     try {
//       final uri = Uri.parse(url);

//       final cacheKey = md5.convert(normalizeUrl(url).codeUnits).toString();

//       String finalExt = "";
//       String filePath = p.join(appDir.path, "$cacheKey.tmp");
//       File tempFile = File(filePath);

//       int existingBytes = 0;
//       if (await tempFile.exists()) {
//         existingBytes = await tempFile.length();
//       }

//       for (int attempt = 1; attempt <= maxRetries; attempt++) {
//         try {
//           final headers = <String, dynamic>{};

//           // ---------------------------------------
//           // RESUME WITH RANGE HEADER
//           // ---------------------------------------
//           if (existingBytes > 0) {
//             headers["Range"] = "bytes=$existingBytes-";
//           }

//           final response = await dio.get<List<int>>(
//             url,
//             options: Options(
//               responseType: ResponseType.bytes,
//               followRedirects: true,
//               headers: headers,
//               receiveTimeout: const Duration(seconds: 90),
//               sendTimeout: const Duration(seconds: 60),
//             ),
//           );

//           final status = response.statusCode ?? 0;
//           if (status != 200 && status != 206) {
//             throw Exception("HTTP status $status");
//           }

//           final contentType =
//               response.headers.value("content-type")?.split(";").first.trim();

//           final contentDisposition =
//               response.headers.value("content-disposition");

//           // -------------------------------------------------------
//           // DETECT CORRECT FILE EXTENSION
//           // -------------------------------------------------------
//           if (contentDisposition != null) {
//             final name = extractFileNameFromHeader(contentDisposition);
//             if (name != null) {
//               final ext = p.extension(name).toLowerCase();
//               if (ext.isNotEmpty) finalExt = ext;
//             }
//           }

//           if (finalExt.isEmpty &&
//               contentType != null &&
//               mimeMap.containsKey(contentType)) {
//             finalExt = mimeMap[contentType]!;
//           }

//           if (finalExt.isEmpty) finalExt = ".mp4";

//           String finalPath = p.join(appDir.path, "$cacheKey$finalExt");

//           // -------------------------------------------------------
//           // APPEND NEW BYTES (RESUMING DOWNLOAD)
//           // -------------------------------------------------------
//           await tempFile.parent.create(recursive: true);
//           final raf = tempFile.openSync(mode: FileMode.append);
//           raf.writeFromSync(response.data!);
//           await raf.close();

//           // -------------------------------------------------------
//           // VALIDATION
//           // -------------------------------------------------------
//           if (await _isValidVideoFile(tempFile)) {
//             await tempFile.rename(finalPath);
//             return finalPath;
//           }

//           if (attempt == maxRetries) {
//             await tempFile.delete().catchError((_) {});
//             return null;
//           }

//           await Future.delayed(Duration(seconds: attempt));
//         } catch (_) {
//           if (attempt == maxRetries) return null;
//           await Future.delayed(Duration(seconds: attempt));
//         }
//       }

//       return null;
//     } catch (_) {
//       return null;
//     }
//   }

//   // ----------------------------------------------------------
//   // PROCESS IN BATCHES
//   // ----------------------------------------------------------
//   final result = List<String?>.filled(urls.length, null);

//   for (int i = 0; i < urls.length; i += batchSize) {
//     final end = (i + batchSize < urls.length) ? i + batchSize : urls.length;

//     final futures = <Future<String?>>[];
//     for (int j = i; j < end; j++) {
//       futures.add(downloadSingle(urls[j]));
//     }

//     final batchResults = await Future.wait(futures);

//     for (int j = i; j < end; j++) {
//       result[j] = batchResults[j - i];
//     }

//     await Future.delayed(const Duration(milliseconds: 150));
//   }

//   return result.whereType<String>().toList();
// }

// /// Improved validation
// static Future<bool> _isValidVideoFile(File file) async {
//   try {
//     if (!await file.exists()) return false;

//     final size = await file.length();
//     if (size < 1024) return false;

//     final raf = await file.open();
//     final header = await raf.read(16);
//     await raf.close();

//     // MP4
//     if (header.length >= 12 &&
//         String.fromCharCodes(header.sublist(4, 12)).contains("ftyp"))
//       return true;

//     // WebM/MKV (EBML)
//     if (header.length >= 4 &&
//         header[0] == 0x1A &&
//         header[1] == 0x45 &&
//         header[2] == 0xDF &&
//         header[3] == 0xA3)
//       return true;

//     // MOV
//     if (String.fromCharCodes(header).contains("moov")) return true;

//     // TS, AVI, others -> allow if large enough
//     if (size > 20 * 1024) return true;

//     return false;
//   } catch (_) {
//     return false;
//   }
// }
}
