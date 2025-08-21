import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:evide_dashboard/Infrastructure/service/Syncservice.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'screenplay_event.dart';
part 'screenplay_state.dart';

class ScreenplayBloc extends Bloc<ScreenplayEvent, ScreenplayState> {
  final SyncService syncService;

  ScreenplayBloc(this.syncService) : super(ScreenplayInitial()) {
    on<LoadContents>(_onLoadContents);
  }

  Future<void> _onLoadContents(
    LoadContents event,
    Emitter<ScreenplayState> emit,
  ) async {
    emit(ContentsLoading());

    try {
      final prefs = await SharedPreferences.getInstance();

      // Load cached data first (so UI can play immediately)
      final pairingCode = prefs.getString("pairingCode");
      final documentId = prefs.getString("documentId");
      final documentDataStr = prefs.getString("documentData");
      final localPathsStr = prefs.getString("localPaths");
      print('local path of the data........${localPathsStr}');
      print('Document path of the data........${documentDataStr}');
      if (documentDataStr != null && localPathsStr != null) {
        final documentData =
            jsonDecode(documentDataStr) as Map<String, dynamic>;
        final localPaths = Map<String, String>.from(jsonDecode(localPathsStr));
        print('local path of the data........${localPathsStr}');
        // ✅ Inject cached local paths back into contents/stops
        final contents = documentData["Contents"] is List
            ? List<Map<String, dynamic>>.from(documentData["Contents"])
            : <Map<String, dynamic>>[]; // Default empty list if it's not a list
        print('Contents in screenplay_bloc.......${contents}');
        final stops = documentData["stops"] is List
            ? List<Map<String, dynamic>>.from(documentData["stops"])
            : <Map<String, dynamic>>[]; // Default empty list if it's not a list
        print('Stops in Screenplay_bloc............${stops}');

        for (int i = 0; i < contents.length; i++) {
          if (localPaths.containsKey("content_$i")) {
            contents[i]["localPath"] = localPaths["content_$i"];
          }
        }
        for (int i = 0; i < stops.length; i++) {
          if (localPaths.containsKey("stop_$i")) {
            stops[i]["localPath"] = localPaths["stop_$i"];
          }
        }

        documentData["Contents"] = contents;
        documentData["stops"] = stops;

        print("📂 Loading cached contents from prefs...");
        print("💾 Cached local files: $localPaths");

        emit(
          ContentsLoaded(
            pairingCode: pairingCode,
            documentId: documentId,
            documentData: documentData, // enriched with cached localPath
            localFiles: localPaths,
            updatedAt: DateTime.now(),
          ),
        );
      } else {
        emit(ContentsFailed("⚠️ No cached contents found"));
      }

      // 🔄 Start Firestore <-> Local sync in background (No progress tracking, just loading local files)
      await emit.forEach(
        syncService.startSync(),
        onData: (syncedData) {
          final contents = List<Map<String, dynamic>>.from(
            syncedData["Contents"] ?? [],
          );
          print('Contents from the local storage..........📓${contents}');
          final stops = List<Map<String, dynamic>>.from(
            syncedData["stops"] ?? [],
          );
          print('Stops data from Local storage..........📓${stops}');

          // Build local paths map
          final localPaths = <String, String>{};
          for (int i = 0; i < contents.length; i++) {
            if (contents[i]["localPath"] != null) {
              localPaths["content_$i"] = contents[i]["localPath"];
            }
          }
          for (int i = 0; i < stops.length; i++) {
            if (stops[i]["localPath"] != null) {
              localPaths["stop_$i"] = stops[i]["localPath"];
            }
          }

          // ✅ Persist enriched version
          _saveToPrefs(prefs, pairingCode, documentId, syncedData, localPaths);

          print("💾 Synced local files: $localPaths");

          return ContentsLoaded(
            updatedAt: DateTime.now(),
            pairingCode: pairingCode,
            documentId: documentId,
            documentData: syncedData,
            localFiles: localPaths,
          );
        },
        onError: (_, __) => ContentsFailed("❌ Firestore sync failed"),
      );
    } catch (e, stack) {
      print("🔥 Error loading/syncing Files: $e");
      print(stack);
      emit(ContentsFailed("Error loading/syncing: $e"));
    }
  }

  Future<void> _saveToPrefs(
    SharedPreferences prefs,
    String? pairingCode,
    String? documentId,
    Map<String, dynamic> documentData,
    Map<String, String> localPaths,
  ) async {
    await prefs.setString("pairingCode", pairingCode ?? "");
    await prefs.setString("documentId", documentId ?? "");
    await prefs.setString(
      "documentData",
      jsonEncode(documentData),
    ); // enriched!
    await prefs.setString("localPaths", jsonEncode(localPaths));
  }
}
