// lib/main.dart
import 'package:flutter/material.dart';
import 'navigation/navigation_wrapper.dart';
import 'screens/search_result_screen.dart';
import 'screens/bread_detail_screen.dart';
import 'screens/mypage_screen.dart';
import 'screens/settings_screen.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;

  void _toggleDarkMode(bool val) {
    setState(() => _isDarkMode = val);
  }

  // 공통 버튼 스타일
  ButtonStyle get _buttonStyle => ButtonStyle(
    backgroundColor: MaterialStateProperty.all(const Color(0xFFF7EFE6)),
    foregroundColor: MaterialStateProperty.all(const Color(0xFF382E1C)),
  );

  @override
  Widget build(BuildContext context) {
    // 라이트 테마
    final themeLight = ThemeData(
      brightness: Brightness.light,
      primarySwatch: Colors.brown,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFB57A45),
        foregroundColor: Color(0xFFF7EFE6),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: _buttonStyle),
      textButtonTheme: TextButtonThemeData(style: _buttonStyle),
      outlinedButtonTheme: OutlinedButtonThemeData(style: _buttonStyle),
    );

    // 다크 테마(갈색 톤)
    final themeDark = ThemeData(
      brightness: Brightness.dark,
      primarySwatch: Colors.brown,
      scaffoldBackgroundColor: const Color(0xFF4E3A2A),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF382E1C),
        foregroundColor: Color(0xFFF7EFE6),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: _buttonStyle),
      textButtonTheme: TextButtonThemeData(style: _buttonStyle),
      outlinedButtonTheme: OutlinedButtonThemeData(style: _buttonStyle),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFB57A45),
        onPrimary: Color(0xFFF7EFE6),
        secondary: Color(0xFF382E1C),
        onSecondary: Color(0xFFF7EFE6),
        background: Color(0xFF4E3A2A),
        onBackground: Color(0xFFF7EFE6),
        surface: Color(0xFF4E3A2A),
        onSurface: Color(0xFFF7EFE6),
      ),
    );

    return MaterialApp(
      title: 'SungsimWiki',
      theme: _isDarkMode ? themeDark : themeLight,
      initialRoute: '/',
      routes: {
        '/': (ctx) => NavigationWrapper(
          isDarkMode: _isDarkMode,
          onToggleDarkMode: _toggleDarkMode,
        ),
        '/searchResult': (ctx) {
          final arg = ModalRoute.of(ctx)?.settings.arguments as String? ?? '';
          return SearchResultScreen(
            keyword: arg,
            isDarkMode: _isDarkMode,
            onToggleDarkMode: _toggleDarkMode,
          );
        },
        '/breadDetail': (ctx) {
          final arg = ModalRoute.of(ctx)?.settings.arguments as int? ?? 0;
          return BreadDetailScreen(
            breadId: arg,
            isDarkMode: _isDarkMode,
            onToggleDarkMode: _toggleDarkMode,
          );
        },
        '/mypage': (ctx) => MyPageScreen(
          isDarkMode: _isDarkMode,
          onToggleDarkMode: _toggleDarkMode,
        ),
        '/settings': (ctx) => SettingsScreen(
          isDarkMode: _isDarkMode,
          onToggleDarkMode: _toggleDarkMode,
        ),
      },
    );
  }
}

void main() {
  runApp(const MyApp());
}
