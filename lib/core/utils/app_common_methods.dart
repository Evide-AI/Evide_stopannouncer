import 'dart:math';
class AppCommonMethods {
  static final _rnd = Random.secure();

  static String generateSecretCode() {
    // Generate a 6-digit numeric code (100000 - 999999)
    final code = 100000 + _rnd.nextInt(900000);

    // Optionally add milliseconds-based offset to reduce collisions
    final uniqueOffset = DateTime.now().millisecondsSinceEpoch % 1000;

    // Mix both and ensure only 6 digits
    final uniqueCode = ((code + uniqueOffset) % 1000000).toString().padLeft(6, '0');

    return uniqueCode;
  }
}

