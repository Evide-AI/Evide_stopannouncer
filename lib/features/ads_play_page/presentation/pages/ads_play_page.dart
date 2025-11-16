import 'dart:developer';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:better_player_plus/better_player_plus.dart';
import 'package:evide_stop_announcer_app/core/app_imports.dart';
import 'package:evide_stop_announcer_app/core/common/bus_data_cubit/bus_data_cubit.dart';
import 'package:evide_stop_announcer_app/core/constants/backend_constants.dart';
import 'package:evide_stop_announcer_app/core/services/websocket_services.dart';
import 'package:evide_stop_announcer_app/features/ads_play_page/presentation/widgets/ads_play_page_common_loading_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class AdsPlayPage extends StatefulWidget {
  const AdsPlayPage({super.key});

  @override
  State<AdsPlayPage> createState() => _AdsPlayPageState();
}

class _AdsPlayPageState extends State<AdsPlayPage> {
  BetterPlayerController? _betterPlayerController;
  AudioPlayer audioPlayer = AudioPlayer();
  int currentVideoIndex = 0;
  List<String> _videoList = [];
  late io.Socket socket;
  int? lastShownStopSequence;

  @override
  void initState() {
    super.initState();
    initializeSocket();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BusDataCubit>().getBusData();
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          WebSocketServices.connectAndListenToSocket(socket: socket, context: context, betterPlayerController: _betterPlayerController, audioPlayer: audioPlayer);
        }
      });
    });
  }

  initializeSocket() {
    socket = io.io(
      BackendConstants.webSocketUrl,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .setPath('/socket.io/')
          .enableReconnection()
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(5000)
          .setReconnectionAttempts(20)
          .setTimeout(60000)
          .build(),
    );
  }

  // void connectAndListenToSocket() {
  //   // on connection established join the trip room
  //   socket.onConnect((_) {
  //     final busData = context.read<BusDataCubit>().state.busData;
  //     log('🟢 Socket Connected: ${socket.id}');
  //     final tripId = busData.activeTripTimelineModel?.tripDetails?.id;
  //     if (tripId != null) {
  //       log('🚍 Joining trip: $tripId');
  //       socket.emit('join-trip', {'tripId': tripId});
  //     }
  //   });

  //   // if joined trip
  //   socket.on('joined-trip', (data) => log('✅ Joined trip: $data'));

  //   // if trip ended fetch new trip data of the bus
  //  socket.on("trip-ended", (data) {
  //   log('🏁 Trip ended: $data');
  //   // Leave previous trip room
  //   if (data != null && data['tripId'] != null) {
  //     socket.emit("leave-trip", { "tripId": data['tripId'] });
  //   }
  //   // Fetch new bus data
  //   context.read<BusDataCubit>().getBusData();
  // });

  //   // if disconnected
  //   socket.onDisconnect((reason) => log('🔴 Disconnected: $reason'));
  //     socket.onError((data) => log('🚨 Socket Error: $data'));

  //   // on error (like trip not found or not active)
  //   socket.on('error', (error) {log('❌ Server Error: $error');});

  //   // on gps location update
  //   socket.on('location-update', (data) {
  //     final jsonData = data is String ? jsonDecode(data) : data;
  //     final currentStopSequenceNumber = jsonData['current_stop_sequence_number'];
  //     log("📍 location data: $jsonData");

  //     try {
  //       for (StopEntity stop in context.read<BusDataCubit>().state.busData.activeTripTimelineModel?.stopList ?? []) {
  //         if (stop.sequenceOrder == currentStopSequenceNumber) {
  //           log('🏁 Arrived: ${stop.stopName}');

  //           if (lastShownStopSequence != currentStopSequenceNumber) {
  //             // PLAY AUDIO
  //             final audioUrl = context.read<BusDataCubit>().state.busData.stopAudios?[stop.stopId.toString()];
  //             if (audioUrl != null) {
  //               /// 🔇 Mute video before playing stop audio
  //               _betterPlayerController?.videoPlayerController?.setVolume(0.0);

  //               audioPlayer.play(UrlSource(audioUrl));

  //               /// 🟢 When stop audio completes – restore video volume
  //               Future.delayed(Duration(seconds: 1), () {
  //                 audioPlayer.onPlayerComplete.listen((event) {
  //                   _betterPlayerController?.videoPlayerController?.setVolume(0.01);
  //                 });
  //               },);
  //             }

  //             // SHOW DIALOG
  //             currentStopDataShowingDialog(
  //               context: AppGlobalKeys.navigatorKey.currentState!.overlay!.context,
  //               stopName: stop.stopName ?? 'Unknown Stop',
  //             );
  //           }
  //           lastShownStopSequence = currentStopSequenceNumber;
  //         }
  //       }
  //     } catch (e) {
  //       log('❌ Error parsing location-update: $e');
  //     }
  //   });

  //   // on connection error occured
  //   socket.onConnectError((data) {
  //     log('❌ Socket Connect Error: $data');
  //   });

  //   // connect the socket
  //   socket.connect(); // only once
  // }


  @override
  void dispose() {
    // _betterPlayerController?.dispose();
    _betterPlayerController?.pause();
    _betterPlayerController?.dispose(forceDispose: true);
    socket.disconnect();
    socket.dispose();
    audioPlayer.dispose();
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

    _betterPlayerController?.setVolume(0.01);
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
          if (state.status == BusDataStatus.loaded) {
            if (state.busData.activeTripTimelineModel?.tripDetails?.id != null) {
              log('🚍 Joining trip: ${state.busData.activeTripTimelineModel?.tripDetails?.id}');
              socket.emit('join-trip', {'tripId': state.busData.activeTripTimelineModel?.tripDetails?.id});
            }
            // here if state is BusDataLoadedState, we can connect to socket after getting active trip data
            // context.read<BusDataCubit>().getActiveTrip(busId: state.busData.busId ?? 0, socket: socket, audioPlayer: audioPlayer);
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
        if (state.status == BusDataStatus.loading || state.status == BusDataStatus.error) {
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
