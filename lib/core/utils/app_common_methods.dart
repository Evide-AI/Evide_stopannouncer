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


//   static Future<List<String>> downloadVideosToLocal(List<String> urls) async {
//   if (urls.isEmpty) return [];

//   final appDir = await getApplicationDocumentsDirectory();

//   // ------------------------------------------
//   // GET SAVED URL LIST
//   // ------------------------------------------
//   final savedUrls = SharedPrefsServices.getLocallySavedVideoUrls() ?? [];

//   // Remove duplicates from incoming list
//   final incomingUrls = urls.toSet().toList();

//   // New URLs (not downloaded before)
//   List<String> newUrls = incomingUrls.where((u) => !savedUrls.contains(u)).toList();

//   // ------------------------------------------
//   // GET ALL LOCAL VIDEO FILES (ONLY VALID VIDEOS)
//   // ------------------------------------------

//   List<String> locallySavedVideosFilePaths = [];

//   final filesInDir = Directory(appDir.path).listSync();

//   for (var entity in filesInDir) {
//     if (entity is File) {
//       final ext = p.extension(entity.path).toLowerCase();

//       if (videoExtensions.contains(ext)) {
//         // Extra validation to ensure the file is truly a video
//         if (await isValidVideoFile(entity)) {
//           locallySavedVideosFilePaths.add(entity.path);
//         }
//       }
//     }
//   }

//   // ------------------------------------------
//   // NO NEW URL → RETURN EXISTING LOCAL FILES
//   // ------------------------------------------
//   if (newUrls.isEmpty) {
//     return locallySavedVideosFilePaths;
//   }

//   // ==========================================
//   //     DOWNLOAD NEW VIDEOS
//   // ==========================================

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

//   final apiService = serviceLocator<ApiService>();

//   String normalizeUrl(String url) {
//     final uri = Uri.parse(url);
//     return uri.replace(queryParameters: {}).toString();
//   }

//   String? extractFileNameFromHeader(String? header) {
//     if (header == null) return null;
//     final regex = RegExp(r'filename="([^"]+)"');
//     final match = regex.firstMatch(header);
//     return match?.group(1);
//   }

//   // ------------------------------------------
//   // DOWNLOAD ONE FILE WITH RESUME SUPPORT
//   // ------------------------------------------
//   Future<String?> downloadSingle(String url) async {
//     try {
//       final cacheKey = md5.convert(normalizeUrl(url).codeUnits).toString();

//       String finalExt = "";
//       String tempPath = p.join(appDir.path, "$cacheKey.tmp");
//       File tempFile = File(tempPath);

//       int existingBytes = 0;
//       if (await tempFile.exists()) {
//         existingBytes = await tempFile.length();
//       }

//       for (int attempt = 1; attempt <= maxRetries; attempt++) {
//         try {
//           final headers = <String, dynamic>{};

//           if (existingBytes > 0) {
//             headers["Range"] = "bytes=$existingBytes-";
//           }

//           final response = await apiService.get<List<int>>(
//             url: url,
//             options: Options(
//               responseType: ResponseType.bytes,
//               followRedirects: true,
//               headers: headers,
//               receiveTimeout: const Duration(seconds: 90),
//               extra: {
//                 "isNeedToWait": true,
//               }
//             ),
//           );

//           if (![200, 206].contains(response?.statusCode)) {
//             throw Exception("Status ${response?.statusCode}");
//           }

//           final contentType = response?.headers.value("content-type")?.split(";").first.trim();
//           final contentDisposition = response?.headers.value("content-disposition");

//           // Detect extension
//           if (contentDisposition != null) {
//             final name = extractFileNameFromHeader(contentDisposition);
//             if (name != null) {
//               final ext = p.extension(name).toLowerCase();
//               if (ext.isNotEmpty) finalExt = ext;
//             }
//           }

//           if (finalExt.isEmpty && mimeMap.containsKey(contentType)) {
//             finalExt = mimeMap[contentType]!;
//           }
//           if (finalExt.isEmpty) finalExt = ".mp4";

