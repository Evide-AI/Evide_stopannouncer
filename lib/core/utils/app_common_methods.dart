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

  // download videos to local storage
  // static Future<List<String>> downloadVideosToLocal(List<String> videoUrls) async {
  //   final List<String> localPaths = [];
  //   final appDir = await getApplicationDocumentsDirectory();

  //   // Allowed video extensions
  //   const validVideoExtensions = {
  //     '.mp4', '.webm', '.mov', '.mkv', '.avi', '.flv', '.wmv', '.3gp', '.m4v', '.ts', '.ogv'
  //   };

  //   for (int i = 0; i < videoUrls.length; i++) {
  //     final url = videoUrls[i];
  //     try {
  //       // Decode URL and parse it
  //       final decodedUrl = Uri.decodeFull(url);
  //       final uri = Uri.parse(decodedUrl);

  //       // Extract filename from Firebase-style path (last segment)
  //       String fileName = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'video_$i.mp4';

  //       // Clean out "%2F" encoding (if any)
  //       fileName = fileName.split('%2F').last;

  //       // Extract extension and validate it
  //       String extension = p.extension(fileName).toLowerCase();

  //       if (!validVideoExtensions.contains(extension)) {
  //         // No valid extension found → default to .mp4
  //         extension = '.mp4';
  //       }

  //       // Sanitize file name for filesystem
  //       fileName = p.basenameWithoutExtension(fileName)
  //           .replaceAll(RegExp(r'[^\w\-\.]'), '_') + extension;

  //       // Construct full local path
  //       final filePath = p.join(appDir.path, fileName);
  //       final file = File(filePath);

  //       if (await file.exists()) {
  //         localPaths.add(file.path);
  //         continue;
  //       }

  //       // Download file
  //       final response = await serviceLocator<Dio>().download(
  //         url,
  //         filePath,
  //         options: Options(responseType: ResponseType.bytes),
  //       );

  //       if (response.statusCode == 200) {
  //         localPaths.add(filePath);
  //         dev.log('Downloaded: $fileName');
  //       } else {
  //         dev.log('Failed to download ($fileName): ${response.statusCode}');
  //       }
  //     } catch (e) {
  //       dev.log('Error downloading $url: $e');
  //     }
  //   }

  //   return localPaths;
  // }

  static Future<List<String>> downloadVideosToLocal(List<String> videoUrls) async {
  if (videoUrls.isEmpty) return [];

  final appDir = await getApplicationDocumentsDirectory();
  const validVideoExtensions = {
    '.mp4', '.webm', '.mov', '.mkv', '.avi', '.flv', '.wmv', '.3gp', '.m4v', '.ts', '.ogv'
  };

  final dio = serviceLocator<Dio>();

  // Use Future.wait to download multiple videos concurrently (limit to avoid overload)
  final futures = <Future<String?>>[];

  for (int i = 0; i < videoUrls.length; i++) {
    final url = videoUrls[i];
    futures.add(() async {
      try {
        final decodedUrl = Uri.decodeFull(url);
        final uri = Uri.parse(decodedUrl);
        String fileName = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'video_$i.mp4';
        fileName = fileName.split('%2F').last;
        String extension = p.extension(fileName).toLowerCase();

        if (!validVideoExtensions.contains(extension)) {
          extension = '.mp4';
        }

        fileName = p.basenameWithoutExtension(fileName)
            .replaceAll(RegExp(r'[^\w\-\.]'), '_') + extension;

        final filePath = p.join(appDir.path, fileName);
        final file = File(filePath);

        if (await file.exists()) {
          return file.path;
        }

        final response = await dio.download(
          url,
          filePath,
          options: Options(responseType: ResponseType.bytes),
        );

        if (response.statusCode == 200) {
          dev.log('✅ Downloaded: $fileName');
          return filePath;
        } else {
          dev.log('❌ Failed: $fileName (${response.statusCode})');
          return null;
        }
      } catch (e) {
        dev.log('⚠️ Error downloading $url: $e');
        return null;
      }
    }());
  }

  // Limit concurrency (e.g. 3–5 at a time to avoid overload)
  const int batchSize = 3;
  final localPaths = <String>[];

  for (int i = 0; i < futures.length; i += batchSize) {
    final batch = futures.skip(i).take(batchSize).toList();
    final results = await Future.wait(batch);
    localPaths.addAll(results.whereType<String>());
  }

    return localPaths;
  }

  //

