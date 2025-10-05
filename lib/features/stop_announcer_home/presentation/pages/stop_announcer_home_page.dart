import 'dart:math';

import 'package:evide_stop_announcer_app/core/app_imports.dart';
import 'package:evide_stop_announcer_app/core/components/common_text_form_field_widget.dart';
import 'package:evide_stop_announcer_app/core/constants/app_common_styles.dart';
import 'package:evide_stop_announcer_app/features/stop_announcer_home/presentation/widgets/home_top_part_intro_widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class StopAnnouncerHomePage extends StatefulWidget {
  const StopAnnouncerHomePage({super.key});

  @override
  State<StopAnnouncerHomePage> createState() => _StopAnnouncerHomePageState();
}

class _StopAnnouncerHomePageState extends State<StopAnnouncerHomePage> {
  TextEditingController secretCodeController = TextEditingController();

  @override
  void dispose() {
    secretCodeController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: EdgeInsets.only(left: 10.w),
          child: Image.asset(AppAssets.pngApplogo, width: 50, height: 50),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // home top intro part
             ...homeTopPartIntroWidgets(),
             AppConstraints.kHeight40,
             Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.sp),
                color: AppColors.kAppLightPrimaryColor,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                  "${Random().nextInt(10000000)}",
                  style: AppCommonStyles.commonTextStyle(
                    color: AppColors.kBlack,
                    fontSize: 18.sp,
                    fontFamily: AppAssets.robotoMediumFont,
                    letterSpacing: 0.8,
                  ),
                  ),
                  AppConstraints.kWidth10,
                   GestureDetector(
                    onTap: () {
                      
                    },
                    child: Icon(Icons.copy),
                  ),
                ],
              ),
             ),
             AppConstraints.kHeight10,
             Text(
              "Enter the code above",
              style: AppCommonStyles.commonTextStyle(
                color: AppColors.kBlack,
                fontSize: 18.sp,
                fontFamily: AppAssets.robotoMediumFont,
                letterSpacing: 0.8,
              ),
            ),
             AppConstraints.kHeight20,
             CommonTextFormFieldWidget(
              enabled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15.sp),
                borderSide: BorderSide(color: AppColors.kAppPrimaryColor),
              ),
              controller: secretCodeController,
              hintText: "Enter connection code",
             ),
            ],
          ),
        ),
      ),
    );
  }
}