//           // Write bytes (resume logic)
//           await tempFile.parent.create(recursive: true);
//           final raf = tempFile.openSync(mode: FileMode.append);
//           raf.writeFromSync(response?.data!);
//           await raf.close();

//           // Validate final result
//           if (await isValidVideoFile(tempFile)) {
//             final finalPath = p.join(appDir.path, "$cacheKey$finalExt");
//             await tempFile.rename(finalPath);
//             return finalPath;
//           }

//           // Final attempt failed
//           if (attempt == maxRetries) {
//             await tempFile.delete().catchError((_) {});
//             return null;
//           }

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

//   // ------------------------------------------
//   // PROCESS IN BATCHES
//   // ------------------------------------------
//   final results = List<String?>.filled(newUrls.length, null);

//   for (int i = 0; i < newUrls.length; i += batchSize) {
//     final end = (i + batchSize < newUrls.length) ? i + batchSize : newUrls.length;

//     final futures = <Future<String?>>[];

//     for (int j = i; j < end; j++) {
//       futures.add(downloadSingle(newUrls[j]));
//     }

//     final batchResults = await Future.wait(futures);

//     for (int j = i; j < end; j++) {
//       results[j] = batchResults[j - i];
//     }

//     await Future.delayed(const Duration(milliseconds: 150));
//   }

//   // Keep only successful downloads
//   final downloadedPaths = results.whereType<String>().toList();

//   locallySavedVideosFilePaths.addAll(downloadedPaths);

//   // ------------------------------------------
//   // UPDATE SAVED URL LIST
//   // ------------------------------------------
//   SharedPrefsServices.setLocallySavedVideoUrls(
//     urls: [...savedUrls, ...newUrls],
//   );

//   return locallySavedVideosFilePaths;
// }


/// ================================================
/// VALIDATION LOGIC
/// ================================================
static Future<bool> isValidVideoFile(File file) async {
  try {
    if (!await file.exists()) return false;

    final size = await file.length();
    if (size < 1024) return false; // too small → not a video

    final raf = await file.open();
    final header = await raf.read(16);
    await raf.close();

    // MP4 signature
    if (header.length >= 12 &&
        String.fromCharCodes(header.sublist(4, 12)).contains("ftyp")) {
      return true;
    }

    // WebM / MKV signature (EBML)
    if (header.length >= 4 &&
        header[0] == 0x1A &&
        header[1] == 0x45 &&
        header[2] == 0xDF &&
        header[3] == 0xA3) {
      return true;
    }

    // MOV (not perfect but acceptable)
    if (String.fromCharCodes(header).contains("moov")) {
      return true;
    }

    // For AVI, TS, FLV etc. → accept based on file size
    if (size > 20 * 1024) return true;

    return false;
  } catch (_) {
    return false;
  }
}

