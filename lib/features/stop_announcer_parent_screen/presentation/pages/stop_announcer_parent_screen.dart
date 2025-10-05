import 'package:evide_stop_announcer_app/core/app_imports.dart';
import 'package:evide_stop_announcer_app/features/stop_announcer_parent_screen/presentation/widgets/pairing_code_showing_widget.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class StopAnnouncerParentScreen extends StatelessWidget {
  const StopAnnouncerParentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kAppPrimaryColor,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w,),
        child: SingleChildScrollView(
          child: SizedBox(
            height: ScreenUtil().screenHeight,
            width: ScreenUtil().screenWidth,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AppConstraints.kHeight40,
                Text(
                  "Pairing Code",
                  style: AppCommonStyles.commonTextStyle(
                    color: AppColors.kWhite,
                    fontSize: 10.sp,
                    fontFamily: AppAssets.robotoSemiBoldFont,
                    letterSpacing: 0.8,
                  ),
                ),
                AppConstraints.kHeight12,
                PairingCodeShowingWidget(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
