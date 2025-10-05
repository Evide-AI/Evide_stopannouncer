import 'dart:math';
class AppCommonMethods {
  static String generateSecretCode() {
    const String chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final rnd = Random.secure(); // Better randomness

    // Random 6 chars + 2 chars derived from timestamp for uniqueness
    final randomPart = List.generate(
      6,
      (_) => chars[rnd.nextInt(chars.length)],
    ).join();

    final timestampPart = DateTime.now().millisecondsSinceEpoch
        .toRadixString(36)
        .substring(0, 2); // adds time-based uniqueness

    return randomPart + timestampPart; // total 8 chars
  }
}
