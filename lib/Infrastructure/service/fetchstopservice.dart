import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:audioplayers/audioplayers.dart';

class StopAnnouncerService {
  List<Map<String, dynamic>> stops = [];
  String? _lastAnnouncedStop;
  Timer? _timer;
  bool _isRunning = false;
  AudioPlayer? _audioPlayer; // Keep reference to manage audio lifecycle

  final StreamController<String?> _stopController =
      StreamController<String?>.broadcast();

  /// 🔹 UI listens to this
  Stream<String?> get stopStream => _stopController.stream;

  /// Start background checking every [intervalSeconds]
  Future<void> start({int intervalSeconds = 5}) async {
    if (_isRunning) return;
    _isRunning = true;

    // Initialize audio player with proper configuration
    _audioPlayer = AudioPlayer();
    await _configureAudioPlayer();

    // Load stops once
    await _fetchStopsData();

    // Run immediately once
    _checkNearbyStop();

    // Schedule every X seconds
    _timer = Timer.periodic(Duration(seconds: intervalSeconds), (_) {
      _checkNearbyStop();
    });

    debugPrint(
      "🚀 StopAnnouncerService started with interval $intervalSeconds sec",
    );
  }

  /// Configure audio player for optimal stop announcement playback
  Future<void> _configureAudioPlayer() async {
    if (_audioPlayer == null) return;

    try {
      // Set audio context to prioritize announcements
      await _audioPlayer!.setAudioContext(
        AudioContext(
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: {
              AVAudioSessionOptions.mixWithOthers,
              AVAudioSessionOptions
                  .duckOthers, // Lower other audio when playing
            },
          ),
          android: AudioContextAndroid(
            isSpeakerphoneOn: false,
            stayAwake: false,
            contentType: AndroidContentType.speech,
            usageType: AndroidUsageType.notificationRingtone, // High priority
            audioFocus:
                AndroidAudioFocus.gainTransientMayDuck, // Duck other audio
          ),
        ),
      );

      // Set volume to maximum for announcements
      await _audioPlayer!.setVolume(1.0);

      debugPrint("🔊 Audio player configured for priority playback");
    } catch (e) {
      debugPrint("⚠️ Audio context configuration failed: $e");
    }
  }

  void stop() {
    _timer?.cancel();
    _audioPlayer?.stop();
    _audioPlayer?.dispose();
    _audioPlayer = null;
    _isRunning = false;
    _stopController.close();
    debugPrint("🛑 StopAnnouncerService stopped");
  }

  /// Fetch stops from SharedPreferences (documentData)
  Future<void> _fetchStopsData() async {
    final prefs = await SharedPreferences.getInstance();
    final documentPathData = prefs.getString('documentData');
    debugPrint("📂 Loaded documentData: $documentPathData");

    if (documentPathData != null) {
      final data = jsonDecode(documentPathData);
      if (data.containsKey('stops')) {
        stops = List<Map<String, dynamic>>.from(data['stops']);
        debugPrint('✅ Fetched stops: ${stops.length}');
      }
    }
  }

  /// Check current location vs stops
  Future<void> _checkNearbyStop() async {
    if (stops.isEmpty) {
      debugPrint("⚠️ No stops loaded, skipping check...");
      return;
    }

    Position liveLocation;
    try {
      liveLocation = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      debugPrint("🔥 Failed to get location: $e");
      return;
    }

    debugPrint(
      "📍 Live Location: ${liveLocation.latitude}, ${liveLocation.longitude}",
    );

    for (final stop in stops) {
      final stopLat = (stop['latitude'] ?? 0.0).toDouble();
      final stopLon = (stop['longitude'] ?? 0.0).toDouble();

      double distance = _calculateDistance(
        liveLocation.latitude,
        liveLocation.longitude,
        stopLat,
        stopLon,
      );

      if (distance < 100 && _lastAnnouncedStop != stop['stopname']) {
        _lastAnnouncedStop = stop['stopname'];

        String localFilePath = stop['localPath'] ?? '';
        String firebaseUrl = stop['url'] ?? '';

        // 🔹 If no direct localPath, retry lookup in localPaths
        if (localFilePath.isEmpty) {
          final prefs = await SharedPreferences.getInstance();
          final localPathData = prefs.getString('localPaths');
          if (localPathData != null) {
            final localData = jsonDecode(localPathData);

            final normalizedName = (stop['stopname'] ?? "")
                .toString()
                .toLowerCase()
                .replaceAll(" ", "");

            localFilePath = localData.values.firstWhere(
              (path) => path.toString().contains("$normalizedName.mp3"),
              orElse: () => '',
            );
          }
        }

        // 🔹 Priority: Local -> Firebase
        if (localFilePath.isNotEmpty) {
          await _playStopAudio(localFilePath);
          debugPrint('✅ Playing local stop audio: $localFilePath');
        } else if (firebaseUrl.isNotEmpty) {
          await _playStopAudio(firebaseUrl, isRemote: true);
          debugPrint('🌐 Playing Firebase stop audio: $firebaseUrl');
        } else {
          debugPrint("❌ No audio found for stop: ${stop['stopname']}");
        }

        debugPrint('✅ Announced stop: ${stop['stopname']}');

        // 🔹 Emit stopName to UI
        _stopController.add(stop['stopname']);

        // Hide banner after 5s (or when audio finishes, whichever is longer)
        Future.delayed(const Duration(seconds: 5), () {
          _stopController.add(null);
        });

        break; // announce only one stop per cycle
      }
    }
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double radius = 6371;
    double dLat = _degToRad(lat2 - lat1);
    double dLon = _degToRad(lon2 - lon1);

    double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) *
            cos(_degToRad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return radius * c * 1000; // in meters
  }

  double _degToRad(double degree) => degree * (pi / 180);

  /// 🔊 Play audio with priority over video (enhanced version)
  Future<void> _playStopAudio(String path, {bool isRemote = false}) async {
    if (_audioPlayer == null) {
      debugPrint("❌ Audio player not initialized");
      return;
    }

    try {
      // Stop any currently playing audio first
      await _audioPlayer!.stop();

      // Reconfigure for maximum priority
      await _audioPlayer!.setVolume(1.0);

      debugPrint("🎶 Starting to play audio: $path");

      if (isRemote) {
        await _audioPlayer!.play(UrlSource(path));
      } else {
        await _audioPlayer!.play(DeviceFileSource(path));
      }

      // Listen for completion
      _audioPlayer!.onPlayerComplete.listen((event) {
        debugPrint("🎶 Stop announcement audio finished");

        // Optional: Reset audio context after announcement
        _configureAudioPlayer();
      });

      // Listen for any errors
      _audioPlayer!.onPlayerStateChanged.listen((state) {
        debugPrint("🎶 Audio player state: $state");
      });
    } catch (e) {
      debugPrint("🔥 Error playing stop audio: $e");

      // Try to recover by reinitializing audio player
      try {
        _audioPlayer?.dispose();
        _audioPlayer = AudioPlayer();
        await _configureAudioPlayer();
        debugPrint("🔄 Audio player reinitialized after error");
      } catch (recoveryError) {
        debugPrint("🔥 Failed to recover audio player: $recoveryError");
      }
    }
  }
}
