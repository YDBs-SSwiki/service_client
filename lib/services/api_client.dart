// lib/services/api_client.dart
import 'package:dio/dio.dart';

class ApiClient {
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: 'https://physically-legible-bengal.ngrok-free.app',
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),

      // ★ 여기 헤더 추가!
      headers: {
        'ngrok-skip-browser-warning': '69420', // 아무 값이면 됨
      },
    ),
  );
}
