import 'package:evide_stop_announcer_app/core/constants/db_constants.dart';
import 'package:evide_stop_announcer_app/features/ads_play_page/domain/entity/bus_data_entity.dart';

class BusDataModel extends BusDataEntity{
  const BusDataModel({
    super.busName,
    super.busNumberPlate,
    super.adVideos,
    super.stopAudios,
  });

  factory BusDataModel.fromMap(Map<String, dynamic> map) {
    return BusDataModel(
      busName: map[DbConstants.busName] as String?,
      busNumberPlate: map[DbConstants.busNumberPlate] as String?,
      // adVideos: List<String>.from(map[DbConstants.adVideos] as List<dynamic>? ?? []),
      // stopAudios: List<String>.from(map[DbConstants.stopAudios] as List<dynamic>? ?? []),
      adVideos: map[DbConstants.adVideos],
      stopAudios: map[DbConstants.stopAudios],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      DbConstants.busName: busName,
      DbConstants.busNumberPlate: busNumberPlate,
      DbConstants.adVideos: adVideos,
      DbConstants.stopAudios: stopAudios,
    };
  }
}