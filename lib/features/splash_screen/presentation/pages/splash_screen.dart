import 'package:evide_stop_announcer_app/core/app_imports.dart';
import 'package:evide_stop_announcer_app/core/common/bus_data_cubit/bus_data_cubit.dart';
import 'package:evide_stop_announcer_app/core/constants/app_global_keys.dart';
import 'package:evide_stop_announcer_app/features/ads_play_page/presentation/pages/ads_play_page.dart';
import 'package:evide_stop_announcer_app/features/stop_announcer_parent_screen/presentation/pages/stop_announcer_parent_screen.dart';
import 'package:evide_stop_announcer_app/features/splash_screen/presentation/widgets/splash_screen_top_part_intro_widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(Duration(seconds: 6), () async {
        // if paired go to add videos list page or playing page
        if (mounted) {
          await AppGlobalKeys.navigatorKey.currentState?.pushAndRemoveUntil(MaterialPageRoute(builder: (context) {
            return AdsPlayPage();
          },), (route) => false,);
        }
      },);
    },);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ...splashScreenTopPartIntroWidgets(),
          AppConstraints.kHeight20,
          Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 1800),
              curve: Curves.easeIn,
              builder: (context, opacity, child) {
                return Opacity(
                  opacity: opacity,
                  child: child,
                );
              },
              child: Container(
                height: 100.h,
                width: 100.w,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.sp),
                ),
                child: ClipRRect(
                  child: Image.asset(
                    AppAssets.pngApplogo,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}