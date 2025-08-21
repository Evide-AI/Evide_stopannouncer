import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:evide_dashboard/Infrastructure/service/fetchstopservice.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:evide_dashboard/Application/pages/screenplay/bloc/screenplay_bloc.dart';
import 'package:evide_dashboard/Infrastructure/service/Syncservice.dart';
import 'package:evide_dashboard/Application/pages/screenplay/widget/playlist.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class Screenplay extends StatefulWidget {
  const Screenplay({super.key});

  @override
  State<Screenplay> createState() => _ScreenplayState();
}

class _ScreenplayState extends State<Screenplay> {
  late StopAnnouncerService stopAnnouncer;
  final ValueNotifier<String?> _currentStop = ValueNotifier(null);

  @override
  void initState() {
    super.initState();
    stopAnnouncer = StopAnnouncerService();
    stopAnnouncer.start(intervalSeconds: 5);

    stopAnnouncer.stopStream.listen((stopName) {
      if (mounted) {
        _currentStop.value = stopName;

        if (stopName != null) {
          Future.delayed(const Duration(seconds: 5), () {
            if (mounted && _currentStop.value == stopName) {
              _currentStop.value = null;
            }
          });
        }
      }
    });
  }

  @override
  void dispose() {
    stopAnnouncer.stop();
    _currentStop.dispose();
    super.dispose();
  }

  Widget _buildStopBanner(String stopName) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade400, Colors.green.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 5,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.location_on, size: 48, color: Colors.white),
          ),
          const SizedBox(height: 24),
          Text(
            "You're Near",
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 18,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            stopName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.explore, size: 16, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  "Discover what's around you",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
                SizedBox(height: 16),
                Text(
                  "Initializing...",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        final prefs = snapshot.data!;
        final pairingCode = prefs.getString("pairingCode") ?? "";

        final syncService = SyncService(
          pairingCode,
          FirebaseFirestore.instance,
          FirebaseStorage.instance,
        );

        return BlocProvider(
          create: (_) => ScreenplayBloc(syncService)..add(LoadContents()),
          child: Scaffold(
            body: BlocBuilder<ScreenplayBloc, ScreenplayState>(
              builder: (context, state) {
                if (state is ContentsLoading) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.blue,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          "Loading your content...",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                } else if (state is ContentsFailed) {
                  return Center(
                    child: Container(
                      margin: const EdgeInsets.all(24),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Something went wrong",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            state.message,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.red.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                } else if (state is ContentsLoaded) {
                  final items = <PlaylistItem>[];

                  final contents = List<Map<String, dynamic>>.from(
                    state.documentData["Contents"] ?? [],
                  );

                  for (int i = 0; i < contents.length; i++) {
                    final contentKey = "content_$i";
                    if (state.localFiles.containsKey(contentKey)) {
                      final localPath = state.localFiles[contentKey]!;
                      final content = contents[i];

                      String fileType = _getFileType(localPath, content);
                      String? originalUrl = content['url'] as String?;

                      items.add(
                        PlaylistItem(
                          type: fileType,
                          path: localPath,
                          url: originalUrl,
                        ),
                      );
                    }
                  }

                  if (items.isEmpty) {
                    return Center(
                      child: Container(
                        margin: const EdgeInsets.all(24),
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.amber.shade200,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.playlist_remove,
                              size: 64,
                              color: Colors.amber.shade600,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "No Media Found",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Check your content library and try again",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.amber.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // ✅ Use Stack instead of Overlay to avoid video interference
                  return Stack(
                    children: [
                      // Video player stays at the bottom layer
                      PlaylistPlayer(items: items),
                      // Banner overlay that doesn't interfere with video
                      ValueListenableBuilder<String?>(
                        valueListenable: _currentStop,
                        builder: (context, stopName, child) {
                          return AnimatedOpacity(
                            opacity: stopName != null ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                            child: stopName != null
                                ? Container(
                                    color: Colors.black.withOpacity(0.3),
                                    child: Center(
                                      child: AnimatedScale(
                                        scale: stopName != null ? 1.0 : 0.8,
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        curve: Curves.easeOutBack,
                                        child: _buildStopBanner(stopName),
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          );
                        },
                      ),
                    ],
                  );
                }

                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.hourglass_empty,
                          size: 32,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Getting things ready...",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  String _getFileType(String localPath, Map<String, dynamic> content) {
    final extension = localPath.toLowerCase().split('.').last;
    if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension)) {
      return 'image';
    } else if ([
      'mp4',
      'mov',
      'avi',
      'mkv',
      'webm',
      'flv',
    ].contains(extension)) {
      return 'video';
    }
    final contentType = content['contentType'] as String? ?? '';
    if (contentType.startsWith('image/')) return 'image';
    if (contentType.startsWith('video/')) return 'video';
    return File(localPath).existsSync() ? 'video' : 'image';
  }
}