static Future<List<String>> downloadVideosToLocal(List<String> urls) async {
  if (urls.isEmpty) return [];

  final appDir = await getApplicationDocumentsDirectory();

  // ---------------------------------------------
  // Extract file name from Firebase URL
  // ---------------------------------------------
  String getFileNameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);

      // Firebase path is encoded → decode it
      String path = uri.path; // /v0/b/.../o/video%2Fatless.mp4
      path = Uri.decodeFull(path);

      // After decode → /v0/b/.../o/video/atless.mp4
      if (path.contains("/o/")) {
        final afterO = path.split("/o/").last;
        return afterO.split("/").last; // atless.mp4
      }

      return uri.pathSegments.last;
    } catch (_) {
      return DateTime.now().millisecondsSinceEpoch.toString();
    }
  }

  // -------------------------
  // Normalize URL
  // -------------------------
  String normalizeUrl(String url) {
    final uri = Uri.parse(url);
    return uri.replace(queryParameters: {}).toString();
  }

  final savedUrls = SharedPrefsServices.getLocallySavedVideoUrls() ?? [];
  final normalizedIncomingUrls = urls.map(normalizeUrl).toSet().toList();

  // -------------------------
  // Cleanup deleted URLs
  // -------------------------
  final normalizedSavedUrls = savedUrls.map(normalizeUrl).toSet();
  final normalizedNewUrls = normalizedIncomingUrls.toSet();

  final removedUrls = normalizedSavedUrls.difference(normalizedNewUrls).toList();

  for (final removed in removedUrls) {
    final fname = getFileNameFromUrl(removed);
    final file = File(p.join(appDir.path, fname));

    if (await file.exists()) {
      await file.delete().catchError((_) {});
    }
  }

  SharedPrefsServices.setLocallySavedVideoUrls(
    urls: savedUrls.where((u) => !removedUrls.contains(normalizeUrl(u))).toList(),
  );

  // -------------------------
  // Find new URLs to download
  // -------------------------
  final newUrls = normalizedIncomingUrls
      .where((u) => !savedUrls.map(normalizeUrl).contains(u))
      .toList();

  // -------------------------
  // Read existing valid files
  // -------------------------
  List<String> locallySavedVideosFilePaths = [];
  final files = Directory(appDir.path).listSync();

  for (var entity in files) {
    if (entity is File) {
      if (await isValidVideoFile(entity)) {
        locallySavedVideosFilePaths.add(entity.path);
      }
    }
  }

  if (newUrls.isEmpty) return locallySavedVideosFilePaths;

  // -----------------------------------------
  // DOWNLOAD A SINGLE FILE (with filename)
  // -----------------------------------------
  Future<String?> downloadSingle(String url) async {
    final normalized = normalizeUrl(url);
    final fileName = getFileNameFromUrl(normalized); // <----- FIXED
    final finalPath = p.join(appDir.path, fileName);

    final tempPath = finalPath + ".temp";
    final tempFile = File(tempPath);

    int existingBytes = await tempFile.exists() ? await tempFile.length() : 0;

    final apiService = serviceLocator<ApiService>();
    const maxRetries = 3;

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final headers = <String, dynamic>{};
        if (existingBytes > 0) {
          headers["Range"] = "bytes=$existingBytes-";
        }

        final response = await apiService.get<List<int>>(
          url: url,
          options: Options(
            responseType: ResponseType.bytes,
            followRedirects: true,
            headers: headers,
            receiveTimeout: const Duration(seconds: 90),
            extra: {"isNeedToWait": true},
          ),
        );

        if (![200, 206].contains(response?.statusCode)) {
          throw Exception("HTTP ${response?.statusCode}");
        }

        await tempFile.parent.create(recursive: true);

        final raf = tempFile.openSync(mode: FileMode.append);
        raf.writeFromSync(response?.data!);
        await raf.close();

        if (await isValidVideoFile(tempFile)) {
          await tempFile.rename(finalPath);
          return finalPath;
        }

        if (attempt == maxRetries) {
          tempFile.delete().catchError((_) {});
          return null;
        }
      } catch (_) {
        if (attempt == maxRetries) return null;
        await Future.delayed(Duration(seconds: attempt));
      }
    }

    return null;
  }

  // ------------------------------
  // Batch processing
  // ------------------------------
  const batchSize = 3;
  List<String?> results = List.filled(newUrls.length, null);

  for (int i = 0; i < newUrls.length; i += batchSize) {
    final end =
        (i + batchSize < newUrls.length) ? i + batchSize : newUrls.length;

    final batch = await Future.wait(
      newUrls.sublist(i, end).map(downloadSingle),
    );

    for (int j = i; j < end; j++) {
      results[j] = batch[j - i];
    }
  }

  final downloaded = results.whereType<String>().toList();
  locallySavedVideosFilePaths.addAll(downloaded);

  // ---------------------------------
  // Update shared prefs
  // ---------------------------------
  SharedPrefsServices.setLocallySavedVideoUrls(
    urls: [...savedUrls, ...urls],
  );

  return locallySavedVideosFilePaths;
}



