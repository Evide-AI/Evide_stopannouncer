import 'package:evide_stop_announcer_app/core/common/bus_data_domain/entity/active_trip_data_entity.dart';

class ActiveTripDataModel extends ActiveTripDataEntity{
  const ActiveTripDataModel({
    super.tripId,
    super.busName,
    super.busNumber,
    super.busStartPointName,
    super.busEndPointName,
    super.busStartTimeFromRoute,
    super.busEndTimeOnEndRoute,
    super.isTripActive,
    super.isAdvertisementAvailable,
  });

   factory ActiveTripDataModel.fromJson(Map<String, dynamic> json) {
    return ActiveTripDataModel(
      tripId: json['id'] as int?,
      busName: json['bus_name'] as String?,
      busNumber: json['bus_number'] as String?,
      busStartPointName: json['start_point'] as String?,
      busEndPointName: json['end_point'] as String?,
      busStartTimeFromRoute: json['route_start_time'] as String?,
      busEndTimeOnEndRoute: json['route_end_time'] as String?,
      isTripActive: json['is_active'] as bool?,
      isAdvertisementAvailable: json["is_advertisement_available"] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': tripId,
      'bus_name': busName,
      'bus_number': busNumber,
      'start_point': busStartPointName,
      'end_point': busEndPointName,
      'route_start_time': busStartTimeFromRoute,
      'route_end_time': busEndTimeOnEndRoute,
      'is_active': isTripActive,
      'is_advertisement_available': isAdvertisementAvailable,
    };
  }
}
