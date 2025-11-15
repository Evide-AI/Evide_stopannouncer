import 'package:evide_stop_announcer_app/core/constants/db_constants.dart';
import 'package:evide_stop_announcer_app/core/common/bus_data_domain/entity/bus_data_entity.dart';

class BusDataModel extends BusDataEntity{
  const BusDataModel({
    super.busId,
    super.busName,
    super.busNumberPlate,
    super.adVideos,
    super.stopAudios,
    super.activeTripTimelineModel,
  });

  factory BusDataModel.fromMap(Map<String, dynamic> map) {
    return BusDataModel(
      busId: map[DbConstants.busId] as int?,
      busName: map[DbConstants.busName] as String?,
      busNumberPlate: map[DbConstants.busNumberPlate] as String?,
      adVideos: map[DbConstants.adVideos] != null ? List<String>.from(map[DbConstants.adVideos]) : null,
      stopAudios: map[DbConstants.stopAudios] != null
              ? Map<String, String>.from(map[DbConstants.stopAudios])
              : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      DbConstants.busId: busId,
      DbConstants.busName: busName,
      DbConstants.busNumberPlate: busNumberPlate,
      DbConstants.adVideos: adVideos,
      DbConstants.stopAudios: stopAudios,
    };
  }
}
