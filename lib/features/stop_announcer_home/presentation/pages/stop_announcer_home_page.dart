import 'package:evide_stop_announcer_app/core/app_imports.dart';
import 'package:evide_stop_announcer_app/features/stop_announcer_home/presentation/widgets/home_top_part_intro_widgets.dart';
import 'package:evide_stop_announcer_app/features/stop_announcer_home/presentation/widgets/pairing_code_showing_widget.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class StopAnnouncerHomePage extends StatefulWidget {
  const StopAnnouncerHomePage({super.key});

  @override
  State<StopAnnouncerHomePage> createState() => _StopAnnouncerHomePageState();
}

class _StopAnnouncerHomePageState extends State<StopAnnouncerHomePage> {
  late String secretCodeForConnection;

  @override
  void initState() {
    // generate a random secret code
    secretCodeForConnection = AppCommonMethods.generateSecretCode();
    super.initState();
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
              Text(
                "Pairing Code",
                style: AppCommonStyles.commonTextStyle(
                  color: AppColors.kBlack,
                  fontSize: 23.sp,
                  fontFamily: AppAssets.robotoSemiBoldFont,
                  letterSpacing: 0.8,
                ),
              ),
              AppConstraints.kHeight12,
              PairingCodeShowingWidget(
                secretCodeForConnection: secretCodeForConnection,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
