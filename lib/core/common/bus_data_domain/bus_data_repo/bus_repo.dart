import 'package:evide_stop_announcer_app/core/common/bus_data_domain/entity/active_trip_data_entity.dart';
import 'package:evide_stop_announcer_app/core/failure/failure.dart';
import 'package:evide_stop_announcer_app/core/common/bus_data_domain/entity/bus_data_entity.dart';
import 'package:fpdart/fpdart.dart';

abstract class BusDataRepo {
  Future<Either<Failure, BusDataEntity?>> getBusDocData({required String busPairingCode});
  Future<Either<Failure, ActiveTripDataEntity>> getActiveTripData({required int busId});
}
