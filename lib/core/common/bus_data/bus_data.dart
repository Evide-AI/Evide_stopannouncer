import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:evide_stop_announcer_app/core/common/bus_data/model/audio_video_model.dart';
import 'package:evide_stop_announcer_app/core/common/bus_data/model/timeline_model.dart';
import 'package:evide_stop_announcer_app/core/common/bus_data_domain/entity/bus_data_entity.dart';
import 'package:evide_stop_announcer_app/core/constants/db_constants.dart';
import 'package:evide_stop_announcer_app/core/failure/failure.dart';
import 'package:evide_stop_announcer_app/core/common/bus_data/model/bus_data_model.dart';
import 'package:evide_stop_announcer_app/core/services/api_service.dart';
import 'package:evide_stop_announcer_app/core/services/service_locator.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:evide_stop_announcer_app/core/common/bus_data/model/active_trip_data_model.dart';
import 'package:evide_stop_announcer_app/core/constants/api_endpoint.dart';
import 'package:evide_stop_announcer_app/core/constants/backend_constants.dart';
import 'package:evide_stop_announcer_app/core/services/api_reponse.dart';

abstract class BusData {
  Future<BusDataEntity?> getBusDocData({required String busPairingCode});
  Future<TimeLineModel> getActiveTripData({required int? busId});
  // Stream<List<String>> streamBusVideos({required String busPairingCode});
  Stream<AudioVideoModel>? streamBusVideosAndAudios({required String busPairingCode});
}

class BusDataImpl implements BusData {
  final FirebaseFirestore firebaseFirestore;
  final Dio dio;

  BusDataImpl({required this.firebaseFirestore, required this.dio});

  // @override
  // Stream<List<String>> streamBusVideos({required String busPairingCode}) {
  //   try {
  //     return firebaseFirestore
  //       .collection(DbConstants.busesCollection)
  //       .doc(busPairingCode)
  //       .snapshots()
  //       .map((doc) {
  //         if (!doc.exists || doc.data() == null) return [];

  //         final data = doc.data()!;
  //         return data[DbConstants.adVideos] != null
  //             ? List<String>.from(data[DbConstants.adVideos])
  //             : [];
  //       });
  //   } catch (e) {
  //     return [] as Stream<List<String>>;
  //   }
  // }

  @override
  Stream<AudioVideoModel>? streamBusVideosAndAudios({required String busPairingCode}) {
    try {
      return firebaseFirestore
          .collection(DbConstants.busesCollection)
          .doc(busPairingCode)
          .snapshots()
          .map((doc) {
        if (!doc.exists || doc.data() == null) {
          return AudioVideoModel(videoUrls: [], audios: {});
        }

        final data = doc.data()!;

        // VIDEOS → LIST<String>
        final videos = data[DbConstants.adVideos] != null
            ? List<String>.from(data[DbConstants.adVideos])
            : <String>[];

        // STOP AUDIOS → MAP<String, dynamic>
        final stopAudiosMap = data[DbConstants.stopAudios] != null
            ? Map<String, dynamic>.from(data[DbConstants.stopAudios])
            : <String, dynamic>{};

        return AudioVideoModel(
          videoUrls: videos,
          audios: stopAudiosMap,
        );
      });
    } catch (e) {
      return null;
    }
  }

  // method to get bus document data by pairing code
  @override
  Future<BusDataEntity?> getBusDocData({required String busPairingCode}) async {
    try {
      final doc = await firebaseFirestore.collection(DbConstants.busesCollection).doc(busPairingCode).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;

        // return BusDataModel.fromMap(data);
        BusDataEntity busDataModel = BusDataModel.fromMap(data);
        if (busDataModel.busId != null) {
          try {
            // getting all trips of th bus by bus id
            final allTrips = await getAllTripsByBusId(busId: busDataModel.busId!);
            if(allTrips.isNotEmpty){ // checking all trips is not empty
              final activeTrips = allTrips.where((trip) => trip.isTripActive == true).toList(); // filter out the active trip from the trip list
              if(activeTrips.isNotEmpty){ // checking activetrips not empty
                final activeTrip = activeTrips.first; //taking the first, because only one active for a bus at a time
                if (activeTrip.tripId != null) { // if trip id id not null, then getting the timeline response of that trip
                    final timelineResponse = await serviceLocator<ApiService>().get(url: "${BackendConstants.baseUrl}${ApiEndpoint.getTripTimeLineData(tripId: activeTrip.tripId!)}");
                    final apiResponse = ApiResponse.fromJson(
                      json: timelineResponse?.data,
                      fromDataJson: (data) {
                        return TimeLineModel.fromJson(data);
                      },
                    );
                    busDataModel = busDataModel.copyWith(activeTripTimelineModel : apiResponse.data); // storing the trip data on busdata model
                }
              }
            }
            return busDataModel; // returning the busdata model
          } catch (e) {
            debugPrint('Error fetching active trip data: $e');
          }
        }

        return busDataModel; // if not active trip found return bus data model from here
      }else {
        throw Failure(message: "Bus document does not exist");
      }
    } catch (e) {
      debugPrint('Error fetching bus document: $e');
      throw Failure(message: "Error fetching bus document");
    }
  }

  // method to get all trips by bus id
  Future<List<ActiveTripDataModel>> getAllTripsByBusId({required int busId, int pageNo = 1}) async {
    try {
      final response = await serviceLocator<ApiService>().get(url: "${BackendConstants.baseUrl}${ApiEndpoint.getTripsByBusId(busId: busId, pageNo: pageNo)}");
      final apiResponse = ApiResponse.fromJson(json: response?.data, fromDataJson: (data) {
        return (data["trips"] as List).map((e) {
          return ActiveTripDataModel.fromJson(e);
        },);
      },);
      if (!apiResponse.success) {
        throw Failure(message: apiResponse.message ?? "Unable to fetch trips");
      }

      return apiResponse.data?.toList() ?? [];
    } catch (e) {
      throw Failure(message: "Unable to fetch trips");
    }
  }
  
  @override
  Future<TimeLineModel> getActiveTripData({required int? busId}) async {
    try {
      if (busId == null) {
        throw Failure(message: "Bus Id is null, No trip data found");
      }
      // get all trips by bus id
      final allTrips = await getAllTripsByBusId(busId: busId);
      // if all trips is not empty, filter active trips
      if(allTrips.isNotEmpty){
        final activeTrips = allTrips.where((trip) => trip.isTripActive == true).toList();
        if(activeTrips.isNotEmpty){
          final activeTrip = activeTrips.first;
          // if active trip found, get timeline data
          if (activeTrip.tripId != null) {
            final timelineResponse = await serviceLocator<ApiService>().get(url: "${BackendConstants.baseUrl}${ApiEndpoint.getTripTimeLineData(tripId: activeTrip.tripId!)}");
            final apiResponse = ApiResponse.fromJson(
              json: timelineResponse?.data,
              fromDataJson: (data) {
                return TimeLineModel.fromJson(data);
              },
            );
            // return timeline data if success
            if(apiResponse.success){
              if (apiResponse.data != null) {
                return apiResponse.data!;
              } else {
                throw Failure(message: "No timeline data found");
              }
            }else {
              throw Failure(message: apiResponse.message ?? "Unable to fetch timeline data");
            }
          } else {
            throw Failure(message: "Invalid Trip ID");
          }
        }else {
          throw Failure(message: "No Active Trips Found");
        }
      }else {
        throw Failure(message: "No Active Trips Found");
      }
    } catch (e) {
      debugPrint('Error fetching bus document: $e');
      throw Failure(message: "Error fetching active trip data");
    }
  }
}
