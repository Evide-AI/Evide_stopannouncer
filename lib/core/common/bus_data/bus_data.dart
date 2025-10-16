import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:evide_stop_announcer_app/core/constants/db_constants.dart';
import 'package:evide_stop_announcer_app/core/failure/failure.dart';
import 'package:evide_stop_announcer_app/core/common/bus_data/model/bus_data_model.dart';
import 'package:flutter/foundation.dart';

abstract class BusData {
  Future<BusDataModel?> getBusDocData({required String busPairingCode});
}

class BusDataImpl implements BusData {
  final FirebaseFirestore firebaseFirestore;

  BusDataImpl({required this.firebaseFirestore});
  @override
  Future<BusDataModel?> getBusDocData({required String busPairingCode}) async {
    try {
      final doc = await firebaseFirestore.collection(DbConstants.busesCollection).doc(busPairingCode).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;

        return BusDataModel(
          busName: data[DbConstants.busName] as String?,
          busNumberPlate: data[DbConstants.busNumberPlate] as String?,
          adVideos: data[DbConstants.adVideos] != null
              ? List<String>.from(data[DbConstants.adVideos])
              : [],
          stopAudios: data[DbConstants.stopAudios] != null
              ? List<String>.from(data[DbConstants.stopAudios])
              : [],
        );
      }else {
        throw Failure(message: "Bus document does not exist");
      }
    } catch (e) {
      debugPrint('Error fetching bus document: $e');
      throw Failure(message: "Error fetching bus document");
    }
  }
}