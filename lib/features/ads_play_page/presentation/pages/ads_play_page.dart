import 'dart:developer';
import 'dart:io';
import 'package:better_player_plus/better_player_plus.dart';
import 'package:evide_stop_announcer_app/core/app_imports.dart';
import 'package:evide_stop_announcer_app/core/common/bus_data_cubit/bus_data_cubit.dart';
import 'package:evide_stop_announcer_app/core/constants/backend_constants.dart';
import 'package:evide_stop_announcer_app/core/services/websocket_services.dart';
import 'package:evide_stop_announcer_app/core/services/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class AdsPlayPage extends StatefulWidget {
  const AdsPlayPage({super.key});

  @override
  State<AdsPlayPage> createState() => _AdsPlayPageState();
}

class _AdsPlayPageState extends State<AdsPlayPage> {
  BetterPlayerController? _betterPlayerController;
  int currentVideoIndex = 0;
  List<String> _videoList = [];
  late io.Socket socket;

  @override
  void initState() {
    super.initState();
    context.read<BusDataCubit>().getBusData();
    socket = io.io(
      BackendConstants.webSocketUrl,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .setPath('/socket.io/')
          .enableReconnection()
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(5000)
          .setReconnectionAttempts(5)
          .setTimeout(20000)
          .build(),
    );
  }

  @override
  void dispose() {
    _betterPlayerController?.dispose();
    super.dispose();
  }

  Future<void> initializeVideo({required int index}) async {
  if (_videoList.isEmpty) return;

  final videoFile = File(_videoList[index]);
  if (!videoFile.existsSync()) {
    log("⚠️ File not found: ${videoFile.path}");
    _skipToNextOnError();
    return;
  }

  try {
    final dataSource = BetterPlayerDataSource(
      BetterPlayerDataSourceType.file,
      videoFile.path,
      notificationConfiguration: const BetterPlayerNotificationConfiguration(
        showNotification: false,
      ),
    );

    _betterPlayerController?.dispose();

    _betterPlayerController = BetterPlayerController(
      BetterPlayerConfiguration(
        autoPlay: true,
        looping: false,
        handleLifecycle: true,
        allowedScreenSleep: false,
        autoDispose: true,
        eventListener: _onVideoEvent,
        controlsConfiguration: const BetterPlayerControlsConfiguration(
          showControls: false,
        ),
      ),
      betterPlayerDataSource: dataSource,
    );

    _betterPlayerController?.setVolume(0.0);
    setState(() {});
  } catch (e) {
    log("⚠️ Error initializing video: $e");
    _skipToNextOnError();
  }
}

void _skipToNextOnError() async {
  if (_videoList.isEmpty) return;

  // Try next video
  currentVideoIndex++;
  if (currentVideoIndex >= _videoList.length) {
    currentVideoIndex = 0; // restart from first
  }

  try {
    await initializeVideo(index: currentVideoIndex);
  } catch (e) {
    log("⚠️ Failed to play next video: $e");
    // recursively skip until you find a valid playable one
    _skipToNextOnError();
  }
}


  void _onVideoEvent(BetterPlayerEvent event) {
    if (event.betterPlayerEventType == BetterPlayerEventType.finished) {
      _playNextVideo();
    }
  }

  void _playNextVideo() {
    log("Video: ${_videoList[currentVideoIndex]}");
    if (_videoList.isEmpty) return;

    currentVideoIndex++;
    if (currentVideoIndex >= _videoList.length) {
      currentVideoIndex = 0; // Loop back to first video
    }

    initializeVideo(index: currentVideoIndex);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BusDataCubit, BusDataState>(
      listener: (context, state) async {
        if (state is BusDataLoadedState) {
          if (state.busData.adVideos?.isNotEmpty ?? false) {
            _videoList = state.localVideoPaths; // Store all video paths
            currentVideoIndex = 0;
            await initializeVideo(index: currentVideoIndex);
          }
        }
      },
      builder: (context, state) {
        if (state is BustDataLoadingState) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (_betterPlayerController == null) {
          return Scaffold(
            body: Center(
              child: Lottie.asset("assets/Artboard.json"),
            ),
          );
        }

        return Scaffold(
          body: Center(
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: BetterPlayer(controller: _betterPlayerController!),
            ),
          ),
        );
      },
    );
  }
}
