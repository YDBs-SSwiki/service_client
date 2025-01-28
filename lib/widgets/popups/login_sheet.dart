// lib/widgets/popups/login_sheet.dart
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

/// 로그인 BottomSheet
class LoginSheet extends StatefulWidget {
  const LoginSheet({Key? key}) : super(key: key);

  @override
  State<LoginSheet> createState() => _LoginSheetState();
}

class _LoginSheetState extends State<LoginSheet> {
  Future<void> _onGoogleLogin() async {
    final ok = await AuthService.googleLogin();
    if (ok) {
      Navigator.pop(context, true); // 로그인 성공 => 닫고 true
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('구글 로그인 실패')));
    }
  }

  Future<void> _onLogout() async {
    await AuthService.logout();
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('로그아웃 완료')));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            const Text(
              '구글 로그인/회원가입',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: _onGoogleLogin,
              child: const Text('구글 로그인'),
            ),
            const SizedBox(height: 8),

            // 만약 로그아웃 버튼을 테스트하고 싶다면:
            ElevatedButton(
              onPressed: _onLogout,
              child: const Text('로그아웃 (테스트)'),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
