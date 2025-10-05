import 'package:evide_stop_announcer_app/core/app_imports.dart';
import 'package:evide_stop_announcer_app/core/constants/app_global_keys.dart';
import 'package:evide_stop_announcer_app/features/splash_screen/splash_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
class RootWidgetPage extends StatelessWidget {
  const RootWidgetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData.light(useMaterial3: true),
          navigatorKey: AppGlobalKeys.navigatorKey,
          home: SplashScreen(),
        );
      },
    );
  }
}
