import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:evide_stop_announcer_app/core/network_connection/connection_checker.dart';
import 'package:evide_stop_announcer_app/core/services/api_core.dart';

class ApiService {

  ApiService() : apiCore = ApiCore(interceptors: [apiServiceInterceptor]);

  final ApiCore apiCore;

  // interceptor for ApiService
  static InterceptorsWrapper get apiServiceInterceptor => InterceptorsWrapper(
    onRequest: ((options, handler) async {
      // isNeedToWait added to check internet connection before making the request
      final bool isNeedToWait = options.extra['isNeedToWait'] ?? true;
      if (isNeedToWait) {
        final completer = Completer<void>();
        ConnectionChecker().connectionStream.listen((isConnected) {
          if (isConnected) {
            if (!completer.isCompleted) {
              completer.complete(); // Resolve completer when connection is restored
            }
          }
        });
        final isConnected = await ConnectionChecker.checkConnectivity();
        // Wait for connection to be restored if there's no internet
        if (!isConnected) {
          await completer.future; // Wait until the completer is completed
        }
        handler.next(options);
      } else {
        handler.next(options);
      }
    }),
    onResponse: (e, handler) {
      handler.next(e);
    },
    onError: (e, handler) async {
      handler.next(e);
    },
  );
  // get method
  Future<Response?> get({
    required String url,
    CancelToken? cancelToken,
    int timeout = 60,
    bool? isNeedToWait,
    bool updateToken = false,
  }) {
    return apiCore.get(
      url: url,
      cancelToken: cancelToken,
      timeout: timeout,
      isNeedToWait: isNeedToWait,
    );
  }

  // post method
  Future<Response?> post({
    required String url,
    required Map<String, dynamic> data,
    CancelToken? cancelToken,
    Map<String, String?>? additionalHeaders,
    bool? isNeedToWait,
  }) {
    return apiCore.post(
        url: url,
        data: jsonEncode(data),
        cancelToken: cancelToken,
        additionalHeaders: additionalHeaders,
        isNeedToWait: isNeedToWait,
      );
  }

  Future<Response?> download({
    required String urlPath,
    required String savePath,
    Options? options,
  }) {
    return apiCore.download(
      urlPath: urlPath,
      savePath: savePath,
      options: options,
    );
  }
}
