import 'package:evide_stop_announcer_app/core/app_imports.dart';
import 'package:evide_stop_announcer_app/core/common/bus_data_cubit/bus_data_cubit.dart';
import 'package:evide_stop_announcer_app/core/components/common_text_form_field_widget.dart';
import 'package:evide_stop_announcer_app/core/constants/app_global_keys.dart';
import 'package:evide_stop_announcer_app/features/splash_screen/presentation/pages/splash_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PairingCodeEnterPage extends StatefulWidget {
  const PairingCodeEnterPage({super.key});

  @override
  State<PairingCodeEnterPage> createState() => _PairingCodeEnterPageState();
}

class _PairingCodeEnterPageState extends State<PairingCodeEnterPage> {
  TextEditingController pairingCodeController = TextEditingController();
  @override
  void dispose() {
    pairingCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BusDataCubit, BusDataState>(
      listener: (context, state) {
        if (state is BusDataLoadedState) {
          AppGlobalKeys.navigatorKey.currentState?.pushAndRemoveUntil(MaterialPageRoute(builder: (context) {
            return SplashScreen();
          },), (route) => false,);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.kAppPrimaryColor,
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: SingleChildScrollView(
            child: SizedBox(
              height: ScreenUtil().screenHeight,
              width: ScreenUtil().screenWidth,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  AppConstraints.kHeight40,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Enter Pairing Code",
                        style: AppCommonStyles.commonTextStyle(
                          color: AppColors.kWhite,
                          fontSize: 10.sp,
                          fontFamily: AppAssets.robotoSemiBoldFont,
                          letterSpacing: 0.8,
                        ),
                      ),
                      AppConstraints.kWidth8,
                      Text(
                        "Hint(Bus no)",
                        style: AppCommonStyles.commonTextStyle(
                          color: AppColors.kBlack,
                          fontSize: 6.sp,
                          fontFamily: AppAssets.robotoSemiBoldFont,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  AppConstraints.kHeight12,
                  SizedBox(
                    width: ScreenUtil().screenWidth / 3,
                    child: CommonTextFormFieldWidget(
                      controller: pairingCodeController,
                      hintText: "Enter code",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                        borderSide: BorderSide(
                          color: AppColors.kLightGrey,
                          width: 1.w,
                        ),
                      ),
                      keyboardType: TextInputType.text,
                      fillColor: AppColors.kWhite,
                      hintStyle: AppCommonStyles.commonTextStyle(
                        color: AppColors.kLightGrey,
                        fontSize: 6.sp,
                        fontFamily: AppAssets.robotoRegularFont,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  AppConstraints.kHeight20,
                  ElevatedButton(
                    onPressed: () {
                      // connect with firebase collection with pairing code document
                      context.read<BusDataCubit>().getBusData(
                        pairingCode: pairingCodeController.text
                            .toUpperCase()
                            .trim(),
                      );
                    },
                    child: Text(
                      "Connect",
                      style: AppCommonStyles.commonTextStyle(
                        color: AppColors.kBlack,
                        fontSize: 6.sp,
                        fontFamily: AppAssets.robotoSemiBoldFont,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
