import 'package:evide_dashboard/Application/pages/linkscreen/linkscreen.dart';
import 'package:evide_dashboard/Application/pages/screenplay/Screenplay.dart';
import 'package:evide_dashboard/Application/pages/splashscreen/Splashscreen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'firebase_options.dart';

const MethodChannel _kioskChannel = MethodChannel('com.example.evide_dashboard/kiosk');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
_getLiveLocation();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  // Enable immersive sticky to hide system UI on TV
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  // Attempt to start lock task (kiosk) at launch
  try {
    await _kioskChannel.invokeMethod('startLockTask');
  } catch (_) {}
    // Initialize the service here
 // Start periodic fetching

  runApp( MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      // home: Splashscreren(),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashscreenWrapper(),
        '/link': (context) => const HomeScreenWrapper(),
        '/home': (context) => const Screenplay(),
        // '/screens': (context) => const Fetchstops(),
        // '/assigncontent':(context) => AssigncontentWrapper()
      },
    );
  }
}
  Future<Position> _getLiveLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('Location services are disabled.');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        throw Exception('Location permissions are denied.');
      }
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
