import 'dart:convert';
import 'dart:developer';
import 'package:audioplayers/audioplayers.dart';
import 'package:evide_stop_announcer_app/core/common/bus_data_domain/entity/timeline_entity.dart';
import 'package:evide_stop_announcer_app/core/constants/app_global_keys.dart';
import 'package:evide_stop_announcer_app/features/ads_play_page/presentation/dialogs/current_stop_data_showing_dialog.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
class WebSocketServices {
  /// ✅ Connect to backend socket
  static void connectSocket({
    required TimeLineEntity activeTripTimelineData,
    required io.Socket socket,
    required Map<String, dynamic> stopAudios,
  }) {
    AudioPlayer audioPlayer = AudioPlayer();
    socket.onConnect((_) {
      log('🟢 Connected to socket with ID: ${socket.id}');
      if (activeTripTimelineData.tripDetails?.id != null) {
        socket.emit('join-trip', {'tripId': activeTripTimelineData.tripDetails?.id});
      }
    });

    socket.onDisconnect((reason) {
      log('🔴 Disconnected: $reason');
      audioPlayer.dispose();
    });
    socket.onError((data) => log('🚨 Socket Error: $data'));
    socket.onConnectError((data) => log('❌ Connect Error: $data'));

    socket.on('joined-trip', (data) => log('✅ Joined trip: $data'));

    /// ✅ Location update handler
    socket.on('location-update', (data) async {
      final jsonData = data is String ? jsonDecode(data) : data;
      final currentStopSequenceNumber = jsonData['current_stop_sequence_number'];

      try {
        for (var stop in activeTripTimelineData.stopList ?? []) {
          if (stop.sequenceOrder == currentStopSequenceNumber) {
            log('🏁 Arrived: ${stop.stopName}');

            // PLAY AUDIO
            final audioUrl = stopAudios[stop.stopId.toString()];
            if (audioUrl != null) {
              await audioPlayer.play(UrlSource(audioUrl));
            }

            // SHOW DIALOG
            currentStopDataShowingDialog(
              context: AppGlobalKeys.navigatorKey.currentState!.overlay!.context,
              stopName: stop.stopName ?? 'Unknown Stop',
            );
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
