import 'package:evide_stop_announcer_app/core/app_imports.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

List<Widget> homeTopPartIntroWidgets() {
  return [
    // Welcome Text
    Text(
      "Welcome to\nEvide",
      style: AppCommonStyles.commonTextStyle(
        color: AppColors.kAppPrimaryColor,
        fontSize: 48.sp,
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
        fontSize: 28.sp,
        fontFamily: AppAssets.robotoSemiBoldFont,
        letterSpacing: 0.8,
      ),
    ),
    AppConstraints.kHeight16,
    Container(
      width: 80.w,
      height: 4.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.kAppPrimaryColor, AppColors.kAppLightPrimaryColor],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(2.h),
      ),
    ),
  ];
}
