import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:talker_dio_logger/talker_dio_logger.dart';

import '../main.dart';

class HttpService {
  static const kTimeOutDurationInSeconds = 30;
  static Future<Response> get<T>(String url) async {
    final dio = Dio();
    dio.interceptors.add(TalkerDioLogger(talker: talker!));
    try {
      return await dio
          .get<T>(
        url,
        options: Options(
          responseType: ResponseType.plain,
        ),
      )
          .timeout(
        const Duration(seconds: kTimeOutDurationInSeconds),
        onTimeout: () {
          // Time has run out, do what you wanted to do.
          return Response(
            requestOptions: RequestOptions(),
            statusCode: 408,
            statusMessage: 'Request Timeout Expired',
          ); // Request Timeout response status code
        },
      );
    } on DioException catch (e) {
      debugPrint('#########################');
      debugPrint('Entering the Dio Exception');
      if (kDebugMode) print(e);
      debugPrint('Exiting the Dio Exception');
      debugPrint('#########################');
      rethrow;
    }
  }
}
