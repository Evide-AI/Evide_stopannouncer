import 'package:evide_stop_announcer_app/core/common/bus_data_domain/entity/timeline_entity.dart';

class TimeLineModel extends TimeLineEntity{
  const TimeLineModel({
    super.tripDetails,
    super.currentStatus,
    super.stopList,
  });

  factory TimeLineModel.fromJson(Map<String, dynamic> json) {
    return TimeLineModel(
      tripDetails: json['trip_details'] != null
          ? TripDetailsModel.fromJson(json['trip_details'])
          : null,
      currentStatus: json['current_status'] != null
          ? CurrentStatusModel.fromJson(json['current_status'])
          : null,
      stopList: (json['stops'] as List?)
          ?.map((e) => StopModel.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'trip_details': (tripDetails is TripDetailsModel)
          ? (tripDetails as TripDetailsModel).toJson()
          : null,
      'current_status': (currentStatus is CurrentStatusModel)
          ? (currentStatus as CurrentStatusModel).toJson()
          : null,
      'stops': stopList != null
          ? (stopList as List)
              .map((e) => (e as StopModel).toJson()).toList()
          : null,
    };
  }
}

// current status model
class CurrentStatusModel extends CurrentStatusEntity {

  const CurrentStatusModel({
    super.currentStopSequenceNumber,
    super.nextStopSequenceNumber,
    super.nextStopLat,
    super.nextStopLon,
    super.stopReachedTime,
    super.distanceToNextStopMeters,
  });

  factory CurrentStatusModel.fromJson(Map<String, dynamic> json) {
    return CurrentStatusModel(
      currentStopSequenceNumber: json['current_stop_sequence_number'] as int?,
      nextStopSequenceNumber: json['next_stop_sequence_number'] as int?,
      nextStopLat: (json['next_stop_lat'] as num?)?.toDouble(),
      nextStopLon: (json['next_stop_lon'] as num?)?.toDouble(),
      stopReachedTime: json['timestamp'] as String?,
      distanceToNextStopMeters:
          (json['distanceToNextStopMeters'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current_stop_sequence_number': currentStopSequenceNumber,
      'next_stop_sequence_number': nextStopSequenceNumber,
      'next_stop_lat': nextStopLat,
      'next_stop_lon': nextStopLon,
      'timestamp': stopReachedTime,
      'distanceToNextStopMeters': distanceToNextStopMeters,
    };
  }
}

// stop model
class StopModel extends StopEntity {
  const StopModel({
    super.sequenceOrder,
    super.stopId,
    super.stopName,
    super.latitude,
    super.longitude,
    super.scheduledArrivalTime,
    super.scheduledDepartureTime,
  });

  factory StopModel.fromJson(Map<String, dynamic> json) {
    double? lat;
    double? lon;

    final locationData = json['location'];

    if (locationData is String) {
      // Case 1: WKT string like "POINT(77.2090 28.6139)"
      if (locationData.startsWith('POINT(') && locationData.endsWith(')')) {
        final coords =
            locationData.substring(6, locationData.length - 1).split(' ');
        if (coords.length == 2) {
          lon = double.tryParse(coords[0]);
          lat = double.tryParse(coords[1]);
        }
      }
    } else if (locationData is Map<String, dynamic>) {
      // Case 2: Object/map like {"x": 77.2090, "y": 28.6139} or {"longitude": ..., "latitude": ...}
      lon = (locationData['x'] ?? locationData['longitude'])?.toDouble();
      lat = (locationData['y'] ?? locationData['latitude'])?.toDouble();
    }

    return StopModel(
      sequenceOrder: json['sequence_order'] as int?,
      stopId: json['stop_id'] as int?,
      stopName: json['stop_name'] as String?,
      latitude: lat,
      longitude: lon,
      scheduledArrivalTime: json['scheduled_arrival_time'],
      scheduledDepartureTime: json['scheduled_departure_time'],
    );
  }

  /// ✅ Convert model to JSON
  Map<String, dynamic> toJson() {
    String? location;
    if (longitude != null && latitude != null) {
      location = 'POINT($longitude $latitude)';
    }

    return {
      'sequence_order': sequenceOrder,
      'stop_id': stopId,
      'stop_name': stopName,
      'location': location,
      'scheduled_arrival_time': scheduledArrivalTime,
      'scheduled_departure_time': scheduledDepartureTime,
    };
  }
}

// trip details model
class TripDetailsModel extends TripDetailsEntity {
  const TripDetailsModel({
    super.id,
    super.busName,
    super.busNumber,
    super.isActive,
    super.startTime,
    super.endTime,
  });

  factory TripDetailsModel.fromJson(Map<String, dynamic> json) {
    return TripDetailsModel(
      id: json['id'] as int?,
      busName: json['bus_name'] as String?,
      busNumber: json['bus_number'] as String?,
      isActive: json['is_active'] as bool?,
      startTime: json['start_time'],
      endTime: json['end_time'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bus_name': busName,
      'bus_number': busNumber,
      'is_active': isActive,
      'start_time': startTime,
      'end_time': endTime,
    };
  }
}