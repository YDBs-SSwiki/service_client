// lib/widgets/common/custom_navbar.dart

import 'package:flutter/material.dart';

class CustomNavBar extends StatelessWidget {
  final int currentIndex;
  final bool isLoggedIn;
  final ValueChanged<int> onTap;

  const CustomNavBar({
    Key? key,
    required this.currentIndex,
    required this.isLoggedIn,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (idx){
        if(idx==currentIndex) return;
        onTap(idx);
      },
      backgroundColor: const Color(0xFF382E1C),
      selectedItemColor: const Color(0xFFF7EFE6),
      unselectedItemColor: const Color(0xFFCC9C66),
      type: BottomNavigationBarType.fixed,
      items: isLoggedIn
          ? const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label:'홈'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label:'마이페이지'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label:'설정'),
      ]
          : const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label:'홈'),
        BottomNavigationBarItem(icon: Icon(Icons.login), label:'로그인'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label:'설정'),
      ],
    );
  }
}
