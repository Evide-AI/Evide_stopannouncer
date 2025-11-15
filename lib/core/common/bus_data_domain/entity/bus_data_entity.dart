import 'package:equatable/equatable.dart';
import 'package:evide_stop_announcer_app/core/common/bus_data_domain/entity/timeline_entity.dart';

class BusDataEntity extends Equatable{
  final int? busId;
  final String? busName;
  final String? busNumberPlate;
  final List<String>? adVideos;
  final Map<String, dynamic>? stopAudios;
  final TimeLineEntity? activeTripTimelineModel;

  const BusDataEntity({
    this.busId,
    this.busName,
    this.busNumberPlate,
    this.adVideos,
    this.stopAudios,
    this.activeTripTimelineModel,
  });

  BusDataEntity copyWith({
    int? busId,
    String? busName,
    String? busNumberPlate,
    List<String>? adVideos,
    Map<String, dynamic>? stopAudios,
    TimeLineEntity? activeTripTimelineModel,
  }) {
    return BusDataEntity(
      busId: busId ?? this.busId,
      busName: busName ?? this.busName,
      busNumberPlate: busNumberPlate ?? this.busNumberPlate,
      adVideos: adVideos ?? this.adVideos,
      stopAudios: stopAudios ?? this.stopAudios,
      activeTripTimelineModel: activeTripTimelineModel ?? this.activeTripTimelineModel,
    );
  }

  @override
  List<Object?> get props => [
    busId,
    busName,
    busNumberPlate,
    adVideos,
    stopAudios,
    activeTripTimelineModel,
  ];
}
