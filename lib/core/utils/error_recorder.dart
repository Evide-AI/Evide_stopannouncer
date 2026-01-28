import 'dart:ui';

import 'package:evide_stop_announcer_app/core/app_imports.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class ErrorRecorder {
  static void initializeFirebaseCrashlyticsServerAndRecordError() {
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true; // Indicate that the error was handled
    };
    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterError(errorDetails);
    };
  }
}