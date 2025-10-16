import 'package:evide_stop_announcer_app/core/app_imports.dart';
import 'package:evide_stop_announcer_app/core/common_blocs/bus_data_cubit/bus_data_cubit.dart';
import 'package:evide_stop_announcer_app/core/constants/app_global_keys.dart';
import 'package:evide_stop_announcer_app/core/services/service_locator.dart';
import 'package:evide_stop_announcer_app/features/splash_screen/presentation/pages/splash_screen.dart';
import 'package:evide_stop_announcer_app/features/stop_announcer_parent_screen/presentation/cubit/stop_announcer_parent_screen_cubit.dart';
import 'package:evide_stop_announcer_app/features/stop_announcer_parent_screen/presentation/pages/pairing_code_enter_page.dart';
// import 'package:evide_stop_announcer_app/features/stop_announcer_parent_screen/presentation/pages/stop_announcer_parent_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RootWidgetPage extends StatelessWidget {
  const RootWidgetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      builder: (context, child) {
        return MultiBlocProvider(
          providers: [
            // BlocProvider(create: (context) => serviceLocator<StopAnnouncerParentScreenCubit>()..getPairingCode(),)
            BlocProvider(create: (context) => serviceLocator<StopAnnouncerParentScreenCubit>()),
            BlocProvider(create: (context) => serviceLocator<BusDataCubit>()),
          ],
          child: FutureBuilder(
            future: AppCommonMethods.checkIsPaired(),
            builder: (context, snap) {
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: ThemeData.light(useMaterial3: true),
                navigatorKey: AppGlobalKeys.navigatorKey,
                // home: (snap.data ?? false) ? SplashScreen() : StopAnnouncerParentScreen(),
                home: (snap.data ?? false) ? SplashScreen() : PairingCodeEnterPage(),
              );
            }
          ),
        );
      },
    );
  }
}
