// lib/services/auth_service.dart

class AuthService {
  static bool isLoggedIn = false;
  static int? currentUserId;

  /// (실제 서버 호출 없이) 강제로 로그인 상태로 만듦
  ///  - 예: userId=50으로 로그인
  static Future<bool> googleLoginDummy(String idToken, String username) async {
    // 여기선 idToken, username 무시하고 바로 로그인 처리
    isLoggedIn = true;
    currentUserId = 50;
    return true;
  }

  /// (실제 서버 호출 없이) 로그아웃
  static Future<void> logout() async {
    // 서버로 /auth/logout 안 날림
    isLoggedIn = false;
    currentUserId = null;
  }

  /// 혹은 그냥 함수 하나로 간단 처리 (버튼 누르면 즉시 로그인)
  static void loginDummy([int uid = 50]) {
    isLoggedIn = true;
    currentUserId = uid;
  }
}
