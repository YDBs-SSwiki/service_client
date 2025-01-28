// lib/main.dart

import 'package:flutter/material.dart';
import 'navigation/navigation_wrapper.dart';
import 'screens/search_result_screen.dart';
import 'screens/bread_detail_screen.dart';
import 'screens/mypage_screen.dart';
import 'screens/settings_screen.dart';
import 'services/api_client.dart';

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;

  void _setDarkMode(bool val) {
    setState(() => _isDarkMode = val);
  }

  @override
  void initState() {
    super.initState();
    // 1) 앱 시작 시 1회, Dio 인터셉터 초기화
    ApiClient.initInterceptors();
  }

  @override
  Widget build(BuildContext context) {
    final themeLight = ThemeData(
      brightness: Brightness.light,
      primarySwatch: Colors.brown,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFB57A45),
        foregroundColor: Color(0xFFF7EFE6),
      ),
    );
    final themeDark = ThemeData(
      brightness: Brightness.dark,
      primarySwatch: Colors.brown,
      scaffoldBackgroundColor: const Color(0xFF4E3A2A),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF382E1C),
        foregroundColor: Color(0xFFF7EFE6),
      ),
    );

    return MaterialApp(
      title: 'SungsimWiki',
      theme: _isDarkMode ? themeDark : themeLight,
      initialRoute: '/',
      routes: {
        '/': (ctx) => NavigationWrapper(
          isDarkMode: _isDarkMode,
          onToggleDarkMode: _setDarkMode,
        ),
        '/searchResult': (ctx) {
          final arg = ModalRoute.of(ctx)?.settings.arguments as String? ?? '';
          return SearchResultScreen(
            keyword: arg,
            isDarkMode: _isDarkMode,
            onToggleDarkMode: _setDarkMode,
          );
        },
        '/breadDetail': (ctx) {
          final arg = ModalRoute.of(ctx)?.settings.arguments as int? ?? 0;
          return BreadDetailScreen(
            breadId: arg,
            isDarkMode: _isDarkMode,
            onToggleDarkMode: _setDarkMode,
          );
        },
        '/mypage': (ctx) => MyPageScreen(
          isDarkMode: _isDarkMode,
          onToggleDarkMode: _setDarkMode,
        ),
        '/settings': (ctx) => SettingsScreen(
          isDarkMode: _isDarkMode,
          onToggleDarkMode: _setDarkMode,
        ),
      },
    );
  }
}

void main() {
  runApp(const MyApp());
}
