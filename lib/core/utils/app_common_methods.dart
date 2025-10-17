import 'dart:math';
import 'dart:developer' as dev;
import 'dart:io';
import 'package:dio/dio.dart';
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
  static Future<List<String>> downloadVideosToLocal(List<String> videoUrls) async {
    final List<String> localPaths = [];
    final appDir = await getApplicationDocumentsDirectory();

    // Allowed video extensions
    const validVideoExtensions = {
      '.mp4', '.webm', '.mov', '.mkv', '.avi', '.flv', '.wmv', '.3gp', '.m4v', '.ts', '.ogv'
    };

    for (int i = 0; i < videoUrls.length; i++) {
      final url = videoUrls[i];
      try {
        // Decode URL and parse it
        final decodedUrl = Uri.decodeFull(url);
        final uri = Uri.parse(decodedUrl);

        // Extract filename from Firebase-style path (last segment)
        String fileName = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'video_$i.mp4';

        // Clean out "%2F" encoding (if any)
        fileName = fileName.split('%2F').last;

        // Extract extension and validate it
        String extension = p.extension(fileName).toLowerCase();

        if (!validVideoExtensions.contains(extension)) {
          // No valid extension found → default to .mp4
          extension = '.mp4';
        }

        // Sanitize file name for filesystem
        fileName = p.basenameWithoutExtension(fileName)
            .replaceAll(RegExp(r'[^\w\-\.]'), '_') + extension;

        // Construct full local path
        final filePath = p.join(appDir.path, fileName);
        final file = File(filePath);

        if (await file.exists()) {
          localPaths.add(file.path);
          continue;
        }

        // Download file
        final response = await serviceLocator<Dio>().download(
          url,
          filePath,
          options: Options(responseType: ResponseType.bytes),
        );

        if (response.statusCode == 200) {
          localPaths.add(filePath);
          dev.log('Downloaded: $fileName');
        } else {
          dev.log('Failed to download ($fileName): ${response.statusCode}');
        }
      } catch (e) {
        dev.log('Error downloading $url: $e');
      }
    }

    return localPaths;
  }
}

