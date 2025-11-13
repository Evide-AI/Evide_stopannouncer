import 'package:equatable/equatable.dart';

class BusDataEntity extends Equatable{
  final int? busId;
  final String? busName;
  final String? busNumberPlate;
  final List<String>? adVideos;
  final Map<String, dynamic>? stopAudios;

  const BusDataEntity({
    this.busId,
    this.busName,
    this.busNumberPlate,
    this.adVideos,
    this.stopAudios,
  });

  BusDataEntity copyWith({
    int? busId,
    String? busName,
    String? busNumberPlate,
    List<String>? adVideos,
    Map<String, dynamic>? stopAudios,
  }) {
    return BusDataEntity(
      busId: busId ?? this.busId,
      busName: busName ?? this.busName,
      busNumberPlate: busNumberPlate ?? this.busNumberPlate,
      adVideos: adVideos ?? this.adVideos,
      stopAudios: stopAudios ?? this.stopAudios,
    );
  }

  @override
  List<Object?> get props => [
    busId,
    busName,
    busNumberPlate,
    adVideos,
    stopAudios,
  ];
}
