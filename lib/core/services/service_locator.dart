import 'package:evide_stop_announcer_app/features/stop_announcer_parent_screen/presentation/cubit/stop_announcer_parent_screen_cubit.dart';
import 'package:get_it/get_it.dart';

GetIt serviceLocator = GetIt.instance;

initDependencies(){
  initHomeDependencies();
}


initHomeDependencies() {
  serviceLocator.registerFactory<StopAnnouncerParentScreenCubit>(() {
    return StopAnnouncerParentScreenCubit();
  },);
}
