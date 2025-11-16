import 'dart:convert';
import 'dart:developer';
import 'package:audioplayers/audioplayers.dart';
import 'package:better_player_plus/better_player_plus.dart';
import 'package:evide_stop_announcer_app/core/app_imports.dart';
import 'package:evide_stop_announcer_app/core/common/bus_data_cubit/bus_data_cubit.dart';
import 'package:evide_stop_announcer_app/core/common/bus_data_domain/entity/timeline_entity.dart';
import 'package:evide_stop_announcer_app/core/constants/app_global_keys.dart';
import 'package:evide_stop_announcer_app/features/ads_play_page/presentation/dialogs/current_stop_data_showing_dialog.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class WebSocketServices {
  static int? lastShownStopSequence;

  static void connectAndListenToSocket({required io.Socket socket, required BuildContext context, required BetterPlayerController? betterPlayerController, required AudioPlayer audioPlayer}) {
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

    // if joined trip
    socket.on('joined-trip', (data) => log('✅ Joined trip: $data'));

    // if trip ended fetch new trip data of the bus
    socket.on("trip-ended", (data) {
      log('🏁 Trip ended: $data');
      // Leave previous trip room
      if (data != null && data['tripId'] != null) {
        socket.emit("leave-trip", {"tripId": data['tripId']});
      }
      // Fetch new bus data
      context.read<BusDataCubit>().getBusData();
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
                /// 🔇 Mute video before playing stop audio
                betterPlayerController?.videoPlayerController?.setVolume(0.0);

                audioPlayer.play(UrlSource(audioUrl));

                /// 🟢 When stop audio completes – restore video volume
                Future.delayed(Duration(seconds: 1), () {
                  audioPlayer.onPlayerComplete.listen((event) {
                    betterPlayerController?.videoPlayerController?.setVolume(
                      0.01,
                    );
                  });
                });
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

    // connect the socket
    socket.connect(); // only once
  }
}
