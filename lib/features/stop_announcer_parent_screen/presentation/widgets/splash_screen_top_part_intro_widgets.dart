import 'package:evide_stop_announcer_app/core/app_imports.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

List<Widget> splashScreenTopPartIntroWidgets() {
  return [
    // Welcome Text
    Text(
      "Welcome to Evide",
      maxLines: 2,
      style: AppCommonStyles.commonTextStyle(
        color: AppColors.kAppPrimaryColor,
        fontSize: 20.sp,
        fontFamily: AppAssets.robotoBoldFont,
        letterSpacing: 1.2,
        shadows: [
          Shadow(offset: Offset(2, 2), blurRadius: 4, color: Colors.black26),
        ],
      ),
    ),
    AppConstraints.kHeight16,
    // Subtitle Text
    Text(
      "Your travel companion",
      style: AppCommonStyles.commonTextStyle(
        color: AppColors.kLightGrey,
        fontSize: 10.sp,
        fontFamily: AppAssets.robotoSemiBoldFont,
        letterSpacing: 0.8,
      ),
    ),
  ];
}
