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
    socket.on('location-update', (data) {
      final jsonData = data is String ? jsonDecode(data) : data;
      final currentStopSequenceNumber = jsonData["current_stop_sequence_number"];
      final nextstopSequenceNumber = jsonData["next_stop_sequence_number"];
      final currentStopName = jsonData["current_stop_name"];
      final nextStopName = jsonData["next_stop_name"];
      final distanceToNextStopInMeters = jsonData["distance_to_next_stop_meters"];
      log("📍 location data: $jsonData");
      // try {
      //   final stops = context.read<BusDataCubit>().state.busData.activeTripTimelineModel?.stopList ?? [];

      //   for (int i = 0; i < stops.length; i++) {
      //     final stop = stops[i];

      //     // CHECK CURRENT STOP MATCH
      //     if (stop.sequenceOrder == currentStopSequenceNumber) {
      //       log('🏁 Arrived Current Stop: ${stop.stopName}');
      //       if (isSecondUpdateFromGpsAfterCurrentStopReached) {
      //         // reading the totalDistance to next stop only once means at the time the bus reached the stop
      //         // totalDistanceToNextStop = distanceToNextStopInMeters;
      //         if (distanceToNextStopInMeters > 500) {
      //           totalDistanceToNextStop = distanceToNextStopInMeters;
      //           isSecondUpdateFromGpsAfterCurrentStopReached = false;
      //         }
      //         // isSecondUpdateFromGpsAfterCurrentStopReached = false;
      //       }

      //       // Prevent repeating for same stop
      //       if (lastShownStopSequence == currentStopSequenceNumber) continue;
      //       if (lastShownStopSequence != currentStopSequenceNumber) {
      //         isSecondUpdateFromGpsAfterCurrentStopReached = true;
      //       }
      //       lastShownStopSequence = currentStopSequenceNumber;
      //       // if (lastShownStopSequence != currentStopSequenceNumber) {
      //       //   // reading the totalDistance to next stop only once means at the time the bus reached the stop
      //       //   totalDistanceToNextStop = distanceToNextStopInMeters;
      //       // }
      //       // ----------------------------------------------------
      //       // GET CURRENT STOP DATA
      //       // ----------------------------------------------------
      //       final stopId = stop.stopId?.toString();
      //       final stopAudioMap = context.read<BusDataCubit>().state.busData.stopAudios?[stopId];

      //       final currentStopAudio = stopAudioMap?["stop_audio_url"];
      //       final currentStopNameInMalayalam = stopAudioMap?["stop_name"];


      //       log("🎵 Current Stop Audio: $currentStopAudio");

      //       // Play current audio
      //       if (currentStopAudio != null) {
      //         playStopAudioAndHandleVideoVolume(audioUrl: currentStopAudio);
      //       }
      //       // Show current stop dialog
      //       currentStopDataShowingDialog(
      //         isCurrentStop: true,
      //         isAudioPresent: currentStopAudio != null,
      //         context: AppGlobalKeys.navigatorKey.currentState!.overlay!.context,
      //         stopName: currentStopName,
      //         stopNameInMalayalam: currentStopNameInMalayalam,
      //       );

      //       lastShownStopSequence = currentStopSequenceNumber;
      //       isNextStopAlreadyShown = false;
      //     }
      //   }

      //   // ----------------------------------------------------
      //   // GET NEXT STOP DATA
      //   // ----------------------------------------------------
      //   if (totalDistanceToNextStop != null) {
      //     if (totalDistanceToNextStop! > 500 && (distanceToNextStopInMeters != null && distanceToNextStopInMeters <= 200 && !isNextStopAlreadyShown)) {
      //       StopEntity? nextStop;
      //       try {
      //         nextStop = stops.firstWhere(
      //           (s) => s.sequenceOrder == nextstopSequenceNumber,
      //         );
      //       } on StateError {
      //         // firstWhere throws StateError if no element found
      //         nextStop = null;
      //       }

      //       final nextStopId = nextStop?.stopId?.toString();
      //       final nextStopAudioMap = context.read<BusDataCubit>().state.busData.stopAudios?[nextStopId];

      //       final nextStopAudio = nextStopAudioMap?["stop_audio_url"];
      //       final nextStopNameInMalayalam = nextStopAudioMap?["stop_name"];

      //       // Play NEXT audio
      //       if (nextStopAudio != null) {
      //         playStopAudioAndHandleVideoVolume(audioUrl: nextStopAudio);
      //       }
      //       if (nextStopName != null) {
      //         // Show next stop dialog
      //         currentStopDataShowingDialog(
      //           isCurrentStop: false,
      //           isAudioPresent: nextStopAudio != null,
      //           context: AppGlobalKeys.navigatorKey.currentState!.overlay!.context,
      //           stopName: nextStopName,
      //           stopNameInMalayalam: nextStopNameInMalayalam,
      //         );
      //       }
      //       // assigning true to isNextStopAlreadyShown to prevent showing dialog multiple time for same stop
      //       isNextStopAlreadyShown = true;
      //     }
      //   }

      // } catch (e) {
      //   log('❌ Error parsing location-update: $e');
      // }
       try {
        final stops = context.read<BusDataCubit>().state.busData.activeTripTimelineModel?.stopList ?? [];

        bool isCurrentStopMatched = false;

        // ----------------------------------------------------
        // 🔴 1. CURRENT STOP LOGIC
        // ----------------------------------------------------
        for (int i = 0; i < stops.length; i++) {
          final stop = stops[i];

          if (stop.sequenceOrder == currentStopSequenceNumber) {

            log('🏁 Arrived Current Stop: ${stop.stopName}');

            // Read total distance once, only after reaching stop
            if (isSecondUpdateFromGpsAfterCurrentStopReached) {
              if (distanceToNextStopInMeters > 500) {
                totalDistanceToNextStop = distanceToNextStopInMeters;
                isSecondUpdateFromGpsAfterCurrentStopReached = false;
              }
            }

            // Prevent repeating same stop dialog
            if (lastShownStopSequence == currentStopSequenceNumber) break;

            if (lastShownStopSequence != currentStopSequenceNumber) {
              isSecondUpdateFromGpsAfterCurrentStopReached = true;
            }

            lastShownStopSequence = currentStopSequenceNumber;
            isNextStopAlreadyShown = false;

            // ---- CURRENT STOP DATA ----
            final stopId = stop.stopId?.toString();
            final stopAudioMap = context.read<BusDataCubit>().state.busData.stopAudios?[stopId];

            final currentStopAudio = stopAudioMap?["stop_audio_url"];
            final currentStopNameInMalayalam = stopAudioMap?["stop_name"];

            log("🎵 Current Stop Audio: $currentStopAudio");

            // Play current stop audio
            if (currentStopAudio != null) {
              playStopAudioAndHandleVideoVolume(audioUrl: currentStopAudio);
            }

            // Show current stop dialog
            currentStopDataShowingDialog(
              isCurrentStop: true,
              isAudioPresent: currentStopAudio != null,
              context: AppGlobalKeys.navigatorKey.currentState!.overlay!.context,
              stopName: currentStopName,
              stopNameInMalayalam: currentStopNameInMalayalam,
            );

            break; // No need to check further stops
          }
        }

        // ----------------------------------------------------
        // 🔵 2. NEXT STOP LOGIC (ONLY WHEN NOT AT CURRENT STOP)
        // ----------------------------------------------------
          if (lastShownStopSequence == currentStopSequenceNumber && totalDistanceToNextStop != null && totalDistanceToNextStop! > 500 && distanceToNextStopInMeters != null && distanceToNextStopInMeters <= 200 && !isNextStopAlreadyShown) {

            StopEntity? nextStop;
            try {
              nextStop = stops.firstWhere(
                (s) => s.sequenceOrder == nextstopSequenceNumber,
              );
            } catch (_) {
              nextStop = null;
            }

            final nextStopId = nextStop?.stopId?.toString();
            final nextStopAudioMap =
                context.read<BusDataCubit>().state.busData.stopAudios?[nextStopId];

            final nextStopAudio = nextStopAudioMap?["stop_audio_url"];
            final nextStopNameInMalayalam = nextStopAudioMap?["stop_name"];

            // Play next stop audio
            if (nextStopAudio != null) {
              playStopAudioAndHandleVideoVolume(audioUrl: nextStopAudio);
            }

            // Show next stop dialog
            if (nextStopName != null) {
              currentStopDataShowingDialog(
                isCurrentStop: false,
                isAudioPresent: nextStopAudio != null,
                context: AppGlobalKeys.navigatorKey.currentState!.overlay!.context,
                stopName: nextStopName,
                stopNameInMalayalam: nextStopNameInMalayalam,
              );
            }

            isNextStopAlreadyShown = true;
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
