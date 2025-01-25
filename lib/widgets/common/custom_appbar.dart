// lib/widgets/common/custom_appbar.dart

import 'package:flutter/material.dart';

// 실시간 검색 콜백 추가
typedef SearchChangedCallback = void Function(String);

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final bool isHome;
  final ValueChanged<String> onSearchSubmitted;
  final Widget? leading;
  final List<Widget>? actions;

  // 실시간 검색용
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
  State<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> {
  final TextEditingController _searchCtrl = TextEditingController();

  // 실시간 onChange
  void _onChange(String val) {
    // HomeScreen 등에 직접 콜백을 주입받을 수도 있지만,
    // 구조 단순화 위해, onSubmitted만 사용 or pass new callback...
    // 여기서는 그냥 do nothing. (실제 홈스크린에서 controller 가져갈 수도)
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFFB57A45),
      leading: widget.leading,
      centerTitle: false,
      title: GestureDetector(
        onTap: () {
          if(!widget.isHome){
            Navigator.pushNamed(context, '/');
          }
        },
        child: const Text(
          '성심위키',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      actions: widget.actions,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          height:60,
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal:16, vertical:8),
          child: TextField(
            controller: _searchCtrl,
            decoration: const InputDecoration(
              hintText:'검색...',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: _onChange, // 실시간
            onSubmitted: widget.onSearchSubmitted,
          ),
        ),
      ),
    );
  }
}
