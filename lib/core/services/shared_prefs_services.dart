import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsServices {
  static String pairingCodeKey = 'DevicePairingCode';
  static String isPairedKey = 'IsDevicePaired';
  // saving pairing code to local storage
  static Future<bool> savePairingCodeToLocalStorage({required String pairingCode}) async {
    final sharedPrefs = await SharedPreferences.getInstance();
    bool isSaved = await sharedPrefs.setString(pairingCodeKey, pairingCode);
    return isSaved;
  }
  // getting pairing code from local storage
  static Future<String?> getPairingCode() async{
    final sharedPrefs = await SharedPreferences.getInstance();
    return sharedPrefs.getString(pairingCodeKey);
  }

  static Future<void> setIsPaired({required bool isPaired}) async {
    final sharedPrefs = await SharedPreferences.getInstance();
    await sharedPrefs.setBool(isPairedKey, isPaired);
  }

  // save isPaired data
  static Future<bool?> getIsPaired() async {
    final sharedPrefs = await SharedPreferences.getInstance();
    return sharedPrefs.getBool(isPairedKey);
  }
}