import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:evide_stop_announcer_app/core/constants/db_constants.dart';
import 'package:evide_stop_announcer_app/core/failure/failure.dart';
import 'package:evide_stop_announcer_app/core/common/bus_data/model/bus_data_model.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:evide_stop_announcer_app/core/common/bus_data/model/active_trip_data_model.dart';
import 'package:evide_stop_announcer_app/core/constants/api_endpoint.dart';
import 'package:evide_stop_announcer_app/core/constants/backend_constants.dart';
import 'package:evide_stop_announcer_app/core/services/api_reponse.dart';

abstract class BusData {
  Future<BusDataModel?> getBusDocData({required String busPairingCode});
  Future<ActiveTripDataModel> getActiveTripData({required int busId});
}

class BusDataImpl implements BusData {
  final FirebaseFirestore firebaseFirestore;
  final Dio dio;

  BusDataImpl({required this.firebaseFirestore, required this.dio});
  @override
  Future<BusDataModel?> getBusDocData({required String busPairingCode}) async {
    try {
      final doc = await firebaseFirestore.collection(DbConstants.busesCollection).doc(busPairingCode).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;

        return BusDataModel.fromMap(data);
      }else {
        throw Failure(message: "Bus document does not exist");
      }
    } catch (e) {
      debugPrint('Error fetching bus document: $e');
      throw Failure(message: "Error fetching bus document");
    }
  }

  Future<List<ActiveTripDataModel>> getAllTripsByBusId({required int busId, int pageNo = 1}) async {
    try {
      final response = await dio.get("${BackendConstants.baseUrl}${ApiEndpoint.getTripsByBusId(busId: busId, pageNo: pageNo)}");
      final apiResponse = ApiResponse.fromJson(json: response.data, fromDataJson: (data) {
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
  Future<ActiveTripDataModel> getActiveTripData({required int busId}) async {
    try {
      final allTrips = await getAllTripsByBusId(busId: busId);
      if(allTrips.isNotEmpty){
        final activeTrips = allTrips.where((trip) => trip.isTripActive == true).toList();
        if(activeTrips.isNotEmpty){
          return activeTrips.first;
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
