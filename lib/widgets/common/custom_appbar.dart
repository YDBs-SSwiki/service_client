// lib/widgets/common/custom_appbar.dart
import 'package:flutter/material.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final bool isHome;
  final ValueChanged<String> onSearchSubmitted;
  final ValueChanged<String>? onSearchChanged; // ← 추가

  final Widget? leading;
  final List<Widget>? actions;

  const CustomAppBar({
    Key? key,
    required this.isHome,
    required this.onSearchSubmitted,
    this.onSearchChanged, // ← 추가
    this.leading,
    this.actions,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 60);

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> {
  final TextEditingController _searchCtrl = TextEditingController();

  void _onChanged(String keyword) {
    // onSearchChanged가 있다면 호출
    if (widget.onSearchChanged != null) {
      widget.onSearchChanged!(keyword);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: widget.leading,
      title: GestureDetector(
        onTap: () {
          // 홈이 아닐 때 로고 클릭 → 홈으로
          if (!widget.isHome) {
            Navigator.pushReplacementNamed(context, '/');
          }
        },
        child: const Text('성심위키', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      actions: widget.actions,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          height: 60,
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: _searchCtrl,
            decoration: const InputDecoration(
              hintText: '검색...',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: _onChanged,                   // 실시간 입력 감지
            onSubmitted: widget.onSearchSubmitted,    // 엔터 시
          ),
        ),
      ),
    );
  }
}
