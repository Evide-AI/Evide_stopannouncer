import 'package:evide_stop_announcer_app/core/common/bus_data/model/audio_video_model.dart';
import 'package:evide_stop_announcer_app/core/common/bus_data/model/timeline_model.dart';
import 'package:evide_stop_announcer_app/core/failure/failure.dart';
import 'package:evide_stop_announcer_app/core/common/bus_data/bus_data.dart';
import 'package:evide_stop_announcer_app/core/common/bus_data_domain/entity/bus_data_entity.dart';
import 'package:evide_stop_announcer_app/core/common/bus_data_domain/bus_data_repo/bus_repo.dart';
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

   @override
  Future<Either<Failure, TimeLineModel>> getActiveTripData({required int busId}) async {
    try {
      final res = await busData.getActiveTripData(busId: busId);
      if (res != null) {
        return Right(res);
      }else {
        return Left(Failure(message: "No active trip data found"));
      }
    } catch (e) {
      return Left(Failure(message: e.toString()));
    }
  }

  // @override
  // Stream<Either<Failure, List<String>>> streamBusVideos({
  //   required String busPairingCode,
  // }) {
  //   try {
  //     return busData.streamBusVideos(busPairingCode: busPairingCode)
  //         .map((videos) {
  //       return Right(videos);
  //     });
  //   } catch (e) {
  //     return Stream.value(Left(Failure(message: e.toString())));
  //   }
  // }

  @override
  Stream<Either<Failure, AudioVideoModel>> streamBusVideosAndAudios({
    required String busPairingCode,
  }) {
    try {
      return busData
          .streamBusVideosAndAudios(busPairingCode: busPairingCode)!
          .map<Either<Failure, AudioVideoModel>>((data) {
        return Right(data);
      }).handleError((error) {
        return Left(Failure(message: error.toString()));
      });
    } catch (e) {
      return Stream.value(Left(Failure(message: e.toString())));
    }
  }


}
