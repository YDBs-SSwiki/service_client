// lib/services/auth_service.dart
import 'dart:developer';
import 'package:dio/dio.dart';
import 'api_client.dart';
import 'user_service.dart';
import '../models/user.dart';

class AuthService {
  static bool isLoggedIn = false;
  static int? currentUserId;
  static UserInfo? currentUserInfo;

  /// 구글 로그인 (Dummy)
  /// 실제로는 /auth/google
  static Future<bool> googleLogin(String idToken, String username) async {
    log('googleLogin dummy: $idToken, $username');
    try {
      // 실제 API: final res = await ApiClient.dio.post('/auth/google', data:{...})
      // parse userId=?
      isLoggedIn = true;
      currentUserId = 1;

      final info = await UserService.getUserInfo(1);
      currentUserInfo = info;
      return true;
    } catch(e){
      log('googleLogin error: $e');
      return false;
    }
  }

  /// 로그아웃
  static Future<void> logout() async {
    try {
      // real: await ApiClient.dio.post('/auth/logout');
      isLoggedIn=false;
      currentUserId=null;
      currentUserInfo=null;
    } catch(e){
      log('logout error: $e');
    }
  }
}
