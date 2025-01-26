// lib/widgets/common/custom_appbar.dart

import 'package:flutter/material.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final bool isHome;
  final ValueChanged<String> onSearchSubmitted;
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
  State<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> {
  final TextEditingController _searchCtrl = TextEditingController();

  // 필요 시 onChanged를 별도 콜백으로 넘길 수 있음
  void _onSearchChanged(String val) {
    // Optional
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFFB57A45),
      leading: widget.leading,
      centerTitle: false,
      title: GestureDetector(
        onTap: () {
          // 홈화면이 아니면 홈으로
          if(!widget.isHome){
            Navigator.pushReplacementNamed(context, '/');
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
            onChanged: _onSearchChanged,
            onSubmitted: widget.onSearchSubmitted,
          ),
        ),
      ),
    );
  }
}
