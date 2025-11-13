import 'dart:convert';
import 'dart:developer';
import 'package:evide_stop_announcer_app/core/app_imports.dart';
import 'package:evide_stop_announcer_app/core/constants/app_global_keys.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
int? lastStopSequenceNumber;
class WebSocketServices {
  /// ✅ Connect to backend socket
  static void connectSocket({
    required int? tripId,
    required io.Socket socket,
  }) {
    socket.onConnect((_) {
      log('🟢 Connected to socket with ID: ${socket.id}');
      if (tripId != null) {
        socket.emit('join-trip', {'tripId': tripId});
      }
    });

    socket.onDisconnect((reason) => log('🔴 Disconnected: $reason'));
    socket.onError((data) => log('🚨 Socket Error: $data'));
    socket.onConnectError((data) => log('❌ Connect Error: $data'));

    socket.on('joined-trip', (data) => log('✅ Joined trip: $data'));

    /// ✅ Location update handler
    socket.on('location-update', (data) {
      log('📍 Location update: $data');
      try {
        final jsonData = data is String ? jsonDecode(data) : data;
        
        final location = jsonData['location'];
        final lat = location['lat'];
        final lon = location['lon'];
        final timestamp = jsonData['timestamp'];
        final currentStopSequenceNumber =
            jsonData['current_stop_sequence_number'];
        final nextStopSequenceNumber = jsonData['next_stop_sequence_number'];
        final distanceToNextStopMeters =
            (jsonData['distanceToNextStopMeters'] as num?)?.toDouble();
        final speed = (jsonData['speed'] as num?)?.toDouble();
        final currentStopArrivalDelay = jsonData['currentStopArrivalDelay'];

        if (lastStopSequenceNumber != null && currentStopSequenceNumber > lastStopSequenceNumber!) {
          // print('🚌 Bus has arrived at stop sequence number: $lastStopSequenceNumber');  
          if (AppGlobalKeys.navigatorKey.currentContext != null) {
            if (AppGlobalKeys.navigatorKey.currentContext!.mounted) {
              AppCommonMethods.currentStopDataShowingDialog(AppGlobalKeys.navigatorKey.currentContext!, stopName: "stopName");
            }
          }
          
        }

        lastStopSequenceNumber = currentStopSequenceNumber;

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
