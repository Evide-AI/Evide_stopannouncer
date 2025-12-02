import 'package:evide_stop_announcer_app/core/app_imports.dart';
import 'package:evide_stop_announcer_app/core/services/websocket_services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

Future<dynamic> currentStopDataShowingDialog({
  required BuildContext context,
  required String? stopName,
  required bool isCurrentStop,
  required String? stopNameInMalayalam,
}) async {
  // Show the dialog
  final dialogFuture = showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierLabel: '',
    transitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (context, anim1, anim2) {
      return const SizedBox.shrink();
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return Transform.scale(
        scale: animation.value,
        child: Opacity(
          opacity: animation.value,
          child: Dialog(
            insetPadding: EdgeInsets.zero,
            backgroundColor: Colors.transparent,
            child: Container(
              width: MediaQuery.of(context).size.width,
              padding: EdgeInsets.only(top: 20.h, left: 20.h, right: 20.h, bottom: 10.h),
              height: MediaQuery.of(context).size.height / 1.2,
              margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 30.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade400, Colors.blue.shade800],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueAccent.withAlpha(128),
                    blurRadius: 25,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -20,
                    top: -10,
                    child: Icon(
                      Icons.location_on_rounded,
                      size: 180,
                      color: AppColors.kWhite.withAlpha(26),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: AppColors.kWhite.withAlpha(38),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.location_on_rounded,
                            color: Colors.white,
                            size: 12.sp,
                          ),
                        ),
                        AppConstraints.kHeight16,
                        Text(
                          "${isCurrentStop ? "Current" : "Next"} Stop",
                          style: AppCommonStyles.commonTextStyle(
                            color: AppColors.kWhite,
                            fontSize: 16.sp,
                            fontFamily: AppAssets.robotoSemiBoldFont,
                            letterSpacing: 0.5,
                          ),
                        ),
                        AppConstraints.kHeight8,
                        if (stopNameInMalayalam != null) ...[
                          Text(
                            stopNameInMalayalam,
                            style: AppCommonStyles.commonTextStyle(
                              color: AppColors.kWhite,
                              fontSize: 20.sp,
                              fontFamily: AppAssets.robotoBoldFont,
                              letterSpacing: 1.5,
                              height: 1.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          AppConstraints.kHeight8,
                        ],
                        if (stopName != null) Text(
                          stopName,
                          style: AppCommonStyles.commonTextStyle(
                            color: AppColors.kWhite,
                            fontSize: 22.sp,
                            fontFamily: AppAssets.robotoBoldFont,
                            letterSpacing: 1.5,
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        AppConstraints.kHeight8,
                        Container(
                          width: 60.w,
                          height: 4.h,
                          decoration: BoxDecoration(
                            color: AppColors.kWhite,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );

  // Automatically close after 5 seconds
  Future.delayed(const Duration(seconds: 5), () {
    Navigator.pop(context);
  });

  return dialogFuture;
}
