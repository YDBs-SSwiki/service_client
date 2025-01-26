// lib/navigation/navigation_wrapper.dart

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/popups/login_sheet.dart';
import '../widgets/common/custom_navbar.dart';
import '../screens/home_screen.dart';
import '../screens/mypage_screen.dart';
import '../screens/settings_screen.dart';

class NavigationWrapper extends StatefulWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onToggleDarkMode;

  const NavigationWrapper({
    Key? key,
    required this.isDarkMode,
    required this.onToggleDarkMode,
  }) : super(key: key);

  @override
  State<NavigationWrapper> createState() => _NavigationWrapperState();
}

class _NavigationWrapperState extends State<NavigationWrapper> {
  int _currentIndex = 0;

  bool get _isLoggedIn => AuthService.isLoggedIn;

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomeScreen(
        isDarkMode: widget.isDarkMode,
        onToggleDarkMode: widget.onToggleDarkMode,
      ),
      MyPageScreen(
        isDarkMode: widget.isDarkMode,
        onToggleDarkMode: widget.onToggleDarkMode,
      ),
      SettingsScreen(
        isDarkMode: widget.isDarkMode,
        onToggleDarkMode: widget.onToggleDarkMode,
      ),
    ];
  }

  void _onTapNav(int newIndex) async {
    if (newIndex == _currentIndex) return;

    // 로그인 안 돼있고 탭=1(마이페이지) => 로그인 팝업
    if (newIndex == 1 && !_isLoggedIn) {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => const LoginSheet(),
      );
      if (AuthService.isLoggedIn) {
        setState(() => _currentIndex = 1);
      }
      return;
    }

    setState(() => _currentIndex = newIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: CustomNavBar(
        currentIndex: _currentIndex,
        isLoggedIn: _isLoggedIn,
        onTap: _onTapNav,
      ),
    );
  }
}
