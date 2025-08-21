import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

class SyncService {
  final String pairingCode;
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;

  StreamSubscription? _subscription;
  final Set<String> _downloadingFiles = {}; // Track ongoing downloads

  SyncService(this.pairingCode, this.firestore, this.storage);

  String _safeFileName(String name) {
    // Keep only letters, numbers, dot, dash, underscore
    return name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), "_");
  }

  /// Generate a unique hash for URL to detect content changes
  String _getUrlHash(String url) {
    var bytes = utf8.encode(url);
    var digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16); // Short hash
  }

  /// Start listening to Firestore document changes (by pairingCode)
  Stream<Map<String, dynamic>> startSync() {
    print("🔄 Starting sync for pairingCode: $pairingCode");

    return firestore
        .collection("Screens")
        .where("pairingCode", isEqualTo: pairingCode)
        .limit(1)
        .snapshots()
        .asyncMap<Map<String, dynamic>>((querySnapshot) async {
          if (querySnapshot.docs.isEmpty) {
            print("⚠️ No document found for pairingCode: $pairingCode");
            return <String, dynamic>{};
          }

          final docRef = querySnapshot.docs.first.reference;
          final data = Map<String, dynamic>.from(
            querySnapshot.docs.first.data(),
          );

          print("📡 Firestore data changed, syncing...");

          // ✅ Normalize Firestore arrays
          final contents = _normalizeList(data["Contents"]);
          final stops = _normalizeList(data["stops"]);

          print("📊 Found ${contents.length} contents, ${stops.length} stops");

          // ⏳ Download into separate folders (only new/changed files)
          final syncedContents = await _syncList(contents, "contents");
          final syncedStops = await _syncList(stops, "stops");

          // Update data with enriched versions
          data["Contents"] = syncedContents;
          data["stops"] = syncedStops;

          // 💾 Persist into prefs with metadata
          await _saveToPreferences(
            data,
            docRef.id,
            syncedContents,
            syncedStops,
          );

          print("✅ Sync completed successfully");
          return data;
        })
        .handleError((error) {
          print("❌ Firestore sync error: $error");
          throw error;
        });
  }

  /// Save synced data to SharedPreferences
  Future<void> _saveToPreferences(
    Map<String, dynamic> data,
    String documentId,
    List<Map<String, dynamic>> syncedContents,
    List<Map<String, dynamic>> syncedStops,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString("pairingCode", pairingCode);
    await prefs.setString("documentId", documentId);
    await prefs.setString("documentData", jsonEncode(data));
    await prefs.setString("lastSyncTime", DateTime.now().toIso8601String());

    // Build local paths map
    final localPaths = <String, String>{};
    final fileMetadata = <String, Map<String, dynamic>>{};

    for (int i = 0; i < syncedContents.length; i++) {
      if (syncedContents[i]["localPath"] != null) {
        final key = "content_$i";
        localPaths[key] = syncedContents[i]["localPath"];

        // Store metadata for cache validation
        fileMetadata[key] = {
          'url': syncedContents[i]["url"] ?? "",
          'downloadTime': DateTime.now().toIso8601String(),
          'hash': _getUrlHash(syncedContents[i]["url"] ?? ""),
        };
      }
    }

    for (int i = 0; i < syncedStops.length; i++) {
      if (syncedStops[i]["localPath"] != null) {
        final key = "stop_$i";
        localPaths[key] = syncedStops[i]["localPath"];

        fileMetadata[key] = {
          'url': syncedStops[i]["stopUrl"] ?? "",
          'downloadTime': DateTime.now().toIso8601String(),
          'hash': _getUrlHash(syncedStops[i]["stopUrl"] ?? ""),
        };
      }
    }

    await prefs.setString("localPaths", jsonEncode(localPaths));
    await prefs.setString("fileMetadata", jsonEncode(fileMetadata));

    print("💾 Cached ${localPaths.length} files locally");
  }

  /// ✅ Convert Firestore data (Map or List) into a List<Map<String, dynamic>>
  List<Map<String, dynamic>> _normalizeList(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) {
      return raw.cast<Map<String, dynamic>>();
    } else if (raw is Map) {
      return raw.values
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } else {
      return [];
    }
  }

  /// Sync list of files (Contents or Stops) into subfolder
  Future<List<Map<String, dynamic>>> _syncList(
    List<Map<String, dynamic>> items,
    String subDir,
  ) async {
    final baseDir = await getApplicationDocumentsDirectory();
    final targetDir = Directory("${baseDir.path}/$subDir");

    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
      print("📁 Created directory: ${targetDir.path}");
    }

    final result = List<Map<String, dynamic>>.filled(items.length, {});

    // Get existing file metadata for smart caching
    final prefs = await SharedPreferences.getInstance();
    final fileMetadataStr = prefs.getString("fileMetadata");
    final existingMetadata = fileMetadataStr != null
        ? Map<String, Map<String, dynamic>>.from(
            (jsonDecode(fileMetadataStr) as Map).map(
              (key, value) => MapEntry(key, Map<String, dynamic>.from(value)),
            ),
          )
        : <String, Map<String, dynamic>>{};

    for (int i = 0; i < items.length; i++) {
      final item = Map<String, dynamic>.from(items[i]);
      final url = item["url"] ?? item["stopUrl"];

      if (url == null || url.toString().isEmpty) {
        result[i] = item;
        continue;
      }

      final urlString = url.toString().trim();
      final urlHash = _getUrlHash(urlString);
      final rawName = urlString.split('/').last.trim();
      final safeName = _safeFileName(rawName);
      final filePath = "${targetDir.path}/$safeName";
      final file = File(filePath);

      // Check if we need to download this file
      final metadataKey = subDir == "contents" ? "content_$i" : "stop_$i";
      final shouldDownload = await _shouldDownloadFile(
        file,
        urlHash,
        existingMetadata[metadataKey],
        urlString,
      );

      if (shouldDownload) {
        await _downloadFileWithRetry(urlString, filePath);
      } else {
        print("📂 Using cached file: $safeName");
      }

      // Verify file exists and has content
      if (await file.exists() && await file.length() > 0) {
        item["localPath"] = filePath;
      } else {
        print("⚠️ File missing or empty after sync: $safeName");
      }

      result[i] = item;
    }

    // 🧹 Cleanup unused files in this subfolder
    final firestoreFiles = items
        .map((c) => (c["url"] ?? c["stopUrl"])?.toString())
        .where((e) => e != null && e.isNotEmpty)
        .toList();
    await _cleanup(targetDir, firestoreFiles);

    return result;
  }

  /// Determine if file should be downloaded
  Future<bool> _shouldDownloadFile(
    File file,
    String urlHash,
    Map<String, dynamic>? existingMetadata,
    String url,
  ) async {
    // File doesn't exist
    if (!await file.exists()) {
      print("⬇️ File missing, will download: ${file.path.split('/').last}");
      return true;
    }

    // File is empty
    if (await file.length() == 0) {
      print("⬇️ File empty, will re-download: ${file.path.split('/').last}");
      return true;
    }

    // No metadata (first time or after reset)
    if (existingMetadata == null) {
      print(
        "⬇️ No cache metadata, will download: ${file.path.split('/').last}",
      );
      return true;
    }

    // URL changed (different hash)
    final cachedHash = existingMetadata['hash'] as String?;
    if (cachedHash != urlHash) {
      print("⬇️ URL changed, will re-download: ${file.path.split('/').last}");
      return true;
    }

    // File is already downloading
    if (_downloadingFiles.contains(url)) {
      print("⏳ Already downloading: ${file.path.split('/').last}");
      return false;
    }

    // File exists and unchanged
    return false;
  }

  /// Download file with retry logic and duplicate prevention
  Future<void> _downloadFileWithRetry(String url, String filePath) async {
    final fileName = filePath.split('/').last;

    // Prevent duplicate downloads
    if (_downloadingFiles.contains(url)) {
      print("⏳ Already downloading $fileName, skipping duplicate request");
      return;
    }

    _downloadingFiles.add(url);

    try {
      print("⬇️ Starting download: $fileName");
      await _downloadFile(url, filePath);

      // Verify downloaded file
      final file = File(filePath);
      if (await file.exists() && await file.length() > 0) {
        print("✅ Download completed: $fileName (${await file.length()} bytes)");
      } else {
        throw Exception("Downloaded file is empty or missing");
      }
    } catch (e) {
      print("❌ Download failed: $fileName - $e");

      // Clean up failed download
      final file = File(filePath);
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {}
      }

      // Don't retry for authentication errors
      if (e.toString().contains('authentication') ||
          e.toString().contains('permission-denied')) {
        print("🚫 Authentication error - not retrying: $fileName");
        rethrow;
      }

      // Single retry after longer delay for network issues
      print("🔄 Retrying download in 5 seconds: $fileName");
      await Future.delayed(const Duration(seconds: 5));

      try {
        await _downloadFile(url, filePath);
        final file = File(filePath);
        if (await file.exists() && await file.length() > 0) {
          print("✅ Retry successful: $fileName (${await file.length()} bytes)");
        } else {
          throw Exception("Retry resulted in empty file");
        }
      } catch (retryError) {
        print("❌ Retry also failed: $fileName - $retryError");
        rethrow;
      }
    } finally {
      _downloadingFiles.remove(url);
    }
  }

  /// Download file from Firebase Storage or direct URL
  Future<void> _downloadFile(String pathOrUrl, String filePath) async {
    final cleanUrl = pathOrUrl.trim();
    final fileName = filePath.split('/').last;

    try {
      if (cleanUrl.startsWith("gs://")) {
        // Firebase Storage URL
        print("🔥 Getting Firebase Storage URL for: $fileName");
        final ref = storage.refFromURL(cleanUrl);
        final downloadUrl = await ref.getDownloadURL().timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw TimeoutException(
            'Firebase Storage URL timeout',
            const Duration(seconds: 15),
          ),
        );
        await _downloadFromHttp(downloadUrl, filePath);
      } else if (cleanUrl.startsWith("http://") ||
          cleanUrl.startsWith("https://")) {
        // Direct HTTP URL
        await _downloadFromHttp(cleanUrl, filePath);
      } else {
        // Firebase Storage path
        print("🔥 Getting Firebase Storage path for: $fileName");
        final cleanPath = cleanUrl.startsWith("/")
            ? cleanUrl.substring(1)
            : cleanUrl;
        final ref = storage.ref().child(cleanPath);
        final downloadUrl = await ref.getDownloadURL().timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw TimeoutException(
            'Firebase Storage path timeout',
            const Duration(seconds: 15),
          ),
        );
        await _downloadFromHttp(downloadUrl, filePath);
      }
    } on FirebaseException catch (e) {
      print("🔥 Firebase error for $fileName: ${e.code} - ${e.message}");
      if (e.code == 'unauthenticated' || e.code == 'permission-denied') {
        throw Exception(
          "Firebase authentication required. Please check Firebase rules and ensure user is signed in.",
        );
      }
      throw Exception("Firebase error: ${e.message}");
    } on TimeoutException catch (e) {
      throw Exception("Download timeout: ${e.message}");
    } catch (e) {
      throw Exception("Download error: $e");
    }
  }

  /// Download from HTTP URL with timeout and retry
  Future<void> _downloadFromHttp(String url, String filePath) async {
    const maxRetries = 3;
    const timeoutDuration = Duration(seconds: 60); // Increased timeout

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        print(
          "🌐 Downloading attempt $attempt/$maxRetries: ${filePath.split('/').last}",
        );

        final response = await http
            .get(
              Uri.parse(url),
              headers: {
                'Connection': 'keep-alive',
                'Accept': '*/*',
                'User-Agent': 'Flutter App',
              },
            )
            .timeout(timeoutDuration);

        if (response.statusCode == 200) {
          // Ensure directory exists
          final file = File(filePath);
          await file.parent.create(recursive: true);

          // Write file atomically (to temp file first, then rename)
          final tempPath = '$filePath.tmp';
          final tempFile = File(tempPath);
          await tempFile.writeAsBytes(response.bodyBytes);
          await tempFile.rename(filePath);

          print("✅ Downloaded: ${file.lengthSync()} bytes");
          return;
        } else {
          throw Exception(
            "HTTP ${response.statusCode}: ${response.reasonPhrase}",
          );
        }
      } catch (e) {
        print("⚠️ Download attempt $attempt failed: $e");

        if (attempt == maxRetries) {
          throw Exception("Download failed after $maxRetries attempts: $e");
        }

        // Progressive backoff delay
        final delay = Duration(seconds: attempt * 2);
        print("⏳ Retrying in ${delay.inSeconds}s...");
        await Future.delayed(delay);
      }
    }
  }

  /// Cleanup unused files in a specific subfolder
  Future<void> _cleanup(Directory dir, List<dynamic> firestoreFiles) async {
    final keep = firestoreFiles
        .map((e) => _safeFileName(e.toString().split('/').last.trim()))
        .toSet();

    try {
      final files = dir.listSync();
      int deletedCount = 0;

      for (var f in files) {
        if (f is File) {
          final name = f.path.split('/').last;
          if (!keep.contains(name)) {
            await f.delete();
            deletedCount++;
            print("🧹 Deleted old file: $name");
          }
        }
      }

      if (deletedCount > 0) {
        print("🧹 Cleanup completed: deleted $deletedCount unused files");
      }
    } catch (e) {
      print("⚠️ Cleanup error: $e");
    }
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final baseDir = await getApplicationDocumentsDirectory();
      final contentsDir = Directory("${baseDir.path}/contents");
      final stopsDir = Directory("${baseDir.path}/stops");

      int totalFiles = 0;
      int totalSize = 0;

      if (await contentsDir.exists()) {
        final files = contentsDir.listSync().whereType<File>();
        totalFiles += files.length;
        for (var file in files) {
          totalSize += await file.length();
        }
      }

      if (await stopsDir.exists()) {
        final files = stopsDir.listSync().whereType<File>();
        totalFiles += files.length;
        for (var file in files) {
          totalSize += await file.length();
        }
      }

      final prefs = await SharedPreferences.getInstance();
      final lastSync = prefs.getString("lastSyncTime");

      return {
        'totalFiles': totalFiles,
        'totalSizeBytes': totalSize,
        'totalSizeMB': (totalSize / 1024 / 1024).toStringAsFixed(2),
        'lastSyncTime': lastSync,
        'cacheDirectories': [contentsDir.path, stopsDir.path],
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Clear all cached files
  Future<void> clearCache() async {
    try {
      final baseDir = await getApplicationDocumentsDirectory();
      final contentsDir = Directory("${baseDir.path}/contents");
      final stopsDir = Directory("${baseDir.path}/stops");

      if (await contentsDir.exists()) {
        await contentsDir.delete(recursive: true);
      }
      if (await stopsDir.exists()) {
        await stopsDir.delete(recursive: true);
      }

      // Clear preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove("localPaths");
      await prefs.remove("fileMetadata");
      await prefs.remove("documentData");

      print("🧹 Cache cleared completely");
    } catch (e) {
      print("❌ Cache clear error: $e");
    }
  }

  /// Stop listening when not needed
  Future<void> dispose() async {
    await _subscription?.cancel();
    _downloadingFiles.clear();
  }
}