static Future<dynamic> currentStopDataShowingDialog(
  BuildContext context, {
  required String stopName,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true, // tap outside to close
    barrierLabel: '',
    transitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (context, anim1, anim2) {
      return const SizedBox.shrink();
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return Transform.scale(
        scale: animation.value,
        child: Opacity(
          opacity: animation.value,
          child: Dialog(
            insetPadding: EdgeInsets.zero,
            backgroundColor: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height / 2.5,
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade400, Colors.blue.shade800],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueAccent.withOpacity(0.5),
                    blurRadius: 25,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Faint location icon background
                  Positioned(
                    right: -20,
                    top: -10,
                    child: Icon(
                      Icons.location_on_rounded,
                      size: 180,
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),

                  // Main content
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.location_on_rounded,
                            color: Colors.white,
                            size: 60,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Current Stop",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          stopName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 46,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 60,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

}


// class AppCommonMethods {
//   static Future<List<String>> downloadVideosToLocal(List<String> videoUrls) async {
//     if (videoUrls.isEmpty) return [];

//     final appDir = await getApplicationDocumentsDirectory();
//     final dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 15)));
//     const validVideoExtensions = {
//       '.mp4', '.webm', '.mov', '.mkv', '.avi', '.flv', '.wmv', '.3gp', '.m4v', '.ts', '.ogv'
//     };

//     // Limit concurrent downloads to prevent bandwidth exhaustion
//     const int maxConcurrent = 5;

//     final results = <String>[];

//     Future<String?> downloadOne(String url, int index) async {
//       try {
//         final decodedUrl = Uri.decodeFull(url);
//         final uri = Uri.parse(decodedUrl);

//         String fileName = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'video_$index.mp4';
//         fileName = fileName.split('%2F').last;
//         String extension = p.extension(fileName).toLowerCase();
//         if (!validVideoExtensions.contains(extension)) extension = '.mp4';
//         fileName = p.basenameWithoutExtension(fileName).replaceAll(RegExp(r'[^\w\-\.]'), '_') + extension;

//         final filePath = p.join(appDir.path, fileName);
//         final file = File(filePath);

//         // Skip download if already exists
//         if (await file.exists() && await file.length() > 1000) {
//           dev.log('✅ Exists: $fileName');
//           return file.path;
//         }

//         final tempPath = '$filePath.part';
//         final tempFile = File(tempPath);
//         if (await tempFile.exists()) await tempFile.delete();

//         // Stream download directly to file
//         final response = await dio.get<ResponseBody>(
//           url,
//           options: Options(responseType: ResponseType.stream),
//         );

//         final raf = tempFile.openSync(mode: FileMode.write);
//         await response.data!.stream.pipe(raf);
//         await raf.close();

//         await tempFile.rename(filePath);

//         dev.log('✅ Downloaded: $fileName');
//         return file.path;
//       } catch (e) {
//         dev.log('⚠️ Failed $url: $e');
//         return null;
//       }
//     }

//     // Run downloads in batches of `maxConcurrent`
//     for (int i = 0; i < videoUrls.length; i += maxConcurrent) {
//       final batch = videoUrls.skip(i).take(maxConcurrent).toList();
//       final batchResults = await Future.wait(
//         [for (int j = 0; j < batch.length; j++) downloadOne(batch[j], i + j)],
//       );
//       results.addAll(batchResults.whereType<String>());
//     }

//     return results;
//   }
// }
