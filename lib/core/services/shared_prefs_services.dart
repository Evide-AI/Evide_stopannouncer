import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsServices {
  static String pairingCodeKey = 'DevicePairingCode';
  static String isPairedKey = 'IsDevicePaired';

  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // saving pairing code to local storage
  static Future<bool> savePairingCodeToLocalStorage({required String pairingCode}) async {
    bool isSaved = await _prefs.setString(pairingCodeKey, pairingCode);
    return isSaved;
  }
  // getting pairing code from local storage
  static String? getPairingCode() {
    return _prefs.getString(pairingCodeKey);
  }

  static Future<void> setIsPaired({required bool isPaired}) async {
    await _prefs.setBool(isPairedKey, isPaired);
  }

  // save isPaired data
  static bool? getIsPaired() {
    return _prefs.getBool(isPairedKey);
  }
}