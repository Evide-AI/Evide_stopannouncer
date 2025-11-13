import 'package:evide_stop_announcer_app/core/app_imports.dart';
import 'package:evide_stop_announcer_app/core/services/service_locator.dart';
import 'package:evide_stop_announcer_app/features/root_widget_page.dart';
import 'package:evide_stop_announcer_app/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
   options: DefaultFirebaseOptions.currentPlatform,
  );
  await initDependencies();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // immersive mode for full-screen TV experience
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(RootWidgetPage());
}
