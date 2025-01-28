// lib/services/auth_service.dart

import 'dart:developer';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:dio/dio.dart';
import 'api_client.dart';

class AuthService {
  static bool isLoggedIn = false;
  static int? currentUserId;
  static String? currentUsername;

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: '173809341653-3au1opfo1gmfv684j3sqr920515qbtat.apps.googleusercontent.com',
  );

  static Future<bool> googleLogin() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // 사용자 선택 취소
        return false;
      }
      final auth = await googleUser.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        log('No idToken from googleAuth');
        return false;
      }
      final displayName = googleUser.displayName ?? '';

      // 1) 서버에 /auth/google
      final body = {
        'idToken': idToken,
        'username': displayName,
      };
      final res = await ApiClient.dio.post(
        '/auth/google',
        data: body,
      );
      if (res.statusCode == 200) {
        final data = res.data as Map<String, dynamic>;
        final userId = data['userId'] as int?;
        final uname = data['username'] as String?;
        if (userId != null) {
          isLoggedIn = true;
          currentUserId = userId;
          currentUsername = uname ?? '';
          return true;
        }
      }
      return false;
    } catch (e) {
      log('googleLogin error: $e');
      return false;
    }
  }

  static Future<void> logout() async {
    try {
      await ApiClient.dio.post('/auth/logout');
    } catch (e) {
      log('server logout error: $e');
    }
    try {
      final googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
    } catch (e) {
      log('googleSignOut error: $e');
    }
    // 세션 쿠키 제거
    ApiClient.sessionCookie = null;
    isLoggedIn = false;
    currentUserId = null;
    currentUsername = null;
  }
}
