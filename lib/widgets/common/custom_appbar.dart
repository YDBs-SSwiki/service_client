// lib/widgets/common/custom_appbar.dart
import 'package:flutter/material.dart';

/// AppBar:
/// - 우측에 "성심위키" 텍스트, 탭 시 (if not home) -> home
/// - 아래쪽에 검색창
/// - leading/actions는 optional
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isHome; // 홈인지 아닌지
  final void Function(String) onSearchSubmitted;
  final Widget? leading;
  final List<Widget>? actions;

  const CustomAppBar({
    Key? key,
    required this.isHome,
    required this.onSearchSubmitted,
    this.leading,
    this.actions,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 60);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFFB57A45),
      centerTitle: false,
      leading: leading,
      title: GestureDetector(
        onTap: () {
          if(!isHome){
            // Navigator.pushNamed(context, '/') or popUntil?
            Navigator.pushNamed(context, '/');
          }
        },
        child: const Text(
          '성심위키',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      actions: actions,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          color: Colors.white,
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal:16, vertical:8),
          child: TextField(
            decoration: const InputDecoration(
              hintText:'검색...',
              border: OutlineInputBorder(),
            ),
            onSubmitted: onSearchSubmitted,
          ),
        ),
      ),
    );
  }
}
