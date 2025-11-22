import 'package:evide_stop_announcer_app/core/common/bus_data/model/audio_video_model.dart';
import 'package:evide_stop_announcer_app/core/common/bus_data_domain/bus_data_repo/bus_repo.dart';
import 'package:evide_stop_announcer_app/core/failure/failure.dart';
import 'package:evide_stop_announcer_app/core/usecase/stream_usecase.dart';
import 'package:fpdart/fpdart.dart';

// class StreamBusVideosUsecase implements StreamUsecase<List<String>, String>{
//   final BusDataRepo busDataRepo;

//   StreamBusVideosUsecase({required this.busDataRepo});
//   @override
//   Stream<Either<Failure, List<String>>> call({required String params}) {
//     return busDataRepo.streamBusVideos(busPairingCode: params);
//   }
// }

class StreamBusVideosUsecase implements StreamUsecase<AudioVideoModel, String>{
  final BusDataRepo busDataRepo;

  StreamBusVideosUsecase({required this.busDataRepo});
  @override
  Stream<Either<Failure, AudioVideoModel>> call({required String params}) {
    return busDataRepo.streamBusVideosAndAudios(busPairingCode: params);
  }
}
