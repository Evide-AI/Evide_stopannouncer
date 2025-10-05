
import 'package:evide_stop_announcer_app/core/app_imports.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
class AppCommonStyles {
  static TextStyle commonTextStyle({
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    String? fontFamily,
    double? letterSpacing,
    double? height,
    TextDecoration? decoration,
    TextOverflow? overflow,
  }) {
    return TextStyle(
      color: color ?? AppColors.kBlack,
      fontSize: fontSize ?? 16.sp,
      fontWeight: fontWeight,
      fontFamily: fontFamily ?? AppAssets.robotoRegularFont,
      letterSpacing: letterSpacing,
      decoration: decoration,
      overflow: overflow,
      height: height,
    );
  }
}