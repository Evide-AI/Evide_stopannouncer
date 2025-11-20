import 'dart:developer';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:better_player_plus/better_player_plus.dart';
import 'package:evide_stop_announcer_app/core/app_imports.dart';
import 'package:evide_stop_announcer_app/core/common/bus_data_cubit/bus_data_cubit.dart';
import 'package:evide_stop_announcer_app/core/constants/app_global_keys.dart';
import 'package:evide_stop_announcer_app/core/constants/backend_constants.dart';
import 'package:evide_stop_announcer_app/core/services/kiosk_mode_service.dart';
import 'package:evide_stop_announcer_app/core/services/websocket_services.dart';
import 'package:evide_stop_announcer_app/features/ads_play_page/presentation/widgets/ads_play_page_common_loading_widget.dart';
import 'package:evide_stop_announcer_app/features/install_app_list_page/installed_apps_list_page.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class AdsPlayPage extends StatefulWidget {
  const AdsPlayPage({super.key});

  @override
  State<AdsPlayPage> createState() => _AdsPlayPageState();
}

class _AdsPlayPageState extends State<AdsPlayPage> with WidgetsBindingObserver{
  BetterPlayerController? _betterPlayerController;
  AudioPlayer audioPlayer = AudioPlayer();
  String inputCode = "";
  bool isKioskEnabled = true;
  int currentVideoIndex = 0;
  List<String> _videoList = [];
  late io.Socket socket;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ensureKioskMode();
    initializeSocket();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BusDataCubit>().getBusData();
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          WebSocketServices.connectAndListenToSocket(
            socket: socket, context: context,
            audioPlayer: audioPlayer,
            playStopAudioAndHandleVideoVolume: ({required String audioUrl}) {
              /// 🔇 Mute video before playing stop audio
                _betterPlayerController?.videoPlayerController?.setVolume(0.0);

                audioPlayer.play(UrlSource(audioUrl));

                /// 🟢 When stop audio completes – restore video volume
                Future.delayed(Duration(seconds: 1), () {
                  audioPlayer.onPlayerComplete.listen((event) {
                    _betterPlayerController?.videoPlayerController?.setVolume(
                      0.01,
                    );
                  });
                });
            }
          );
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

  Future<void> _ensureKioskMode() async {
    if (isKioskEnabled) {
      await KioskModeService.enableKioskMode();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _ensureKioskMode();
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }


  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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

  // method to handle key input for admin access
  Future<void> _onKeyInput(String value) async {
    inputCode += value;
    // limit to last 6 digits (since secret key length is 6)
    if (inputCode.length > 6) {
      inputCode = inputCode.substring(inputCode.length - 6);
    }

    if (inputCode == AppGlobalKeys.appAdminAccessSecretKey) {
      final installedApps = await AppCommonMethods.getAllInstalledApps();
      if (mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) {
              return InstalledAppsListPage(installedApps: installedApps);
            },
          ),
        );
      }
      inputCode = "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      autofocus: true,
      focusNode: FocusNode(),
      onKeyEvent: (event) {
        // Only handle key down events
        if (event is KeyDownEvent) {
          final key = event.logicalKey.keyLabel;
          if (key.isNotEmpty && int.tryParse(key) != null) {
            _onKeyInput(key);
          }
        }
      },
      child: MultiBlocListener(
        listeners: [
          BlocListener<BusDataCubit, BusDataState>(listener: (context, state) async {
            if (state.status == BusDataStatus.loaded) {
              // initialize video player with first video
            if (state.busData.adVideos?.isNotEmpty ?? false) {
                _videoList = state.localVideoPaths; // Store all video paths
                currentVideoIndex = 0;
                await initializeVideo(index: currentVideoIndex);
              }

            // Update video list if stream updates
            if (state.localVideoPaths.isNotEmpty) {
              _videoList = state.localVideoPaths;
            }
      
            // Start streaming video updates
            if (mounted) {
              context.read<BusDataCubit>().getVideosToPlay();
            }
            }
          },),
        ],
        child: BlocBuilder<BusDataCubit, BusDataState>(builder: (context, state) {
          if (state.status == BusDataStatus.loading || state.status == BusDataStatus.error) {
            return commonLoadingWidget();
          }
      
          if (_betterPlayerController == null) {
            return commonLoadingWidget();
          }
      
          return Scaffold(
            body: Center(
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: BetterPlayer(controller: _betterPlayerController!),
              ),
            ),
            floatingActionButton: TextButton(
              onPressed: () {
                // For testing: Skip to next video
                KioskModeService.disableKioskMode();
              },
              child: Text(
                "Exit Kiosk Mode",
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          );
        },),
      ),
    );
  }
}
