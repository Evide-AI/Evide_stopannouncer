import 'package:evide_stop_announcer_app/core/failure/failure.dart';
import 'package:evide_stop_announcer_app/core/usecase/usecase.dart';
import 'package:evide_stop_announcer_app/core/common/bus_data_domain/bus_data_repo/bus_repo.dart';
import 'package:evide_stop_announcer_app/core/common/bus_data_domain/entity/bus_data_entity.dart';
import 'package:fpdart/fpdart.dart';

class GetBusDocDataUsecase implements Usecase<BusDataEntity?, String>{
  final BusDataRepo busDataRepo;

  GetBusDocDataUsecase({required this.busDataRepo});
  @override
  Future<Either<Failure, BusDataEntity?>> call({required String params}) async{
    return await busDataRepo.getBusDocData(busPairingCode: params);
  }

}