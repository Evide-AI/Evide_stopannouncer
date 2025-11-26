import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:audioplayers/audioplayers.dart';
import 'package:evide_stop_announcer_app/core/app_imports.dart';
import 'package:evide_stop_announcer_app/core/common/bus_data_cubit/bus_data_cubit.dart';
import 'package:evide_stop_announcer_app/core/common/bus_data_domain/entity/timeline_entity.dart';
import 'package:evide_stop_announcer_app/core/constants/app_global_keys.dart';
import 'package:evide_stop_announcer_app/features/ads_play_page/presentation/dialogs/current_stop_data_showing_dialog.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class WebSocketServices {
  static int? lastShownStopSequence;
  static Timer? tripCheckerTimer;
  static int? currentActiveTripId;
  static double? totalDistanceToNextStop;
  static bool isNextStopAlreadyShown = false;
  static bool isSecondUpdateFromGpsAfterCurrentStopReached = false;


  static void connectAndListenToSocket({required io.Socket socket, required BuildContext context, required void Function({required String audioUrl}) playStopAudioAndHandleVideoVolume, required AudioPlayer audioPlayer}) {
    // on connection established join the trip room
    socket.onConnect((_) {
      final busData = context.read<BusDataCubit>().state.busData;
      log('🟢 Socket Connected: ${socket.id}');
      final tripId = busData.activeTripTimelineModel?.tripDetails?.id;
      currentActiveTripId = tripId;
      if (tripId != null) {
        log('🚍 Joining trip: $tripId');
        socket.emit('join-trip', {'tripId': tripId});
      }
      // starting trip watch of the bus
      startTripWatcher(context: context, socket: socket);
    });

    // if joined trip
    socket.on('joined-trip', (data) => log('✅ Joined trip: $data'));

    // if trip ended fetch new trip data of the bus
    socket.on("trip-ended", (data) {
      log('🏁 Trip ended: $data');
      // Leave previous trip room
      if (data != null && data['tripId'] != null) {
        socket.emit("leave-trip", {"tripId": data['tripId']});
      }
    });

    // if disconnected
    socket.onDisconnect((reason) => log('🔴 Disconnected: $reason'));
    socket.onError((data) => log('🚨 Socket Error: $data'));

    // on error (like trip not found or not active)
    socket.on('error', (error) {
      log('❌ Server Error: $error');
    });

    // on gps location update
    socket.on('location-update', (data) async {
      final jsonData = data is String ? jsonDecode(data) : data;
      final currentStopSequenceNumber = jsonData["current_stop_sequence_number"];
      final nextstopSequenceNumber = jsonData["next_stop_sequence_number"];
      final currentStopName = jsonData["current_stop_name"];
      final nextStopName = jsonData["next_stop_name"];
      // final distanceToNextStopInMeters = jsonData["distance_to_next_stop_meters"];
      log("📍 location data: $jsonData");
      try {
        final stops = context.read<BusDataCubit>().state.busData.activeTripTimelineModel?.stopList ?? [];
        
        // Iterate through the loop to find the current stop and show dialog
        for (int i = 0; i < stops.length; i++) {
          final stop = stops[i];

          // CHECK CURRENT STOP MATCH
          if (stop.sequenceOrder == currentStopSequenceNumber) {
            log('🏁 Arrived Current Stop: ${stop.stopName}');

            // Prevent repeating for same stop
            if (lastShownStopSequence == currentStopSequenceNumber) return; //if lastShownStopSequence and currentStopSequenceNumber matches then return from this loop

            lastShownStopSequence = currentStopSequenceNumber; // assigning current stop sequence number to lastShownStopSequence
            // ----------------------------------------------------
            // GET CURRENT STOP DATA
            // ----------------------------------------------------
            processCurrentStopAudioAndDialog(stopId: stop.stopId?.toString(), busData: busData, currentStopName: currentStopName, playStopAudioAndHandleVideoVolume: playStopAudioAndHandleVideoVolume);
            // Next stop
            Future.delayed(Duration(seconds: 15), () {
              processNextStopAudioAndDialog(nextStopName: nextStopName, stops: stops, nextstopSequenceNumber: nextstopSequenceNumber, playStopAudioAndHandleVideoVolume: playStopAudioAndHandleVideoVolume, busData: busData);
            },);
            // setting current stop sequence number to lastShownStopSequence (It is for avoid again showing dialog for current stop even if new update come for the same stop)
            lastShownStopSequence = currentStopSequenceNumber;
            isNextStopAlreadyShown = false;
          }
        }
      } catch (e) {
        log('❌ Error parsing location-update: $e');
      }
    });

    // on connection error occured
    socket.onConnectError((data) {
      log('❌ Socket Connect Error: $data');
    });

    // reconnect events
    socket.onReconnect((attempt) {
      log("🟢 Socket Reconnected after $attempt attempt(s)");
      final busData = context.read<BusDataCubit>().state.busData;
      final tripId = busData.activeTripTimelineModel?.tripDetails?.id;

      if (tripId != null) {
        log('🚍 Rejoining trip room after reconnect: $tripId');
        socket.emit('join-trip', {'tripId': tripId});
      }
    });

    socket.onReconnectAttempt((attempt) {
      log("🔄 Reconnect attempt: $attempt");
    });

    socket.onReconnectError((err) {
      log("❌ Reconnect error: $err");
    });
  }

    static void processCurrentStopAudioAndDialog({
    required String? stopId, required BusDataEntity busData,required String currentStopName,
    required void Function({required String audioUrl}) playStopAudioAndHandleVideoVolume,

  }) {
    final stopAudioMap = busData.stopAudios?[stopId]; // getting current stop audio map
    final currentStopAudio = stopAudioMap?["stop_audio_url"]; // getting current stop audio
    final currentStopNameInMalayalam = stopAudioMap?["stop_name"]; // getting current stop name in malayalam
    log("🎵 Current Stop Audio: $currentStopAudio");
    getStopAudioAndDialog(stopAudio: currentStopAudio, stopName: currentStopName, stopNameInMalayalam: currentStopNameInMalayalam, playStopAudioAndHandleVideoVolume: playStopAudioAndHandleVideoVolume);
  }

  static void processNextStopAudioAndDialog({
    required String nextStopName,
    required List<StopEntity> stops,
    required int nextstopSequenceNumber,
    required void Function({required String audioUrl}) playStopAudioAndHandleVideoVolume,
    required BusDataEntity busData,
  }) {
    // GETTING NEXT STOP AND STOP ID AND STOP NAME IN MALAYALAM
    StopEntity? nextStop;
    try {
      nextStop = stops.firstWhere(
        (s) => s.sequenceOrder == nextstopSequenceNumber,
      );
    } on StateError {
      // firstWhere throws StateError if no element found
      nextStop = null;
    }
    // getting next stop id
    final nextStopId = nextStop?.stopId?.toString();
    final nextStopAudioMap = busData.stopAudios?[nextStopId]; //getting next stop audio and name containing map
    final nextStopNameInMalayalam = nextStopAudioMap?["stop_name"]; // getting next stop name in malayalam
    final nextStopAudio = nextStopAudioMap?["next_stop_audio"];  //getting next stop audio url
    getStopAudioAndDialog(stopAudio: nextStopAudio, stopName: nextStopName, stopNameInMalayalam: nextStopNameInMalayalam, playStopAudioAndHandleVideoVolume: playStopAudioAndHandleVideoVolume);
  }


  static void getStopAudioAndDialog({
    required String? stopAudio,
    required String stopName,
    required String stopNameInMalayalam,
    required void Function({required String audioUrl}) playStopAudioAndHandleVideoVolume,
  }) {
    if (stopAudio != null) { //if stop audio not null, will play the audio
      playStopAudioAndHandleVideoVolume(audioUrl: stopAudio);
    }
    // showing stop dialog
    currentStopDataShowingDialog(
      isCurrentStop: false,
      context: AppGlobalKeys.navigatorKey.currentState!.overlay!.context,
      stopName: stopName,
      stopNameInMalayalam: stopNameInMalayalam,
    );
  }

  // method for watch the trip of the current bus and
  // if there is any trip active and it is not joined via socket to the room,
  // it will join the room with new trip id and
  // continues listening to the updates coming from the socket
  static void startTripWatcher({required BuildContext context, required io.Socket socket}) {
    // Cancel previous watcher if any
    tripCheckerTimer?.cancel();

    tripCheckerTimer = Timer.periodic(const Duration(seconds: 40), (_) async {
      final busDataCubit = context.read<BusDataCubit>();

      // Fetch the bus and its active trip data
      await busDataCubit.getBusData(isLoadingNeeded: false);

      final busData = busDataCubit.state.busData;
      final newActiveTripId = busData.activeTripTimelineModel?.tripDetails?.id;

      // No active trip at the moment
      if (newActiveTripId == null) {
        log("🟡 No active trip for this bus currently.");
        currentActiveTripId = null;
        return;
      }

      // If trip is same then nothing to do
      if (currentActiveTripId == newActiveTripId) return;

      // Trip changed then join new room
      currentActiveTripId = newActiveTripId;

      log("🟢 New active trip detected → joining tripId: $newActiveTripId");

      socket.emit("join-trip", {"tripId": newActiveTripId});
    });
  }

}
