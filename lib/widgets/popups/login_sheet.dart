// lib/widgets/popups/login_sheet.dart
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

/// 로그인/회원가입 버튼 누르면 바로 로그인 상태로 전환(서버 호출 X)
class LoginSheet extends StatefulWidget {
  const LoginSheet({Key? key}) : super(key: key);

  @override
  State<LoginSheet> createState() => _LoginSheetState();
}

class _LoginSheetState extends State<LoginSheet> {
  void _onLogin() {
    // 서버 호출 없이 즉시 로그인
    AuthService.isLoggedIn = true;
    AuthService.currentUserId = 50; // 임의의 유저 ID
    Navigator.pop(context, true);
  }

  void _onSignup() {
    // 회원가입도 마찬가지로 즉시 로그인
    AuthService.isLoggedIn = true;
    AuthService.currentUserId = 51; // 예: 다른 ID
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // 키보드 올라오면 여유공간
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            const Text('로그인 / 회원가입', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _onLogin,
              child: const Text('구글 로그인'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _onSignup,
              child: const Text('회원가입'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
