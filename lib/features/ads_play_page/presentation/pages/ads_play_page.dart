import 'dart:developer';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:better_player_plus/better_player_plus.dart';
import 'package:evide_stop_announcer_app/core/app_imports.dart';
import 'package:evide_stop_announcer_app/core/common/bus_data_cubit/bus_data_cubit.dart';
import 'package:evide_stop_announcer_app/core/constants/backend_constants.dart';
import 'package:evide_stop_announcer_app/core/services/websocket_services.dart';
import 'package:evide_stop_announcer_app/features/ads_play_page/presentation/dialogs/current_stop_data_showing_dialog.dart';
import 'package:evide_stop_announcer_app/features/ads_play_page/presentation/widgets/ads_play_page_common_loading_widget.dart';
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
    initializeSocket();
    context.read<BusDataCubit>().getBusData();
  }

  initializeSocket() {
    // socket = io.io(
    //   BackendConstants.webSocketUrl,
    //   io.OptionBuilder()
    //       .setTransports(['websocket', 'polling'])
    //       .setPath('/socket.io/')
    //       .enableReconnection()
    //       .setReconnectionDelay(1000)
    //       .setReconnectionDelayMax(5000)
    //       .setReconnectionAttempts(5)
    //       .setTimeout(20000)
    //       .build(),
    // );
    socket = io.io(
    BackendConstants.webSocketUrl,
    io.OptionBuilder()
        .setTransports(['websocket']) // Prefer pure websocket
        .enableReconnection()
        .setReconnectionAttempts(10)
        .setReconnectionDelay(2000) // 2 seconds
        .setReconnectionDelayMax(10000) // 10 seconds
        .setTimeout(30000) // 30s connection timeout
        .build(),
  );
  }

  @override
  void dispose() {
    // _betterPlayerController?.dispose();
    _betterPlayerController?.pause();
    _betterPlayerController?.dispose(forceDispose: true);
    socket.disconnect();
    socket.dispose();
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
    log("Error initializing video: $e");
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
    log("Failed to play next video: $e");
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
    return MultiBlocListener(
      listeners: [
        BlocListener<BusDataCubit, BusDataState>(listener: (context, state) async {
          if (state is BusDataLoadedState) {
            // here if state is BusDataLoadedState, we can connect to socket after getting active trip data
            context.read<BusDataCubit>().getActiveTrip(busId: state.busData.busId ?? 0, socket: socket);
            // initialize video player with first video
          if (state.busData.adVideos?.isNotEmpty ?? false) {
              _videoList = state.localVideoPaths; // Store all video paths
              currentVideoIndex = 0;
              await initializeVideo(index: currentVideoIndex);
            }
          }
        },),
      ],
      child: BlocBuilder<BusDataCubit, BusDataState>(builder: (context, state) {
        if (state is BustDataLoadingState) {
          return adsPlayPageCommonLoadingWidget();
        }

        if (_betterPlayerController == null) {
          return adsPlayPageCommonLoadingWidget();
        }

        return Scaffold(
          body: Center(
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: BetterPlayer(controller: _betterPlayerController!),
            ),
          ),
        );
      },),
    );
  }
}
