import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:evide_stop_announcer_app/core/common_blocs/bus_data_cubit/bus_data_cubit.dart';
import 'package:evide_stop_announcer_app/features/ads_play_page/data/bus_data.dart';
import 'package:evide_stop_announcer_app/features/ads_play_page/data/bus_data_repo_impl/bus_data_repo_impl.dart';
import 'package:evide_stop_announcer_app/features/ads_play_page/domain/bus_data_repo/bus_repo.dart';
import 'package:evide_stop_announcer_app/features/ads_play_page/domain/usecases/get_bus_doc_data_usecase.dart';
import 'package:evide_stop_announcer_app/features/stop_announcer_parent_screen/presentation/cubit/stop_announcer_parent_screen_cubit.dart';
import 'package:get_it/get_it.dart';

GetIt serviceLocator = GetIt.instance;

initDependencies(){
  serviceLocator.registerLazySingleton(() => FirebaseFirestore.instance);
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
  ..registerFactory<BusData>(() => BusDataImpl(firebaseFirestore: serviceLocator()),)
  ..registerFactory<BusDataRepo>(() => BusDataRepoImpl(busData: serviceLocator()),)
  ..registerFactory<GetBusDocDataUsecase>(() => GetBusDocDataUsecase(busDataRepo: serviceLocator()),)
  ..registerFactory<BusDataCubit>(() => BusDataCubit(getBusDocDataUsecase: serviceLocator()),);
}