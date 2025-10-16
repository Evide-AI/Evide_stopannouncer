import 'package:evide_stop_announcer_app/core/failure/failure.dart';
import 'package:evide_stop_announcer_app/features/ads_play_page/domain/entity/bus_data_entity.dart';
import 'package:fpdart/fpdart.dart';

abstract class BusDataRepo {
  Future<Either<Failure, BusDataEntity?>> getBusDocData({required String busPairingCode});
}