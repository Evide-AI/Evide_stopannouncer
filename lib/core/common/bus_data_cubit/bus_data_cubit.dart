import 'package:equatable/equatable.dart';
import 'package:evide_stop_announcer_app/core/services/shared_prefs_services.dart';
import 'package:evide_stop_announcer_app/core/common/bus_data_domain/entity/bus_data_entity.dart';
import 'package:evide_stop_announcer_app/core/common/bus_data_domain/usecases/get_bus_doc_data_usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'bus_data_state.dart';

class BusDataCubit extends Cubit<BusDataState> {
  final GetBusDocDataUsecase getBusDocDataUsecase;
  BusDataCubit(
    {required this.getBusDocDataUsecase}
  ) : super(BusDataCubitInitial());

  void getBusData({required String pairingCode}) async{
    try {
      final res = await getBusDocDataUsecase(params: pairingCode);
      res.fold((failure) {
        emit(BusDataErrorState(message: failure.message));
      }, (busdata) {
        if (busdata != null) {
          SharedPrefsServices.setIsPaired(isPaired: true);
          emit(BusDataLoadedState(busData: busdata));
        } else {
          emit(const BusDataErrorState(message: "Bus data is not found"));
        }
      },);
    } catch (e) {
      emit(BusDataErrorState(message: e.toString()));
    }
  }
}
