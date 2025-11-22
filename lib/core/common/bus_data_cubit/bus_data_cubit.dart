import 'dart:async';

import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:evide_stop_announcer_app/core/app_imports.dart';
import 'package:evide_stop_announcer_app/core/common/bus_data_domain/usecases/get_active_trip_data_usecase.dart';
import 'package:evide_stop_announcer_app/core/common/bus_data_domain/usecases/stream_bus_videos_usecase.dart';
import 'package:evide_stop_announcer_app/core/services/shared_prefs_services.dart';
import 'package:evide_stop_announcer_app/core/common/bus_data_domain/entity/bus_data_entity.dart';
import 'package:evide_stop_announcer_app/core/common/bus_data_domain/usecases/get_bus_doc_data_usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'bus_data_state.dart';

class BusDataCubit extends Cubit<BusDataState> {
  final GetBusDocDataUsecase getBusDocDataUsecase;
  final GetActiveTripDataUsecase getActiveTripDataUsecase;
  final StreamBusVideosUsecase streamBusVideosUsecase;
  final Dio dio;
  List<String> localVideoPaths = [];
  BusDataCubit({
    required this.getBusDocDataUsecase,
    required this.dio,
    required this.getActiveTripDataUsecase,
    required this.streamBusVideosUsecase,
  }) : super(BusDataCubitInitial());

  StreamSubscription? _videoStreamSub;

  // Method for getting bus data (including bus name, no, ad_videos and stop_audios)
  Future<void> getBusData({String? pairingCode}) async{
    emit(state.copyWith(status: BusDataStatus.loading));
    try {
      final savedPairingCode = SharedPrefsServices.getPairingCode();
      // if saved pairing code is null or empty, use the provided pairing code other wise use the saved one
      final res = await getBusDocDataUsecase(params: pairingCode ?? savedPairingCode ?? '');
      res.fold((failure) {
        emit(state.copyWith(status: BusDataStatus.error, message: failure.message));
      }, (busdata) async {
        if (busdata != null) {
          await SharedPrefsServices.setIsPaired(isPaired: true);
          // if no pairing code is saved, save the current one
          if (savedPairingCode == null || savedPairingCode.isEmpty) {
            SharedPrefsServices.savePairingCodeToLocalStorage(pairingCode: pairingCode ?? '');
          }
          // download videos to local storage and assign paths to localVideoPaths
          localVideoPaths = await AppCommonMethods.downloadVideosToLocal(busdata.adVideos ?? []);
          emit(state.copyWith(busData: busdata, localVideoPaths: localVideoPaths, status: BusDataStatus.loaded));
        } else {
          // emit(const BusDataErrorState(message: "Bus data is not found"));
          emit(state.copyWith(status: BusDataStatus.error));
        }
      },);
    } catch (e) {
      emit(state.copyWith(status: BusDataStatus.error, message: e.toString()));
    }
  }

  void getVideosAndAudiosToPlay({String? busPairingCode}) {
    try {
      String? pairingCode = SharedPrefsServices.getPairingCode() ?? busPairingCode;
      if (pairingCode != null) {
        // Cancel existing stream if already listening
        _videoStreamSub?.cancel();

        // Start listening to video stream
        _videoStreamSub = streamBusVideosUsecase(params: pairingCode).listen(
          (either) async {
            await either.fold(
              // Failure
              (failure) {
                emit(state.copyWith(
                  busData: state.busData,
                  status: BusDataStatus.error,
                  message: failure.message,
                ));
              },

              // Success
              (audioVideoModel) async {
                final audios = audioVideoModel.audioUrls;
                final videos = audioVideoModel.videoUrls;
                // Download videos to local storage
                localVideoPaths =
                    await AppCommonMethods.downloadVideosToLocal(videos);

                // Emit updated paths
                emit(state.copyWith(
                  busData: state.busData.copyWith(
                    stopAudios: audios.isNotEmpty ? audios : state.busData.stopAudios
                  ),
                  localVideoPaths: localVideoPaths,
                  status: BusDataStatus.loaded,
                ));
              },
            );
          },
        );
      }
    } catch (e) {
      emit(state.copyWith(
        message: e.toString(),
      ));
    }
  }
}
