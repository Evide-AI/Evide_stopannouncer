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

  static void connectAndListenToSocket({required io.Socket socket, required BuildContext context, required void Function({required String audioUrl}) playStopAudioAndHandleVideoVolume, required AudioPlayer audioPlayer}) {
    // on connection established join the trip room
    socket.onConnect((_) {
      final busData = context.read<BusDataCubit>().state.busData;
      log('🟢 Socket Connected: ${socket.id}');
      final tripId = busData.activeTripTimelineModel?.tripDetails?.id;
      if (tripId != null) {
        log('🚍 Joining trip: $tripId');
        socket.emit('join-trip', {'tripId': tripId});
      }
    });

    // when new trip starts
    socket.on("trip-started", (data) {
      log("🚍 Trip Started: $data");

      try {
        final tripId = data?['tripId'];
        if (tripId != null) {
          // Fetch new trip data
          // context.read<BusDataCubit>().getBusData();

          // Join the new trip room
          socket.emit("join-trip", {"tripId": tripId});

          // Reset last shown stop, so new trip announcements work properly
          lastShownStopSequence = null;
        }
      } catch (e) {
        log('❌ Error in trip-started event: $e');
      }
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
      final currentStopSequenceNumber =
          jsonData['current_stop_sequence_number'];
      log("📍 location data: $jsonData");

      try {
        for (StopEntity stop
            in context
                    .read<BusDataCubit>()
                    .state
                    .busData
                    .activeTripTimelineModel
                    ?.stopList ??
                []) {
          if (stop.sequenceOrder == currentStopSequenceNumber) {
            log('🏁 Arrived: ${stop.stopName}');

            if (lastShownStopSequence != currentStopSequenceNumber) {
              // PLAY AUDIO
              final audioUrl = context
                  .read<BusDataCubit>()
                  .state
                  .busData
                  .stopAudios?[stop.stopId.toString()];
              if (audioUrl != null) {
                playStopAudioAndHandleVideoVolume(audioUrl: audioUrl);
              }

              // SHOW DIALOG
              currentStopDataShowingDialog(
                context:
                    AppGlobalKeys.navigatorKey.currentState!.overlay!.context,
                stopName: stop.stopName ?? 'Unknown Stop',
              );
            }
            lastShownStopSequence = currentStopSequenceNumber;
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

    // connect the socket
    socket.connect(); // only once
  }
}
