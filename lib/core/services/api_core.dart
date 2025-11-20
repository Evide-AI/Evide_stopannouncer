import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:evide_stop_announcer_app/core/app_imports.dart';

class ApiCore {
  final List<InterceptorsWrapper> interceptors;
  final Dio dio = Dio();

  ApiCore({required this.interceptors}) {
    dio.interceptors.addAll(interceptors);
  }

  // get method
  Future<Response?> get({
    required String url,
    Map<String, String?>? additionalHeaders,
    CancelToken? cancelToken,
    int timeout = 120,
    bool? isNeedToWait,
  }) async {
    try {
      Response response = await dio.get(
        url,
        cancelToken: cancelToken,
        options: Options(
          extra: {
            "isNeedToWait": isNeedToWait,
          },
          headers: {
          }..addAll(additionalHeaders??{})..removeWhere((key, value) => value==null),
        )
      ).timeout(Duration(seconds: timeout));
      return response;
    } on DioException catch (e) {
      debugPrint("DioException From Get: ${e.toString()}");
      return null;
    }
  }

  // post method
  Future<Response?> post({
    required String url,
    required String data,
    Map<String, String?>? additionalHeaders,
    CancelToken? cancelToken,
    void Function(int, int)? onSendProgress,
    void Function(int, int)? onReceiveProgress,
    int timeout = 120,
    bool? isNeedToWait,
  }) async {
    try {

      Map<String, dynamic> finalBody;
      finalBody = jsonDecode(data);
      Response response = await dio.post(
        url,
        cancelToken: cancelToken,
        data: jsonEncode(finalBody),
        options: Options(
          extra: {
            "isNeedToWait": isNeedToWait,
          },
          headers: {
            // if(AppBloc.instance.isLoggedIn) "Authorization" : AppBloc.instance.token,
          }..addAll(additionalHeaders??{})..removeWhere((key, value) => value==null),
        ),
        onReceiveProgress: onReceiveProgress,
        onSendProgress: onSendProgress,
      ).timeout(Duration(seconds: timeout));
      return response;
    } on DioException catch (e) {
      debugPrint("DioException From Post: ${e.toString()}");
      return null;
    }
  }

  Future<Response?> download({
    required String urlPath,
    required String savePath,
    Options? options,
  }) async {
    try {

      Response response = await dio.download(
        urlPath,
        savePath,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      debugPrint("DioException From Post: ${e.toString()}");
      return null;
    }
  }
}
