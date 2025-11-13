import 'package:equatable/equatable.dart';

class ActiveTripDataEntity extends Equatable{
  final int? tripId;
  final String? busName;
  final String? busNumber;
  final String? busStartPointName;
  final String? busEndPointName;
  final String? busStartTimeFromRoute;
  final String? busEndTimeOnEndRoute;
  final bool? isTripActive;
  final bool? isAdvertisementAvailable;

  const ActiveTripDataEntity({
    this.tripId,
    this.busName,
    this.busNumber,
    this.busStartPointName,
    this.busEndPointName,
    this.busStartTimeFromRoute,
    this.busEndTimeOnEndRoute,
    this.isTripActive,
    this.isAdvertisementAvailable,
  });

  ActiveTripDataEntity copyWith({
    int? tripId,
    String? busName,
    String? busNumber,
    String? busStartPointName,
    String? busEndPointName,
    String? busStartTimeFromRoute,
    String? busEndTimeOnEndRoute,
    bool? isTripActive,
    bool? isAdvertisementAvailable,
  }) {
    return ActiveTripDataEntity(
      tripId: tripId ?? this.tripId,
      busName: busName ?? this.busName,
      busNumber: busNumber ?? this.busNumber,
      busStartPointName: busStartPointName ?? this.busStartPointName,
      busEndPointName: busEndPointName ?? this.busEndPointName,
      busStartTimeFromRoute: busStartTimeFromRoute ?? this.busStartTimeFromRoute,
      busEndTimeOnEndRoute: busEndTimeOnEndRoute ?? this.busEndTimeOnEndRoute,
      isTripActive: isTripActive ?? this.isTripActive,
      isAdvertisementAvailable: isAdvertisementAvailable ?? this.isAdvertisementAvailable,
    );
  }

  @override
  List<Object?> get props => [
    tripId, busName, busNumber, busStartPointName, busEndPointName, busStartTimeFromRoute, busEndTimeOnEndRoute, isTripActive
  ];
}
