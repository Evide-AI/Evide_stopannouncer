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



// class WebSocketServices {
//   static int? _lastShownStopSequence;
//   static AudioPlayer? _audioPlayer;
//   static bool _isPlayingAudio = false;
//   static io.Socket? _currentSocket;
//   static int? _currentTripId;

//   /// Reset all state - call this when starting a new trip
//   static void resetTripState() {
//     _lastShownStopSequence = null;
//     _isPlayingAudio = false;
//     log('🔄 Trip state reset');
//   }

//   /// Join a specific trip room
//   static void joinTrip(io.Socket socket, int tripId) {
//     socket.emitWithAck('join-trip', {'tripId': tripId}, ack: (data) {
//       log('🟢 Trip joined ACK: $data');
//     });
//     _currentTripId = tripId;
//   }

//   /// Connect to backend socket
//   static void connectSocket({
//     required TimeLineEntity activeTripTimelineData,
//     required io.Socket socket,
//     required Map<String, dynamic> stopAudios,
//   }) {
//     // Initialize audio player once if not already created
//     _audioPlayer ??= AudioPlayer();
    
//     // Store current socket reference
//     _currentSocket = socket;
    
//     // Reset state for new trip
//     resetTripState();

//     // Setup audio player completion listener
//     _audioPlayer!.onPlayerComplete.listen((_) {
//       _isPlayingAudio = false;
//       log('🎵 Audio playback completed');
//     });

//     // Connection handler
//     socket.onConnect((_) {
//       log('🟢 Connected: ${socket.id}');
//       final tripId = activeTripTimelineData.tripDetails?.id;
//       if (tripId != null) {
//         joinTrip(socket, tripId);
//       }
//     });

//     // Reconnection handler
//     socket.onReconnect((attempt) {
//       log('🔄 Reconnected (attempt $attempt)');
//       final tripId = activeTripTimelineData.tripDetails?.id;
//       if (tripId != null) {
//         joinTrip(socket, tripId);
//         // Reset last shown stop on reconnect to ensure we don't miss updates
//         _lastShownStopSequence = null;
//       }
//     });

//     // Disconnection handler
//     socket.onDisconnect((reason) {
//       log('🔴 Disconnected: $reason');
//     });

//     // Error handlers
//     socket.onError((data) {
//       log('🚨 Socket Error: $data');
//     });

//     socket.onConnectError((data) {
//       log('❌ Connect Error: $data');
//     });

//     // Trip joined confirmation
//     socket.on('joined-trip', (data) {
//       log('✅ Joined trip: $data');
//     });

//     // Location update handler
//     socket.on('location-update', (data) {
//       _handleLocationUpdate(
//         data: data,
//         activeTripTimelineData: activeTripTimelineData,
//         stopAudios: stopAudios,
//       );
//     });
//   }

//   /// Handle location update events
//   static void _handleLocationUpdate({
//     required dynamic data,
//     required TimeLineEntity activeTripTimelineData,
//     required Map<String, dynamic> stopAudios,
//   }) {
//     try {
//       // Parse incoming data
//       final jsonData = data is String ? jsonDecode(data) : data;
      
//       if (jsonData == null || jsonData is! Map) {
//         log('⚠️ Invalid location-update data format');
//         return;
//       }

//       final currentStopSequenceNumber = jsonData['current_stop_sequence_number'];

//       if (currentStopSequenceNumber == null) {
//         log('⚠️ Missing current_stop_sequence_number in location-update');
//         return;
//       }

//       // Check if this is a new stop
//       if (_lastShownStopSequence == currentStopSequenceNumber) {
//         log('⏭️ Stop $currentStopSequenceNumber already processed, skipping');
//         return;
//       }

//       // Find matching stop
//       final stopList = activeTripTimelineData.stopList;
//       if (stopList == null || stopList.isEmpty) {
//         log('⚠️ No stops available in timeline data');
//         return;
//       }

//       for (StopEntity stop in stopList) {
//         if (stop.sequenceOrder == currentStopSequenceNumber) {
//           log('🏁 Arrived at: ${stop.stopName} (Sequence: $currentStopSequenceNumber)');

//           // Update last shown stop BEFORE playing audio/showing dialog
//           // This prevents duplicate processing if multiple events arrive quickly
//           _lastShownStopSequence = currentStopSequenceNumber;

