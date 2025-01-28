// lib/screens/search_result_screen.dart

import 'package:flutter/material.dart';
import '../services/bread_service.dart';
import '../models/bread.dart';
import '../widgets/common/custom_appbar.dart';

/// 검색 결과 페이지
class SearchResultScreen extends StatefulWidget {
  final String keyword;
  final bool isDarkMode;
  final ValueChanged<bool> onToggleDarkMode;

  const SearchResultScreen({
    Key? key,
    required this.keyword,
    required this.isDarkMode,
    required this.onToggleDarkMode,
  }) : super(key: key);

  @override
  State<SearchResultScreen> createState() => _SearchResultScreenState();
}

class _SearchResultScreenState extends State<SearchResultScreen> {
  bool _loading = true;
  List<Bread> _results = [];

  // 자동완성
  String _searchKeyword = '';
  List<Bread> _suggestionBreads = [];

  @override
  void initState() {
    super.initState();
    // 최초엔 widget.keyword로 검색
    _doSearch(widget.keyword);
  }

  /// 실제 검색 API
  Future<void> _doSearch(String kw) async {
    setState(() => _loading = true);
    final res = await BreadService.searchBreads(kw);
    setState(() {
      _results = res;
      _loading = false;
    });
  }

  /// (1) 입력 바뀔 때 -> 자동완성
  Future<void> _onSearchTextChanged(String keyword) async {
    setState(() => _searchKeyword = keyword.trim());
    if (_searchKeyword.isEmpty) {
      setState(() => _suggestionBreads = []);
      return;
    }
    final results = await BreadService.searchBreads(_searchKeyword);
    setState(() => _suggestionBreads = results);
  }

  /// (2) 엔터 or 자동완성 항목 클릭 시 -> _doSearch (검색 결과)
  void _onSearch(String val) {
    _doSearch(val);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        isHome: false,
        onSearchSubmitted: _onSearch,
        onSearchChanged: _onSearchTextChanged,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 자동완성
          if (_searchKeyword.isNotEmpty) _buildSuggestions(),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '검색 결과 (${_results.length}개)',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: _results.isEmpty
                ? const Center(child: Text('(검색 결과가 없습니다)'))
                : ListView.builder(
              itemCount: _results.length,
              itemBuilder: (ctx, i) {
                final b = _results[i];
                final d = b.detail ?? '';
                final shortDetail = (d.length > 50) ? '${d.substring(0, 50)}...' : d;
                return ListTile(
                  leading: (b.imageUrl != null)
                      ? Image.network(b.imageUrl!, width: 50, fit: BoxFit.cover)
                      : const Icon(Icons.bakery_dining),
                  title: Text(b.name),
                  subtitle: Text(shortDetail),
                  onTap: () {
                    // 페이지 1개만 유지 => pushReplacement
                    Navigator.pushReplacementNamed(context, '/breadDetail', arguments: b.breadId);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    if (_suggestionBreads.isEmpty) {
      return Container(
        height: 40,
        color: Colors.orange[50],
        child: const Center(child: Text('검색 결과가 없습니다')),
      );
    }
    return Container(
      height: 100,
      color: Colors.orange[50],
      child: ListView.builder(
        itemCount: _suggestionBreads.length,
        itemBuilder: (ctx, i) {
          final bread = _suggestionBreads[i];
          return InkWell(
            onTap: () {
              // 자동완성 -> 빵 상세로
              Navigator.pushReplacementNamed(context, '/breadDetail', arguments: bread.breadId);
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Text(bread.name, style: const TextStyle(color: Colors.blue)),
            ),
          );
        },
      ),
    );
  }
}
