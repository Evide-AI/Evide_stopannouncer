import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:evide_stop_announcer_app/core/common/bus_data_cubit/bus_data_cubit.dart';
import 'package:evide_stop_announcer_app/core/common/bus_data/bus_data.dart';
import 'package:evide_stop_announcer_app/core/common/bus_data/bus_data_repo_impl/bus_data_repo_impl.dart';
import 'package:evide_stop_announcer_app/core/common/bus_data_domain/bus_data_repo/bus_repo.dart';
import 'package:evide_stop_announcer_app/core/common/bus_data_domain/usecases/get_active_trip_data_usecase.dart';
import 'package:evide_stop_announcer_app/core/common/bus_data_domain/usecases/get_bus_doc_data_usecase.dart';
import 'package:evide_stop_announcer_app/core/services/shared_prefs_services.dart';
import 'package:evide_stop_announcer_app/features/stop_announcer_parent_screen/presentation/cubit/stop_announcer_parent_screen_cubit.dart';
import 'package:get_it/get_it.dart';
import 'package:evide_stop_announcer_app/core/common/bus_data_domain/usecases/stream_bus_videos_usecase.dart';
import 'package:evide_stop_announcer_app/core/services/api_service.dart';

GetIt serviceLocator = GetIt.instance;

Future<void> initDependencies() async {
  await SharedPrefsServices.init();
  serviceLocator.registerLazySingleton(() => FirebaseFirestore.instance);
  serviceLocator.registerLazySingleton(() => Dio());
  serviceLocator.registerFactory<ApiService>(() => ApiService(),);
  initHomeDependencies();
  initBusDataDependencies();
}


initHomeDependencies() {
  serviceLocator.registerFactory<StopAnnouncerParentScreenCubit>(() {
    return StopAnnouncerParentScreenCubit();
  },);
}

initBusDataDependencies() {
  serviceLocator
  ..registerFactory<BusData>(() => BusDataImpl(firebaseFirestore: serviceLocator(), dio: serviceLocator<Dio>()),)
  ..registerFactory<BusDataRepo>(() => BusDataRepoImpl(busData: serviceLocator()),)
  ..registerFactory<GetBusDocDataUsecase>(() => GetBusDocDataUsecase(busDataRepo: serviceLocator()),)
  ..registerFactory<GetActiveTripDataUsecase>(() => GetActiveTripDataUsecase(busDataRepo: serviceLocator()),)
  ..registerFactory<StreamBusVideosUsecase>(() => StreamBusVideosUsecase(busDataRepo: serviceLocator()),)
  ..registerFactory<BusDataCubit>(() => BusDataCubit(
      getBusDocDataUsecase: serviceLocator<GetBusDocDataUsecase>(), dio: serviceLocator<Dio>(),
      getActiveTripDataUsecase: serviceLocator<GetActiveTripDataUsecase>(),
      streamBusVideosUsecase: serviceLocator<StreamBusVideosUsecase>(),
    ),);
}
