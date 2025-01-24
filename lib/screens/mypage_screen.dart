// lib/screens/mypage_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/common/custom_appbar.dart';

class MyPageScreen extends StatefulWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onToggleDarkMode;

  const MyPageScreen({
    Key? key,
    required this.isDarkMode,
    required this.onToggleDarkMode,
  }) : super(key: key);

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        isHome: false,
        onSearchSubmitted: (val) {
          Navigator.pushNamed(context, '/searchResult', arguments: val);
        },
        actions: [
          ElevatedButton.icon(
            onPressed: _onLogout,
            icon: const Icon(Icons.logout),
            label: const Text('로그아웃'),
          ),
        ],
      ),
      body: const Center(child: Text('마이페이지 내용 예시')),
    );
  }

  void _onLogout() {
    // 서버에 /auth/logout 안 보냄. 단순 isLoggedIn=false
    AuthService.logout();
    // 홈으로 이동(로그아웃 상태)
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }
}
