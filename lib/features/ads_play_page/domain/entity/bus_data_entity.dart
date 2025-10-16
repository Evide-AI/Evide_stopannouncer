import 'package:equatable/equatable.dart';

class BusDataEntity extends Equatable{
  final String? busName;
  final String? busNumberPlate;
  final List<String>? adVideos;
  final List<String>? stopAudios;

  const BusDataEntity({
    this.busName,
    this.busNumberPlate,
    this.adVideos,
    this.stopAudios,
  });

  BusDataEntity copyWith({
    String? busName,
    String? busNumberPlate,
    List<String>? adVideos,
    List<String>? stopAudios,
  }) {
    return BusDataEntity(
      busName: busName ?? this.busName,
      busNumberPlate: busNumberPlate ?? this.busNumberPlate,
      adVideos: adVideos ?? this.adVideos,
      stopAudios: stopAudios ?? this.stopAudios,
    );
  }

  @override
  List<Object?> get props => [
    busName,
    busNumberPlate,
    adVideos,
    stopAudios,
  ];
}