//           // Play audio
//           _playStopAudio(
//             stopId: stop.stopId,
//             stopName: stop.stopName ?? 'Unknown Stop',
//             stopAudios: stopAudios,
//           );

//           // Show dialog
//           _showStopDialog(stopName: stop.stopName ?? 'Unknown Stop');

//           // Exit loop once stop is found and processed
//           break;
//         }
//       }
//     } catch (e, stackTrace) {
//       log('❌ Error parsing location-update: $e');
//       log('Stack trace: $stackTrace');
//     }
//   }

//   /// Play audio for the current stop
//   static void _playStopAudio({
//     required int? stopId,
//     required String stopName,
//     required Map<String, dynamic> stopAudios,
//   }) {
//     if (stopId == null) {
//       log('⚠️ Stop ID is null, cannot play audio');
//       return;
//     }

//     final audioUrl = stopAudios[stopId.toString()];

//     if (audioUrl == null) {
//       log('⚠️ No audio URL found for stop: $stopName (ID: $stopId)');
//       return;
//     }

//     if (_isPlayingAudio) {
//       log('⏸️ Audio already playing, skipping new audio for: $stopName');
//       return;
//     }

//     if (_audioPlayer == null) {
//       log('❌ Audio player not initialized');
//       return;
//     }

//     _isPlayingAudio = true;
//     log('🎵 Playing audio for: $stopName');

//     _audioPlayer!.play(UrlSource(audioUrl)).then((_) {
//       log('✅ Audio started successfully for: $stopName');
//     }).catchError((error) {
//       log('❌ Audio playback error for $stopName: $error');
//       _isPlayingAudio = false;
//     });
//   }

//   /// Show dialog for current stop
//   static void _showStopDialog({required String stopName}) {
//     try {
//       final navigatorState = AppGlobalKeys.navigatorKey.currentState;
//       final overlayContext = navigatorState?.overlay?.context;

//       if (overlayContext == null) {
//         log('⚠️ Navigator context not available, cannot show dialog');
//         return;
//       }

//       currentStopDataShowingDialog(
//         context: overlayContext,
//         stopName: stopName,
//       );

//       log('📱 Dialog shown for: $stopName');
//     } catch (e, stackTrace) {
//       log('❌ Error showing dialog: $e');
//       log('Stack trace: $stackTrace');
//     }
//   }

//   /// Disconnect socket and cleanup
//   static void disconnectSocket() {
//     if (_currentSocket != null) {
//       log('🔌 Disconnecting socket...');
      
//       // Remove all listeners
//       _currentSocket!.off('location-update');
//       _currentSocket!.off('joined-trip');
      
//       // Disconnect
//       _currentSocket!.disconnect();
//       _currentSocket = null;
//       _currentTripId = null;
      
//       log('✅ Socket disconnected and cleaned up');
//     }
//   }

//   /// Stop any playing audio
//   static Future<void> stopAudio() async {
//     if (_audioPlayer != null && _isPlayingAudio) {
//       await _audioPlayer!.stop();
//       _isPlayingAudio = false;
//       log('⏹️ Audio stopped');
//     }
//   }

//   /// Dispose all resources - call this when service is no longer needed
//   static Future<void> dispose() async {
//     log('🗑️ Disposing WebSocket services...');
    
//     // Stop audio
//     await stopAudio();
    
//     // Dispose audio player
//     await _audioPlayer?.dispose();
//     _audioPlayer = null;
    
//     // Disconnect socket
//     disconnectSocket();
    
//     // Reset state
//     resetTripState();
    
//     log('✅ WebSocket services disposed');
//   }

//   /// Get current connection status
//   static bool isConnected() {
//     return _currentSocket?.connected ?? false;
//   }

//   /// Get current trip ID
//   static int? getCurrentTripId() {
//     return _currentTripId;
//   }

//   /// Manually emit an event (for testing or special cases)
//   static void emitEvent(String eventName, dynamic data) {
//     if (_currentSocket == null) {
//       log('⚠️ Socket not initialized, cannot emit event: $eventName');
//       return;
//     }

//     if (!isConnected()) {
//       log('⚠️ Socket not connected, cannot emit event: $eventName');
//       return;
//     }

//     _currentSocket!.emit(eventName, data);
//     log('📤 Emitted event: $eventName with data: $data');
//   }
// }
