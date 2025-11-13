import 'dart:math';
import 'dart:developer' as dev;
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:evide_stop_announcer_app/core/app_imports.dart';
import 'package:evide_stop_announcer_app/core/services/service_locator.dart';
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

//   static Future<List<String>> downloadVideosToLocal(List<String> videoUrls) async {
//   if (videoUrls.isEmpty) return [];

//   final appDir = await getApplicationDocumentsDirectory();
//   const validVideoExtensions = {
//     '.mp4', '.webm', '.mov', '.mkv', '.avi', '.flv', '.wmv', '.3gp', '.m4v', '.ts', '.ogv'
//   };

//   final dio = serviceLocator<Dio>();

//   // Use Future.wait to download multiple videos concurrently (limit to avoid overload)
//   final futures = <Future<String?>>[];

//   for (int i = 0; i < videoUrls.length; i++) {
//     final url = videoUrls[i];
//     futures.add(() async {
//       try {
//         final decodedUrl = Uri.decodeFull(url);
//         final uri = Uri.parse(decodedUrl);
//         String fileName = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'video_$i.mp4';
//         fileName = fileName.split('%2F').last;
//         String extension = p.extension(fileName).toLowerCase();

//         if (!validVideoExtensions.contains(extension)) {
//           extension = '.mp4';
//         }

//         fileName = p.basenameWithoutExtension(fileName)
//             .replaceAll(RegExp(r'[^\w\-\.]'), '_') + extension;

//         final filePath = p.join(appDir.path, fileName);
//         final file = File(filePath);

//         if (await file.exists()) {
//           return file.path;
//         }

//         final response = await dio.download(
//           url,
//           filePath,
//           options: Options(responseType: ResponseType.bytes),
//         );

//         if (response.statusCode == 200) {
//           dev.log('✅ Downloaded: $fileName');
//           return filePath;
//         } else {
//           dev.log('❌ Failed: $fileName (${response.statusCode})');
//           return null;
//         }
//       } catch (e) {
//         dev.log('⚠️ Error downloading $url: $e');
//         return null;
//       }
//     }());
//   }

//   // Limit concurrency (e.g. 3–5 at a time to avoid overload)
//   const int batchSize = 3;
//   final localPaths = <String>[];

//   for (int i = 0; i < futures.length; i += batchSize) {
//     final batch = futures.skip(i).take(batchSize).toList();
//     final results = await Future.wait(batch);
//     localPaths.addAll(results.whereType<String>());
//   }

//     return localPaths;
//   }

// Make sure you register Dio in your service locator before calling this function
// or simply replace `serviceLocator<Dio>()` with `Dio()` if not using dependency injection.

static Future<List<String>> downloadVideosToLocal(List<String> videoUrls) async {
  if (videoUrls.isEmpty) return [];

  final appDir = await getApplicationDocumentsDirectory();
  const validVideoExtensions = {
    '.mp4', '.webm', '.mov', '.mkv', '.avi',
    '.flv', '.wmv', '.3gp', '.m4v', '.ts', '.ogv'
  };

  final dio = serviceLocator<Dio>(); // or just Dio();

  // We'll use Future batches to avoid overloading
  final List<Future<String?>> downloadFutures = [];

  for (int i = 0; i < videoUrls.length; i++) {
    final url = videoUrls[i];
    downloadFutures.add(() async {
      try {
        // ⚠️ Don’t decode Firebase URLs — just parse directly
        final uri = Uri.parse(url);

        // Extract clean file name
        String fileName = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'video_$i.mp4';
        fileName = fileName.split('%2F').last; // keep last part if URL encoded
        String extension = p.extension(fileName).toLowerCase();

        // Validate extension
        if (!validVideoExtensions.contains(extension)) {
          extension = '.mp4';
        }

        // Sanitize file name
        fileName = p.basenameWithoutExtension(fileName)
                .replaceAll(RegExp(r'[^\w\-\.]'), '_') +
            extension;

        final filePath = p.join(appDir.path, fileName);
        final file = File(filePath);

        // If file already exists and not empty, skip re-download
        if (await file.exists() && await file.length() > 0) {
          debugPrint('📁 Using cached video: $fileName');
          return file.path;
        }

        debugPrint('⬇️ Downloading: $url');

        final response = await dio.download(
          url,
          filePath,
          options: Options(responseType: ResponseType.bytes),
        );

        // Verify successful download
        if (response.statusCode == 200 && await file.length() > 0) {
          debugPrint('✅ Downloaded: $fileName (${await file.length()} bytes)');
          return file.path;
        } else {
          debugPrint('❌ Failed: $fileName (status: ${response.statusCode})');
          await file.delete().catchError((_) {});
          return null;
        }
      } catch (e, st) {
        debugPrint('⚠️ Error downloading $url: $e');
        return null;
      }
    }());
  }

  // Process downloads in small batches (to prevent network overload)
  const int batchSize = 3;
  final localPaths = <String>[];

  for (int i = 0; i < downloadFutures.length; i += batchSize) {
    final batch = downloadFutures.skip(i).take(batchSize).toList();
    final results = await Future.wait(batch);
    localPaths.addAll(results.whereType<String>());
  }

  dev.log('🎬 All downloaded videos: $localPaths');
  return localPaths;
}


}