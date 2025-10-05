

import 'package:equatable/equatable.dart';
import 'package:evide_stop_announcer_app/core/services/shared_prefs_services.dart';
import 'package:evide_stop_announcer_app/core/utils/app_common_methods.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'stop_announcer_parent_screen_state.dart';

class StopAnnouncerParentScreenCubit extends Cubit<StopAnnouncerParentScreenState> {
  StopAnnouncerParentScreenCubit() : super(StopAnnouncerParentScreenState());

  void getPairingCode() async {
    try {
      String? savedPairingCode = await SharedPrefsServices.getPairingCode();
      if (savedPairingCode == null) {
        String newCode = AppCommonMethods.generateSecretCode();
        await SharedPrefsServices.savePairingCodeToLocalStorage(pairingCode: newCode);
        emit(StopAnnouncerParentScreenState(pairingCode: newCode));
      }else {
        emit(StopAnnouncerParentScreenState(pairingCode: savedPairingCode));
      }
    } catch (e) {
      emit(StopAnnouncerParentScreenErrorState(errorMessage: "Failed to fetch pairing code"));
    }
  }
}
