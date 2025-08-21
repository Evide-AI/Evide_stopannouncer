import 'dart:convert';
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'linkscreen_event.dart';
part 'linkscreen_state.dart';

class LinkscreenBloc extends Bloc<LinkscreenEvent, LinkscreenState> {
  LinkscreenBloc() : super(LinkscreenInitial()) {
    on<CheckPairingCode>((event, emit) async {
      emit(LinkingLoading());
      try {
        print("🔎 Checking Firestore for pairingCode: ${event.pairingCode}");

        final querySnapshot = await FirebaseFirestore.instance
            .collection('Screens')
            .where('pairingCode', isEqualTo: event.pairingCode)
            .get();

        if (querySnapshot.docs.isEmpty) {
          print("❌ Pairing code not found in Firestore");
          emit(LinkingFailed("Pairing code not found"));
          return;
        }

        final doc = querySnapshot.docs.first;
        final data = doc.data();
        print("✅ Found document with ID: ${doc.id}");
        print("📄 Document data: $data");

        final prefs = await SharedPreferences.getInstance();
        final localPaths = <String, String>{};

        // --- Helper function with progress ---
        Future<String> downloadFile(
          String url,
          String fileName,
          String subDir, // "contents" or "stops"
          Emitter<LinkscreenState> emit,
        ) async {
          try {
            final baseDir = await getApplicationDocumentsDirectory();
            final targetDir = Directory("${baseDir.path}/$subDir");

            // Ensure folder exists
            if (!await targetDir.exists()) {
              await targetDir.create(recursive: true);
            }

            final file = File("${targetDir.path}/$fileName");

            // Check if file exists and is not empty
            if (await file.exists() && await file.length() > 0) {
              print("✅ Using existing file: ${file.path}");
              return file.path;
            }

            // Download the file if it doesn't exist
            print("⬇️ Downloading $fileName from $url to ${file.path}");

            final ref = FirebaseStorage.instance.refFromURL(url);
            final task = ref.writeToFile(file);

            // Listen for progress
            task.snapshotEvents.listen((snapshot) {
              final progress = snapshot.totalBytes > 0
                  ? snapshot.bytesTransferred / snapshot.totalBytes
                  : 0.0;
              emit(DownloadProgress(fileName: fileName, progress: progress));
              print(
                "📊 $fileName progress: ${(progress * 100).toStringAsFixed(2)}%",
              );
            });

            await task; // Wait until the task is complete
            print("✅ Saved: ${file.path}");
            return file.path;
          } catch (e) {
            print("⚠️ Failed to download $fileName: $e");
            return "";
          }
        }

        // --- Get current local file paths from SharedPreferences ---
        final localPathsJson = prefs.getString("localPaths");
        Map<String, String> localPathsFromPrefs = {};
        if (localPathsJson != null) {
          localPathsFromPrefs = Map<String, String>.from(
            jsonDecode(localPathsJson),
          );
        }

        // --- Download contents (array of objects) ---
        if (data.containsKey("Contents") && data["Contents"] is List) {
          final contents = List<Map<String, dynamic>>.from(data["Contents"]);

          for (int i = 0; i < contents.length; i++) {
            final content = contents[i];
            if (content.containsKey("url")) {
              final url = content["url"].toString();
              final fileName = url.split('/').last;

              // Check if the file already exists in local storage
              final localPath = await downloadFile(
                url,
                fileName,
                "contents", // Save inside /contents folder
                emit,
              );

              if (localPath.isNotEmpty) {
                contents[i]["localPath"] = localPath;
                localPaths["content_$i"] = localPath;

                // Remove old files if they're no longer in Firestore
                if (localPathsFromPrefs.containsKey("content_$i") &&
                    !data["Contents"].any(
                      (item) => item["url"] == content["url"],
                    )) {
                  final oldFilePath = localPathsFromPrefs["content_$i"];
                  final oldFile = File(oldFilePath!);
                  if (await oldFile.exists() && oldFile.lengthSync() > 0) {
                    await oldFile.delete();
                    print("🗑️ Deleted old file: $oldFilePath");
                  }
                }
              }
            }
          }

          data["Contents"] = contents;
        }

        // --- Download stops (audio files, etc.) ---
        if (data.containsKey("stops") && data["stops"] is List) {
          final stops = List<Map<String, dynamic>>.from(data["stops"]);
          for (int i = 0; i < stops.length; i++) {
            final stop = stops[i];
            if (stop.containsKey("stopUrl")) {
              final fileName = stop["stopUrl"].toString().split('/').last;
              final localPath = await downloadFile(
                stop["stopUrl"],
                fileName,
                "stops", // Save inside /stops folder
                emit,
              );
              if (localPath.isNotEmpty) {
                stops[i]["localPath"] = localPath;
                localPaths["stop_$i"] = localPath;

                // Remove old stop files if no longer in Firestore
                if (localPathsFromPrefs.containsKey("stop_$i") &&
                    !data["stops"].any(
                      (item) => item["stopUrl"] == stop["stopUrl"],
                    )) {
                  final oldFilePath = localPathsFromPrefs["stop_$i"];
                  final oldFile = File(oldFilePath!);
                  if (await oldFile.exists() && oldFile.lengthSync() > 0) {
                    await oldFile.delete();
                    print("🗑️ Deleted old stop file: $oldFilePath");
                  }
                }
              }
            }
          }

          data["stops"] = stops;
        }

        // --- Save everything in SharedPreferences ---
        await prefs.setString("pairingCode", event.pairingCode);
        await prefs.setString("documentId", doc.id);
        await prefs.setString(
          "documentData",
          jsonEncode(data), // Now includes localPath
        );
        await prefs.setString("localPaths", jsonEncode(localPaths));

        print("💾 Saved pairingCode: ${event.pairingCode}");
        print("💾 Saved documentId: ${doc.id}");
        print("💾 Saved local file paths: $localPaths");

        emit(LinkingSuccess());
      } catch (e, stack) {
        print("🔥 Error in CheckPairingCode: $e");
        print(stack);
        emit(LinkingFailed("Error: $e"));
      }
    });
  }
}
