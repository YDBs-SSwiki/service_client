// lib/services/auth_service.dart
import 'dart:developer';
import 'api_client.dart';

class AuthService {
  static bool isLoggedIn = false;
  static int? currentUserId;

  // 가짜 구글 로그인
  static Future<bool> googleLogin(String idToken, String username) async {
    log('googleLogin dummy: $idToken, $username');
    // 실제라면: final res = await ApiClient.dio.post('/auth/google', data:{...})
    // parse userId, ...
    isLoggedIn = true;
    currentUserId = 50; // 임시
    return true;
  }

  // 로그아웃
  static Future<void> logout() async {
    try {
      // real: await ApiClient.dio.post('/auth/logout');
      isLoggedIn=false;
      currentUserId=null;
    } catch(e) {
      log('logout error: $e');
    }
  }
}
