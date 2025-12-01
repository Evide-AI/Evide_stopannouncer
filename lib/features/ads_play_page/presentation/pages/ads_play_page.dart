import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:better_player_plus/better_player_plus.dart';
import 'package:evide_stop_announcer_app/core/app_imports.dart';
import 'package:evide_stop_announcer_app/core/common/bus_data_cubit/bus_data_cubit.dart';
import 'package:evide_stop_announcer_app/core/common/bus_data_domain/entity/timeline_entity.dart';
import 'package:evide_stop_announcer_app/core/constants/app_global_keys.dart';
import 'package:evide_stop_announcer_app/core/constants/backend_constants.dart';
import 'package:evide_stop_announcer_app/core/services/kiosk_mode_service.dart';
import 'package:evide_stop_announcer_app/core/services/websocket_services.dart';
import 'package:evide_stop_announcer_app/features/ads_play_page/presentation/dialogs/current_stop_data_showing_dialog.dart';
import 'package:evide_stop_announcer_app/features/ads_play_page/presentation/widgets/ads_play_page_common_loading_widget.dart';
import 'package:evide_stop_announcer_app/features/install_app_list_page/installed_apps_list_page.dart';
import 'package:evide_stop_announcer_app/features/install_app_list_page/settings_open_option_selection_page.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class AdsPlayPage extends StatefulWidget {
  const AdsPlayPage({super.key});

  @override
  State<AdsPlayPage> createState() => _AdsPlayPageState();
}

class _AdsPlayPageState extends State<AdsPlayPage> with WidgetsBindingObserver{
  late FocusNode _focusNode;
  BetterPlayerController? _betterPlayerController;
  AudioPlayer audioPlayer = AudioPlayer();
  String inputCode = "";
  bool isKioskEnabled = true;
  int currentVideoIndex = 0;
  List<String> _videoList = [];
  late io.Socket socket;
  int? lastShownStopSequence;

  @override
  void initState() {
    super.initState();
    // focusnode for key event focusing
    _focusNode = FocusNode();
    WidgetsBinding.instance.addObserver(this);
    _ensureKioskMode(); // enabling kiosk mode
    initializeSocket(); // initializing socket
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus(); //requesting focus after widget once builded completely
      setupBusDataListener();
      context.read<BusDataCubit>().getBusData(); // method for getting bus and its active trip data
      setUpSocketListners(); // setting up socket listeners
      socket.connect(); // connecting socket
    });
  }
  // method for join trip after bus data loaded fully (backup method to avoid trip join issue)
  void setupBusDataListener() {
    context.read<BusDataCubit>().stream.listen((state) {
      if (state.status == BusDataStatus.loaded) {
        final tripId =
            state.busData.activeTripTimelineModel?.tripDetails?.id;

        if (tripId != null && socket.connected) {
          log("🔄 BusData Loaded → Joining Trip Again: $tripId");
          socket.emit("join-trip", {"tripId": tripId});
        }
      }
    });
  }

  // setting socket listeners for up-to date data
  void setUpSocketListners() {
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
                0.3,
              );
            });
          });
        }
      );
  }
  // initializing socket
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
    // calling method for enable kiosk mode
    if (isKioskEnabled) {
      await KioskModeService.enableKioskMode();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // on app resume, enabling kiosk mode
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
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> initializeVideo({required int index}) async {
  if (_videoList.isEmpty) return;

  final videoFile = File(_videoList[index]);
  // checking video file exits or not, if not skip to next video
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
    // disposing player controller to avoid memory leaks
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
    // setting video volume low as possible
    _betterPlayerController?.setVolume(0.3);
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
    // if inputcode matches secret key, then will go to device settings access page
    if (inputCode == AppGlobalKeys.appAdminAccessSecretKey) {
      if (mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) {
              return SettingsOpenOptionSelectionPage();
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
      focusNode: _focusNode,
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
              final newList = state.localVideoPaths;

              // If list changed -> update & reinitialize
              if (!AppCommonMethods.listEquals(_videoList, newList)) {
                _videoList = List<String>.from(newList);  // defensive copy

                if (_videoList.isNotEmpty) {
                  currentVideoIndex = 0;
                  await initializeVideo(index: currentVideoIndex);
                }
              }

              // Start fetching remote updates only once
              if (context.mounted) {
                context.read<BusDataCubit>().getVideosAndAudiosToPlay();
              }
            }
          },),
        ],
        child: BlocBuilder<BusDataCubit, BusDataState>(builder: (context, state) {
          if ((state.status == BusDataStatus.error) && state.localVideoPaths.isEmpty) {
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
          );
        },),
      ),
    );
  }
}