// static Future<List<String>> downloadVideosToLocal(List<String> urls) async {
//   if (urls.isEmpty) return [];

//   final appDir = await getApplicationDocumentsDirectory();

//   // -----------------------------
//   // NORMALIZE URL (remove token)
//   // -----------------------------
//   String normalizeUrl(String url) {
//     final uri = Uri.parse(url);
//     return uri.replace(queryParameters: {}).toString();
//   }

//   // -----------------------------
//   // LOAD SAVED URL LIST
//   // -----------------------------
//   final savedUrls = SharedPrefsServices.getLocallySavedVideoUrls() ?? [];
//   final normalizedIncomingUrls = urls.map(normalizeUrl).toSet().toList();

//   // --------------------------------------
//   // SYNC CLEANUP: REMOVE DELETED URLs
//   // --------------------------------------
//   final normalizedSavedUrls =
//       savedUrls.map(normalizeUrl).toSet(); // unique old URLs
//   final normalizedNewUrls = normalizedIncomingUrls.toSet();

//   // URLs removed from Firestore
//   final removedUrls =
//       normalizedSavedUrls.difference(normalizedNewUrls).toList();

//   // Delete files corresponding to removed URLs
//   for (final removed in removedUrls) {
//     final cacheKey = md5.convert(removed.codeUnits).toString();
//     final filePattern = RegExp("^$cacheKey\\..+");

//     final files = Directory(appDir.path).listSync();
//     for (var entity in files) {
//       if (entity is File) {
//         final name = p.basename(entity.path);
//         if (filePattern.hasMatch(name)) {
//           await entity.delete().catchError((_) {});
//         }
//       }
//     }
//   }

//   // Update shared prefs (remove deleted URLs)
//   final updatedSaved = savedUrls
//       .where((u) => !removedUrls.contains(normalizeUrl(u)))
//       .toList();

//   SharedPrefsServices.setLocallySavedVideoUrls(urls: updatedSaved);

//   // ----------------------------------------------------
//   // DOWNLOAD PART — SAME AS YOUR LOGIC WITH SMALL FIXES
//   // ----------------------------------------------------

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

//   final apiService = serviceLocator<ApiService>();

//   List<String> locallySavedVideosFilePaths = [];

//   // ------------------------------------------
//   // Identify new URLs to download
//   // ------------------------------------------
//   final newUrls = normalizedIncomingUrls
//       .where((u) => !updatedSaved.map(normalizeUrl).contains(u))
//       .toList();

//   // ------------------------------------------
//   // READ EXISTING LOCAL VIDEO FILES
//   // ------------------------------------------
//   final filesInDir = Directory(appDir.path).listSync();
//   for (var entity in filesInDir) {
//     if (entity is File) {
//       final ext = p.extension(entity.path).toLowerCase();
//       if (videoExtensions.contains(ext)) {
//         if (await isValidVideoFile(entity)) {
//           locallySavedVideosFilePaths.add(entity.path);
//         }
//       }
//     }
//   }

//   // ------------------------------------------
//   // NO NEW URL → RETURN LOCAL FILES
//   // ------------------------------------------
//   if (newUrls.isEmpty) {
//     return locallySavedVideosFilePaths;
//   }

//   // ------------------------------------------
//   // DOWNLOAD ONE FILE
//   // ------------------------------------------
//   Future<String?> downloadSingle(String urlOriginal) async {
//     final url = urlOriginal; // use original while downloading
//     final normalized = normalizeUrl(url);
//     final cacheKey = md5.convert(normalized.codeUnits).toString();

//     String finalExt = "";
//     String tempPath = p.join(appDir.path, "$cacheKey.tmp");
//     File tempFile = File(tempPath);

//     int existingBytes = await tempFile.exists() ? await tempFile.length() : 0;


