import 'package:evide_stop_announcer_app/core/failure/failure.dart';
import 'package:evide_stop_announcer_app/features/ads_play_page/data/bus_data.dart';
import 'package:evide_stop_announcer_app/features/ads_play_page/domain/entity/bus_data_entity.dart';
import 'package:evide_stop_announcer_app/features/ads_play_page/domain/bus_data_repo/bus_repo.dart';
import 'package:fpdart/fpdart.dart';

class BusDataRepoImpl implements BusDataRepo{
  final BusData busData;

  BusDataRepoImpl({required this.busData});
  @override
  Future<Either<Failure, BusDataEntity?>> getBusDocData({required String busPairingCode}) async{
    try {
      final res = await busData.getBusDocData(busPairingCode: busPairingCode);
      if (res != null) {
        return Right(res);
      }else {
        return Left(Failure(message: "Bus document does not exist"));
      }
    } catch (e) {
      return Left(Failure(message: "Error fetching bus document"));
    }
  }

}
