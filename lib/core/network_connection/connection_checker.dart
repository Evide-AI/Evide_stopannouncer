import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';

class ConnectionChecker {
  // Singleton instance
  static final ConnectionChecker _instance = ConnectionChecker._internal();

  factory ConnectionChecker() => _instance;

  ConnectionChecker._internal() {
    _monitorConnection();
  }

  final StreamController<bool> _connectionStreamController =
      StreamController<bool>.broadcast();

  Timer? _monitorTimer;
  bool _lastStatus = false;
  int _failureCount = 0;

  /// Public stream to subscribe to real-time connectivity changes
  Stream<bool> get connectionStream => _connectionStreamController.stream;

  /// Start periodic connection monitoring
  void _monitorConnection() {
    _checkAndEmit(); // Initial check

    _monitorTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _checkAndEmit();
    });
  }

  /// Emit connection changes only when status changes
  Future<void> _checkAndEmit() async {
    final currentStatus = await ConnectionChecker.checkConnectivity();

    if (currentStatus != _lastStatus) {
      _lastStatus = currentStatus;
      _connectionStreamController.add(currentStatus);
      _failureCount = 0;
    } else if (!currentStatus) {
      _failureCount++;
      debugPrint("Connectivity check failed ($_failureCount times)");
    }
  }

  static Future<bool> checkConnectivity() async {
    // if (await _checkSocketPing()) return true;

    const endpoints = [
      'https://one.one.one.one/', // Cloudflare DNS
      'https://www.google.com', // Google fallback
    ];

    for (final endpoint in endpoints) {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 3);
      try {
        final request = await client.headUrl(Uri.parse(endpoint));
        final response = await request.close();
        client.close(force: true);

        if (response.statusCode < 400) return true;
      } catch (e) {
        debugPrint("HTTP connection check failed: $e");
        client.close(force: true);
      }
    }

    return false;
  }

  /// Manually dispose monitoring
  void dispose() {
    _monitorTimer?.cancel();
    _connectionStreamController.close();
  }
}