//     for (int attempt = 1; attempt <= maxRetries; attempt++) {
//       try {
//         final headers = <String, dynamic>{};
//         if (existingBytes > 0) {
//           headers["Range"] = "bytes=$existingBytes-";
//         }

//         final response = await apiService.get<List<int>>(
//           url: url,
//           options: Options(
//             responseType: ResponseType.bytes,
//             followRedirects: true,
//             headers: headers,
//             receiveTimeout: const Duration(seconds: 90),
//             extra: {"isNeedToWait": true},
//           ),
//         );

//         if (![200, 206].contains(response?.statusCode)) {
//           throw Exception("Status ${response?.statusCode}");
//         }

//         final contentType =
//             response?.headers.value("content-type")?.split(";").first.trim();
//         final contentDisposition =
//             response?.headers.value("content-disposition");

//         if (contentDisposition != null) {
//           final name = RegExp(r'filename="([^"]+)"')
//               .firstMatch(contentDisposition)
//               ?.group(1);
//           if (name != null) {
//             final ext = p.extension(name).toLowerCase();
//             if (ext.isNotEmpty) finalExt = ext;
//           }
//         }

//         if (finalExt.isEmpty && mimeMap.containsKey(contentType)) {
//           finalExt = mimeMap[contentType]!;
//         }
//         if (finalExt.isEmpty) finalExt = ".mp4";

//         await tempFile.parent.create(recursive: true);
//         final raf = tempFile.openSync(mode: FileMode.append);
//         raf.writeFromSync(response?.data!);
//         await raf.close();

//         if (await isValidVideoFile(tempFile)) {
//           final finalPath = p.join(appDir.path, "$cacheKey$finalExt");
//           await tempFile.rename(finalPath);
//           return finalPath;
//         }

//         if (attempt == maxRetries) {
//           tempFile.delete().catchError((_) {});
//           return null;
//         }
//       } catch (_) {
//         if (attempt == maxRetries) return null;
//         await Future.delayed(Duration(seconds: attempt));
//       }
//     }

//     return null;
//   }

//   // ------------------------------------------
//   // PROCESS DOWNLOADS IN BATCHES
//   // ------------------------------------------
//   final results = List<String?>.filled(newUrls.length, null);

//   for (int i = 0; i < newUrls.length; i += batchSize) {
//     final end = (i + batchSize < newUrls.length) ? i + batchSize : newUrls.length;

//     // Collect futures for this batch
//     final futures = <Future<String?>>[];

//     for (int j = i; j < end; j++) {
//       futures.add(downloadSingle(newUrls[j])); // FIXED: newUrls, not urls
//     }

//     // Wait for batch
//     final batchResults = await Future.wait(futures);

//     // Store into results
//     for (int j = i; j < end; j++) {
//       results[j] = batchResults[j - i];
//     }
//   }

//   final downloadedPaths = results.whereType<String>().toList();
//   locallySavedVideosFilePaths.addAll(downloadedPaths);

//   // ------------------------------------------
//   // UPDATE SAVED URL LIST
//   // ------------------------------------------
//   SharedPrefsServices.setLocallySavedVideoUrls(
//     urls: [...updatedSaved, ...urls],
//   );

//   return locallySavedVideosFilePaths;
// }



  static Future<void> clearOldDownloadedFilesFromAppStorage({required Directory  appDir}) async {
    // ==========================================
    //     CLEAR OLD DOWNLOADED VIDEO FILES
    // ==========================================
    final dir = Directory(appDir.path);
    if (await dir.exists()) {
      final files = dir.listSync();

      for (var file in files) {
        if (file is File) {
          final name = p.basename(file.path);
          
          // match your cache naming: <md5>.ext or <md5>.tmp
          final isCachedFile = RegExp(r'^[a-f0-9]{32}\.(mp4|webm|mov|mkv|avi|flv|wmv|3gp|m4v|ts|ogv|tmp)$')
              .hasMatch(name);

          if (isCachedFile) {
            try {
              await file.delete();
            } catch (_) {}
          }
        }
      }
    }
  }

}
