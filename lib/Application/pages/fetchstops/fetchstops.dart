// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
// import 'dart:math';

// import 'package:audioplayers/audioplayers.dart';
// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class StopBanner extends StatefulWidget {
//   const StopBanner({super.key});

//   @override
//   State<StopBanner> createState() => _StopBannerState();
// }

// class _StopBannerState extends State<StopBanner> {
//   bool _isNearStop = false;
//   String _stopName = '';
//   List<Map<String, dynamic>> stops = [];
//   Timer? _timer;
//   @override
//   void initState() {
//     super.initState();
//     _timer = Timer.periodic(Duration(seconds: 5), (timer) async {
//       await _checkNearbyStop();
//     });
//     // You can start fetching stop data here
//     _fetchStopsData();
//   }

//   @override
//   void dispose() {
//     _timer?.cancel(); // cancel timer when widget is destroyed
//     super.dispose();
//   }

//   // Fetch stops data from SharedPreferences or elsewhere
//   Future<void> _fetchStopsData() async {
//     final prefs = await SharedPreferences.getInstance();
//     final documentData = prefs.getString('documentData');
//     final localPathsStr = prefs.getString("localPaths");

//     if (documentData != null) {
//       final data = jsonDecode(documentData);
//       if (data.containsKey('stops')) {
//         stops = List<Map<String, dynamic>>.from(data['stops']);

//         // Make sure the localPath is included for each stop
//         for (var stop in stops) {
//           String stopName = stop['stopname'];

