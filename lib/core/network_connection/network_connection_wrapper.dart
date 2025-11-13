import 'dart:async';

import 'package:evide_stop_announcer_app/core/app_imports.dart';
import 'package:evide_stop_announcer_app/core/network_connection/connection_checker.dart';
import 'package:evide_stop_announcer_app/core/network_connection/no_internet_connection_widget.dart';

import 'package:flutter/material.dart';

// import your connection checker and widget
// import 'connection_checker.dart';
// import 'no_internet_connection_widget.dart';

class NetworkConnectionWrapper extends StatefulWidget {
  final Widget child;

  const NetworkConnectionWrapper({super.key, required this.child});

  @override
  State<NetworkConnectionWrapper> createState() =>
      _NetworkConnectionWrapperState();
}

class _NetworkConnectionWrapperState extends State<NetworkConnectionWrapper> {
  late StreamSubscription<bool> _connectionSubscription;
  bool _lastConnectionStatus = true;

  @override
  void initState() {
    super.initState();

    _initializeConnectionStatus();

    _connectionSubscription =
        ConnectionChecker().connectionStream.listen(_handleConnectionChange);
  }

  Future<void> _initializeConnectionStatus() async {
    final isConnected = await ConnectionChecker.checkConnectivity();
    setState(() {
      _lastConnectionStatus = isConnected;
    });
  }

  void _handleConnectionChange(bool hasConnection) {
    if (_lastConnectionStatus == hasConnection) return;

    setState(() {
      _lastConnectionStatus = hasConnection;
    });

    if (!hasConnection) {
    }
  }

  @override
  void dispose() {
    _connectionSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      child: _lastConnectionStatus
          ? widget.child
          : const NoInternetConnectionWidget(),
    );
  }
}
