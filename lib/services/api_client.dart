// lib/services/api_client.dart
import 'package:dio/dio.dart';

class ApiClient {
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: 'https://physically-legible-bengal.ngrok-free.app', // 실제 서버 주소
      connectTimeout: const Duration(seconds:5),
      receiveTimeout: const Duration(seconds:5),
      // ngrok warning skip (유료플랜X시 동작 안할 수도)
      headers: {
        'ngrok-skip-browser-warning': '69420',
      },
    ),
  );
}