//           // Convert stop name to lowercase to match audio file name
//           String localPath =
//               "/data/user/0/com.example.evide_dashboard/app_flutter/stops/${stopName.toLowerCase()}.mp3";
//           stop['localPath'] = localPath;
//           print('the local path of audio file is....$localPath');
//         }
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Stack(
//         children: [
//           // PlaylistPlayer(items: items),
//           if (_isNearStop)
//             Positioned.fill(
//               child: Container(
//                 color: Colors.black.withOpacity(0.3),
//                 child: Center(
//                   child: Container(
//                     margin: EdgeInsets.symmetric(horizontal: 32),
//                     padding: EdgeInsets.all(32),
//                     decoration: BoxDecoration(
//                       gradient: LinearGradient(
//                         colors: [Colors.green.shade400, Colors.green.shade600],
//                         begin: Alignment.topLeft,
//                         end: Alignment.bottomRight,
//                       ),
//                       borderRadius: BorderRadius.circular(24),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.green.withOpacity(0.3),
//                           blurRadius: 20,
//                           spreadRadius: 5,
//                           offset: Offset(0, 8),
//                         ),
//                       ],
//                     ),
//                     child: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Container(
//                           padding: EdgeInsets.all(16),
//                           decoration: BoxDecoration(
//                             color: Colors.white.withOpacity(0.2),
//                             shape: BoxShape.circle,
//                           ),
//                           child: Icon(
//                             Icons.location_on,
//                             size: 48,
//                             color: Colors.white,
//                           ),
//                         ),
//                         SizedBox(height: 24),
//                         Text(
//                           "You're Near",
//                           style: TextStyle(
//                             color: Colors.white.withOpacity(0.9),
//                             fontSize: 18,
//                             fontWeight: FontWeight.w500,
//                             letterSpacing: 1.2,
//                           ),
//                         ),
//                         SizedBox(height: 8),
//                         Text(
//                           _stopName,
//                           textAlign: TextAlign.center,
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontSize: 32,
//                             fontWeight: FontWeight.bold,
//                             letterSpacing: 0.5,
//                             height: 1.2,
//                           ),
//                         ),
//                         SizedBox(height: 24),
//                         Container(
//                           padding: EdgeInsets.symmetric(
//                             horizontal: 20,
//                             vertical: 8,
//                           ),
//                           decoration: BoxDecoration(
//                             color: Colors.white.withOpacity(0.2),
//                             borderRadius: BorderRadius.circular(20),
//                             border: Border.all(
//                               color: Colors.white.withOpacity(0.3),
//                               width: 1,
//                             ),
//                           ),
//                           child: Row(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               Icon(
//                                 Icons.explore,
//                                 size: 16,
//                                 color: Colors.white,
//                               ),
//                               SizedBox(width: 8),
//                               Text(
//                                 "Discover what's around you",
//                                 style: TextStyle(
//                                   color: Colors.white,
//                                   fontSize: 14,
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   String _getFileType(String localPath, Map<String, dynamic> content) {
//     // First check file extension
//     final extension = localPath.toLowerCase().split('.').last;

//     if (['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension)) {
//       return 'image';
//     } else if ([
//       'mp4',
//       'mov',
//       'avi',
//       'mkv',
//       'webm',
//       'flv',
//     ].contains(extension)) {
//       return 'video';
//     }

//     // Fallback to content type from Firestore data
//     final contentType = content['contentType'] as String? ?? '';
//     if (contentType.startsWith('image/')) {
//       return 'image';
//     } else if (contentType.startsWith('video/')) {
//       return 'video';
//     }

//     // Default fallback
//     return File(localPath).existsSync() ? 'video' : 'image';
//   }

//   // Helper function to get the live location of the user
//   Future<Position> _getLiveLocation() async {
//     bool serviceEnabled;
//     LocationPermission permission;

//     serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       return Future.error('Location services are disabled.');
//     }

//     permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission != LocationPermission.whileInUse &&
//           permission != LocationPermission.always) {
//         return Future.error('Location permissions are denied.');
//       }
//     }

//     return await Geolocator.getCurrentPosition(
//       desiredAccuracy: LocationAccuracy.high,
//     );
//   }

//   // Helper function to calculate the distance between two locations
//   double _calculateDistance(
//     double lat1,
//     double lon1,
//     double lat2,
//     double lon2,
//   ) {
//     const double radius = 6371; // Radius of Earth in km
//     double dLat = _degToRad(lat2 - lat1);
//     double dLon = _degToRad(lon2 - lon1);

//     double a =
//         sin(dLat / 2) * sin(dLat / 2) +
//         cos(_degToRad(lat1)) *
//             cos(_degToRad(lat2)) *
//             sin(dLon / 2) *
//             sin(dLon / 2);
//     double c = 2 * atan2(sqrt(a), sqrt(1 - a));
//     double distance = radius * c * 1000; // distance in meters

//     return distance;
//   }

//   // Helper function to convert degrees to radians
//   double _degToRad(double degree) {
//     return degree * (pi / 180);
//   }

//   Future<void> _playStopAudio(String localFilePath) async {
//     String safePath = localFilePath.replaceAll(' ', '_');

//     AudioPlayer audioPlayer = AudioPlayer();
//     try {
//       print("🔊 Playing audio from local file: $localFilePath");

//       // Play the audio from the local file path directly
//       await audioPlayer.play(DeviceFileSource(safePath));

//       // Optionally listen for completion
//       audioPlayer.onPlayerComplete.listen((event) {
//         print("🎶 Audio finished playing");
//       });
//     } catch (e) {
//       print("🔥 Error playing audio: $e");
//     }
//   }

//   // Function to check the user's location and show the banner
//   Future<void> _checkNearbyStop() async {
//     if (stops.isEmpty) {
//       print("⚠️ Stops not loaded yet, skipping check...");
//       return;
//     }

//     Position liveLocation = await _getLiveLocation();
//     print(
//       "📍 Live Location: ${liveLocation.latitude}, ${liveLocation.longitude}",
//     );

//     for (int i = 0; i < stops.length; i++) {
//       final stop = stops[i];
//       final stopLat = stop['latitude'] ?? 0.0;
//       final stopLon = stop['longitude'] ?? 0.0;

//       // Calculate the distance to the stop
//       double distance = _calculateDistance(
//         liveLocation.latitude,
//         liveLocation.longitude,
//         stopLat,
//         stopLon,
//       );

//       // If the distance is within 100 meters
//       if (distance < 100) {
//         setState(() {
//           _isNearStop = true;
//           _stopName = stop['stopname'];
//         });

//         // Show banner for 5 seconds
//         await Future.delayed(Duration(seconds: 5));

//         setState(() {
//           _isNearStop = false;
//         });
//         print('The nearest stop is $_stopName');

//         // Get the local file path for the stop
//         String localFilePath = stop['localPath'] ?? '';
//         print('The Local Path is ....$localFilePath');

//         // Play the audio from the local path
//         if (localFilePath.isNotEmpty) {
//           await _playStopAudio(localFilePath); // Use local file path here
//         }
//         print('The nearest stop audio.....$localFilePath');

//         break; // Stop after finding the first nearby stop
//       }
//     }
//   }
// }
