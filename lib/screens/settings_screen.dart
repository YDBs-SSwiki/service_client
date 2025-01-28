// lib/screens/settings_screen.dart

import 'package:flutter/material.dart';
import '../widgets/common/custom_appbar.dart';
import '../services/bread_service.dart';
import '../models/bread.dart';

class SettingsScreen extends StatefulWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onToggleDarkMode;

  const SettingsScreen({
    Key? key,
    required this.isDarkMode,
    required this.onToggleDarkMode,
  }) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final List<double> _fontScales = [0.5, 0.75, 1.0, 1.25, 1.5];
  double _currentScale = 1.0;

  // 자동완성
  String _searchKeyword = '';
  List<Bread> _suggestionBreads = [];

  // (1) 실시간 입력 -> 자동완성
  Future<void> _onSearchTextChanged(String keyword) async {
    setState(() => _searchKeyword = keyword.trim());
    if (_searchKeyword.isEmpty) {
      setState(() => _suggestionBreads = []);
      return;
    }
    final results = await BreadService.searchBreads(_searchKeyword);
    setState(() => _suggestionBreads = results);
  }

  // (2) 엔터 -> 검색 결과 페이지 이동
  void _onSearch(String keyword) {
    Navigator.pushReplacementNamed(context, '/searchResult', arguments: keyword);
  }

  void _pickFontScale() async {
    final val = await showDialog<double>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('글자 크기'),
        children: [
          for (final s in _fontScales)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, s),
              child: Text(
                '${(s * 100).toInt()}% 크기',
                style: TextStyle(fontSize: 14 * s),
              ),
            )
        ],
      ),
    );
    if (val != null) {
      setState(() => _currentScale = val);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        isHome: false,
        onSearchSubmitted: _onSearch,
        onSearchChanged: _onSearchTextChanged, // 자동완성
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // (자동완성) 검색어가 있을 때만 표시
            if (_searchKeyword.isNotEmpty) _buildSuggestions(),

            Row(
              children: [
                const Text('테마: '),
                ElevatedButton(
                  onPressed: () => widget.onToggleDarkMode(false),
                  child: const Text('라이트'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => widget.onToggleDarkMode(true),
                  child: const Text('다크'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('글자 크기: '),
                ElevatedButton(
                  onPressed: _pickFontScale,
                  child: Text('${(_currentScale * 100).toInt()}%'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '예시 텍스트.\n현재 ${(_currentScale * 100).toInt()}%.',
              style: TextStyle(fontSize: 14 * _currentScale),
            ),
          ],
        ),
      ),
    );
  }

  /// 자동완성 위젯
  Widget _buildSuggestions() {
    // 검색어가 있는데 결과가 비어있으면 "검색 결과 없음"
    if (_suggestionBreads.isEmpty) {
      return Container(
        height: 40,
        color: Colors.orange[50],
        child: const Center(child: Text('검색 결과가 없습니다')),
      );
    }

    // 검색 결과가 있으면 목록
    return Container(
      height: 100,
      color: Colors.orange[50],
      child: ListView.builder(
        itemCount: _suggestionBreads.length,
        itemBuilder: (ctx, i) {
          final bread = _suggestionBreads[i];
          return InkWell(
            onTap: () {
              // 바로 빵 상세로 이동
              Navigator.pushReplacementNamed(context, '/breadDetail', arguments: bread.breadId);
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(bread.name, style: const TextStyle(color: Colors.blue)),
            ),
          );
        },
      ),
    );
  }
}
