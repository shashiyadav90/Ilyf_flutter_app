
import 'package:dio/dio.dart';

class ApiConfig {
  static const String baseUrl =
      'https://de5sbhhkqfvoi.cloudfront.net/api';

  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Accept': 'application/json',
      },
    ),
  );
}
