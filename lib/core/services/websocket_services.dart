import 'dart:convert';
import 'dart:developer';
import 'package:audioplayers/audioplayers.dart';
import 'package:evide_stop_announcer_app/core/common/bus_data_domain/entity/timeline_entity.dart';
import 'package:evide_stop_announcer_app/core/constants/app_global_keys.dart';
import 'package:evide_stop_announcer_app/features/ads_play_page/presentation/dialogs/current_stop_data_showing_dialog.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
class WebSocketServices {
  static int? _lastShownStopSequence;

  static void joinTrip(io.Socket socket, int tripId) {
  socket.emitWithAck('join-trip', {'tripId': tripId}, ack: (data) {
    log('🟢 Trip joined ACK: $data');
  });
}

  /// ✅ Connect to backend socket
  static void connectSocket({
    required TimeLineEntity activeTripTimelineData,
    required io.Socket socket,
    required Map<String, dynamic> stopAudios,
    required AudioPlayer audioPlayer,
  }) {
    socket.connect();
    socket.onConnect((_) {
      log('🟢 Connected: ${socket.id}');
      final tripId = activeTripTimelineData.tripDetails?.id;
      if (tripId != null) {
        joinTrip(socket, tripId);
      }
    });

    socket.onReconnect((attempt) {
      log('🔄 Reconnected (attempt $attempt)');
      final tripId = activeTripTimelineData.tripDetails?.id;
      if (tripId != null) {
        joinTrip(socket, tripId);
      }
    });


    socket.onDisconnect((reason) {
      log('🔴 Disconnected: $reason');
    });
    socket.onError((data) => log('🚨 Socket Error: $data'));
    socket.onConnectError((data) => log('❌ Connect Error: $data'));

    socket.on('joined-trip', (data) => log('✅ Joined trip: $data'));

    /// ✅ Location update handler
    socket.on('location-update', (data) {
      final jsonData = data is String ? jsonDecode(data) : data;
      final currentStopSequenceNumber = jsonData['current_stop_sequence_number'];

      try {
        for (StopEntity stop in activeTripTimelineData.stopList ?? []) {
          if (stop.sequenceOrder == currentStopSequenceNumber) {
            log('🏁 Arrived: ${stop.stopName}');

            if (_lastShownStopSequence != currentStopSequenceNumber) {
              // PLAY AUDIO
              final audioUrl = stopAudios[stop.stopId.toString()];
              if (audioUrl != null) {
                audioPlayer.play(UrlSource(audioUrl));
              }

              // SHOW DIALOG
              currentStopDataShowingDialog(
                context: AppGlobalKeys.navigatorKey.currentState!.overlay!.context,
                stopName: stop.stopName ?? 'Unknown Stop',
              );
            }
            _lastShownStopSequence = currentStopSequenceNumber;
          }
        }
      } catch (e) {
        log('❌ Error parsing location-update: $e');
      }
    });

  }


  void leaveTrip({required int tripId, required io.Socket socket}) {
    if (socket.connected) {
      socket.emit('leave-trip', {'tripId': tripId});
    }
  }
}