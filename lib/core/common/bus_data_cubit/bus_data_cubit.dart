import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:evide_stop_announcer_app/core/app_imports.dart';
import 'package:evide_stop_announcer_app/core/services/shared_prefs_services.dart';
import 'package:evide_stop_announcer_app/core/common/bus_data_domain/entity/bus_data_entity.dart';
import 'package:evide_stop_announcer_app/core/common/bus_data_domain/usecases/get_bus_doc_data_usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'bus_data_state.dart';

class BusDataCubit extends Cubit<BusDataState> {
  final GetBusDocDataUsecase getBusDocDataUsecase;
  final Dio dio;
  List<String> localVideoPaths = [];
  BusDataCubit(
    {required this.getBusDocDataUsecase, required this.dio}
  ) : super(BusDataCubitInitial());

  // Method for getting bus data (including bus name, no, ad_videos and stop_audios)
  void getBusData({String? pairingCode}) async{
    emit(BustDataLoadingState());
    try {
      final savedPairingCode = SharedPrefsServices.getPairingCode();
      // if saved pairing code is null or empty, use the provided pairing code other wise use the saved one
      final res = await getBusDocDataUsecase(params: pairingCode ?? savedPairingCode ?? '');
      res.fold((failure) {
        emit(BusDataErrorState(message: failure.message));
      }, (busdata) async {
        if (busdata != null) {
          await SharedPrefsServices.setIsPaired(isPaired: true);
          // if no pairing code is saved, save the current one
          if (savedPairingCode == null || savedPairingCode.isEmpty) {
            SharedPrefsServices.savePairingCodeToLocalStorage(pairingCode: pairingCode ?? '');
          }
          // download videos to local storage and assign paths to localVideoPaths
          localVideoPaths = await AppCommonMethods.downloadVideosToLocal(busdata.adVideos ?? []);
          emit(BusDataLoadedState(busData: busdata, localVideoPaths: localVideoPaths));
        } else {
          emit(const BusDataErrorState(message: "Bus data is not found"));
        }
      },);
    } catch (e) {
      emit(BusDataErrorState(message: e.toString()));
    }
  }
}
