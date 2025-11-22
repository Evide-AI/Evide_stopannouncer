import 'package:evide_stop_announcer_app/core/common/bus_data/model/audio_video_model.dart';
import 'package:evide_stop_announcer_app/core/common/bus_data_domain/entity/timeline_entity.dart';
import 'package:evide_stop_announcer_app/core/failure/failure.dart';
import 'package:evide_stop_announcer_app/core/common/bus_data_domain/entity/bus_data_entity.dart';
import 'package:fpdart/fpdart.dart';

abstract class BusDataRepo {
  Future<Either<Failure, BusDataEntity?>> getBusDocData({required String busPairingCode});
  Future<Either<Failure, TimeLineEntity>> getActiveTripData({required int busId});
  // Stream<Either<Failure, List<String>>> streamBusVideos({required String busPairingCode});
  Stream<Either<Failure, AudioVideoModel>> streamBusVideosAndAudios({required String busPairingCode});
}
