import 'package:evide_stop_announcer_app/core/app_imports.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PairingCodeShowingWidget extends StatelessWidget {
  const PairingCodeShowingWidget({
    super.key,
    required this.secretCodeForConnection,
  });

  final String secretCodeForConnection;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.sp),
        color: AppColors.kGrey1,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.connected_tv,
            color: AppColors.kAppPrimaryColor,
            size: 22.sp,
          ),
          AppConstraints.kWidth10,
          // showing secret code to user
          Text(
            secretCodeForConnection,
            style: AppCommonStyles.commonTextStyle(
              color: AppColors.kBlack,
              fontSize: 16.sp,
              fontFamily: AppAssets.robotoMediumFont,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}