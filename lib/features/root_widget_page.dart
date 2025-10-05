import 'package:evide_stop_announcer_app/core/app_imports.dart';
import 'package:evide_stop_announcer_app/core/constants/app_global_keys.dart';
import 'package:evide_stop_announcer_app/core/services/service_locator.dart';
import 'package:evide_stop_announcer_app/core/services/shared_prefs_services.dart';
import 'package:evide_stop_announcer_app/features/splash_screen/splash_screen.dart';
import 'package:evide_stop_announcer_app/features/stop_announcer_parent_screen/presentation/cubit/stop_announcer_parent_screen_cubit.dart';
import 'package:evide_stop_announcer_app/features/stop_announcer_parent_screen/presentation/pages/stop_announcer_parent_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RootWidgetPage extends StatelessWidget {
  const RootWidgetPage({super.key});

  Future<bool> checkIsPaired() async {
    bool? isPaired = await SharedPrefsServices.getIsPaired();
    return isPaired ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      builder: (context, child) {
        return MultiBlocProvider(
          providers: [
            BlocProvider(create: (context) => serviceLocator<StopAnnouncerParentScreenCubit>()..getPairingCode(),)
          ],
          child: FutureBuilder(
            future: checkIsPaired(),
            builder: (context, snap) {
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: ThemeData.light(useMaterial3: true),
                navigatorKey: AppGlobalKeys.navigatorKey,
                home: (snap.data ?? false) ? SplashScreen() : StopAnnouncerParentScreen(),
              );
            }
          ),
        );
      },
    );
  }
}
