// lib/services/auth_service.dart

import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'api_client.dart';

class AuthService {
  static bool isLoggedIn = false;
  static int? currentUserId;
  static String? currentUsername;

  // 구글 로그인 플러그인
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    // 웹 환경에서 clientId 설정 가능
    clientId: '173809341653-3au1opfo1gmfv684j3sqr920515qbtat.apps.googleusercontent.com',
    //
    // scopes: ['email'],
  );

  /// 구글 로그인 시도
  /// - 웹/모바일 동시 지원
  static Future<bool> googleLogin() async {
    try {
      // 1) 사용자에게 구글 계정 선택 UI
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // 로그인 취소
        return false;
      }

      // 2) 구글 인증 정보에서 idToken 획득
      final auth = await googleUser.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        log('No idToken from googleAuth');
        return false;
      }

      final displayName = googleUser.displayName ?? '';
      // 3) idToken + username => 서버 /auth/google 전송
      final ok = await _sendGoogleLoginToServer(idToken, displayName);
      return ok;
    } catch (e) {
      log('googleLogin error: $e');
      return false;
    }
  }

  /// 서버에 POST => /auth/google
  static Future<bool> _sendGoogleLoginToServer(String idToken, String username) async {
    try {
      final body = {
        'idToken': idToken,
        'username': username,
      };
      final res = await ApiClient.dio.post(
        '/auth/google',
        data: body,
        // 세션 생성 위해 withCredentials
        options: Options(
          extra: {"withCredentials": true},
        ),
      );
      // 서버가 200 OK + JSON = { userId, username, role, ... }
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
      log('sendGoogleLoginToServer error: $e');
      return false;
    }
  }

  /// 로그아웃
  static Future<void> logout() async {
    try {
      // 1) 서버 /auth/logout
      await ApiClient.dio.post('/auth/logout',
          options: Options(
            extra: {"withCredentials": true},
          ));
    } catch (e) {
      log('server logout error: $e');
    }
    // 2) 구글 로그아웃
    try {
      final googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
    } catch (e) {
      log('googleSignOut error: $e');
    }
    // 3) 상태 초기화
    isLoggedIn = false;
    currentUserId = null;
    currentUsername = null;
  }
}
