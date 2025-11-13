import 'package:evide_stop_announcer_app/core/common/bus_data_domain/entity/active_trip_data_entity.dart';
import 'package:evide_stop_announcer_app/core/failure/failure.dart';
import 'package:evide_stop_announcer_app/core/usecase/usecase.dart';
import 'package:evide_stop_announcer_app/core/common/bus_data_domain/bus_data_repo/bus_repo.dart';
import 'package:fpdart/fpdart.dart';

class GetActiveTripDataUsecase implements Usecase<ActiveTripDataEntity, int>{
  final BusDataRepo busDataRepo;

  GetActiveTripDataUsecase({required this.busDataRepo});
  @override
  Future<Either<Failure, ActiveTripDataEntity>> call({required int params}) async{
    return await busDataRepo.getActiveTripData(busId: params);
  }

}
