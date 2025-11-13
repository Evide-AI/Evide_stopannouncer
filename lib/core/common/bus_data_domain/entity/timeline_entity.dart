import 'package:equatable/equatable.dart';

class TimeLineEntity extends Equatable {
  final TripDetailsEntity? tripDetails;
  final CurrentStatusEntity? currentStatus;
  final List<StopEntity>? stopList;

  const TimeLineEntity({
    this.tripDetails,
    this.currentStatus,
    this.stopList,
  });

  TimeLineEntity copyWith({
    TripDetailsEntity? tripDetails,
    CurrentStatusEntity? currentStatus,
    List<StopEntity>? stopList,
  }) {
    return TimeLineEntity(
      tripDetails: tripDetails ?? this.tripDetails,
      currentStatus: currentStatus ?? this.currentStatus,
      stopList: stopList ?? this.stopList,
    );
  }

  @override
  List<Object?> get props => [tripDetails, currentStatus, stopList];
}

// stop entity
class StopEntity extends Equatable {
  final int? sequenceOrder;
  final int? stopId;
  final String? stopName;
  final double? latitude;
  final double? longitude;
  final String? scheduledArrivalTime;
  final String? scheduledDepartureTime;

  const StopEntity({
    this.sequenceOrder,
    this.stopId,
    this.stopName,
    this.latitude,
    this.longitude,
    this.scheduledArrivalTime,
    this.scheduledDepartureTime,
  });

  StopEntity copyWith({
    int? sequenceOrder,
    int? stopId,
    String? stopName,
    double? latitude,
    double? longitude,
    String? scheduledArrivalTime,
    String? scheduledDepartureTime,
  }) {
    return StopEntity(
      sequenceOrder: sequenceOrder ?? this.sequenceOrder,
      stopId: stopId ?? this.stopId,
      stopName: stopName ?? this.stopName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      scheduledArrivalTime: scheduledArrivalTime ?? this.scheduledArrivalTime,
      scheduledDepartureTime: scheduledDepartureTime ?? this.scheduledDepartureTime,
    );
  }

  @override
  List<Object?> get props => [sequenceOrder, stopId, stopName, latitude, longitude, scheduledArrivalTime, scheduledDepartureTime];
}

// current status entity
class CurrentStatusEntity extends Equatable {
  final int? currentStopSequenceNumber;
  final int? nextStopSequenceNumber;
  final double? nextStopLat;
  final double? nextStopLon;
  final String? stopReachedTime;
  final double? distanceToNextStopMeters;
  const CurrentStatusEntity({
    this.currentStopSequenceNumber,
    this.nextStopSequenceNumber,
    this.nextStopLat,
    this.nextStopLon,
    this.stopReachedTime,
    this.distanceToNextStopMeters,
  });

  CurrentStatusEntity copyWith({
    int? currentStopSequenceNumber,
    int? nextStopSequenceNumber,
    double? nextStopLat,
    double? nextStopLon,
    String? stopReachedTime,
    double? distanceToNextStopMeters,
  }) {
    return CurrentStatusEntity(
      currentStopSequenceNumber: currentStopSequenceNumber ?? this.currentStopSequenceNumber,
      nextStopSequenceNumber: nextStopSequenceNumber ?? this.nextStopSequenceNumber,
      nextStopLat: nextStopLat ?? this.nextStopLat,
      nextStopLon: nextStopLon ?? this.nextStopLon,
      stopReachedTime: stopReachedTime ?? this.stopReachedTime,
      distanceToNextStopMeters: distanceToNextStopMeters ?? this.distanceToNextStopMeters,
    );
  }

  @override
  List<Object?> get props => [currentStopSequenceNumber, nextStopSequenceNumber, nextStopLat, nextStopLon, stopReachedTime, distanceToNextStopMeters];
}

// trip details entity

class TripDetailsEntity extends Equatable {
  final int? id;
  final String? busName;
  final String? busNumber;
  final bool? isActive;
  final String? startTime;
  final String? endTime;

  const TripDetailsEntity({
    this.id,
    this.busName,
    this.busNumber,
    this.isActive,
    this.startTime,
    this.endTime,
  });

  TripDetailsEntity copyWith({
    int? id,
    String? busName,
    String? busNumber,
    bool? isActive,
    String? startTime,
    String? endTime,
  }) {
    return TripDetailsEntity(
      id: id ?? this.id,
      busName: busName ?? this.busName,
      busNumber: busNumber ?? this.busNumber,
      isActive: isActive ?? this.isActive,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }

  @override
  List<Object?> get props => [id, busName, busNumber, isActive, startTime, endTime];
}