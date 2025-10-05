import 'package:evide_stop_announcer_app/core/app_imports.dart';
import 'package:evide_stop_announcer_app/features/stop_announcer_parent_screen/presentation/cubit/stop_announcer_parent_screen_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PairingCodeShowingWidget extends StatelessWidget {
  const PairingCodeShowingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.connected_tv,
            color: AppColors.kWhite,
            size: 22.sp,
          ),
          AppConstraints.kWidth10,
          // showing secret code to user
          BlocBuilder<StopAnnouncerParentScreenCubit, StopAnnouncerParentScreenState>(
            builder: (context, state) {
              return Text(
                state.pairingCode ?? "No code",
                style: AppCommonStyles.commonTextStyle(
                  color: AppColors.kWhite,
                  fontSize: 16.sp,
                  fontFamily: AppAssets.robotoMediumFont,
                  letterSpacing: 0.8,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
