import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'splashscreen_event.dart';
part 'splashscreen_state.dart';

class SplashscreenBloc extends Bloc<SplashscreenEvent, SplashscreenState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  SplashscreenBloc() : super(SplashscreenInitial()) {
    on<IsLinkedEvent>((event, emit) async {
      emit(Loadingsplash());

      try {
        // 1. Get pairing code from local storage
        final prefs = await SharedPreferences.getInstance();
        final localPairingCode = prefs.getString('pairingCode');

        if (localPairingCode == null) {
          emit(ScreenNotLinked());
          print('❌ No local pairing code found');
          return;
        }

        // 2. Query Firestore collection to check if document with the pairing code exists
        final querySnapshot = await _firestore
            .collection('Screens')
            .where('pairingCode', isEqualTo: localPairingCode)
            .get();

        if (querySnapshot.docs.isEmpty) {
          emit(ScreenNotLinked());
          print('❌ No matching Firestore document for $localPairingCode');
        } else {
          emit(ScreenLinked());
          print(
            "✅ Found Firestore doc with matching pairing code: $localPairingCode",
          );
        }
      } catch (e, stack) {
        print("🔥 Error: $e");
        print(stack);
        emit(SplashError(error: "Error checking pairing code: $e"));
      }
    });
  }
}
