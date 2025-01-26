// lib/services/api_client.dart
import 'package:dio/dio.dart';

class ApiClient {
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: 'https://physically-legible-bengal.ngrok-free.app', // 실제 서버 주소
      connectTimeout: const Duration(seconds:5),
      receiveTimeout: const Duration(seconds:5),
      // ngrok warning skip
      headers: {
        'ngrok-skip-browser-warning': '69420',
      },
    ),
  );
}
