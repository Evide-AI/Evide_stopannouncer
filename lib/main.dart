import 'dart:async';
import 'dart:ui';

import 'package:evide_stop_announcer_app/core/app_imports.dart';
import 'package:evide_stop_announcer_app/core/services/service_locator.dart';
import 'package:evide_stop_announcer_app/features/root_widget_page.dart';
import 'package:evide_stop_announcer_app/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/services.dart';

void main() async{
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
    );
    initializeFirebaseCrashlyticsServerAndRecordError();
    await initDependencies();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // immersive mode for full-screen TV experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    runApp(RootWidgetPage());
  }, (error, stack) {
    PlatformDispatcher.instance.onError?.call(error, stack);
  },);
}

void initializeFirebaseCrashlyticsServerAndRecordError() {
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true; // Indicate that the error was handled
  };
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterError(errorDetails);
  };
}
