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

  @override
  void initState(){
    super.initState();
    _doSearch();
  }

  Future<void> _doSearch() async {
    final res = await BreadService.searchBreads(widget.keyword);
    setState(() {
      _results = res;
      _loading = false;
    });
  }

  void _onSearch(String val){
    // 페이지 1개만 유지 => pushReplacement
    Navigator.pushReplacementNamed(context, '/searchResult', arguments:val);
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: CustomAppBar(
        isHome:false,
        onSearchSubmitted:_onSearch,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:[
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '검색 결과 : "${widget.keyword}"',
              style: const TextStyle(fontSize:18, fontWeight:FontWeight.bold),
            ),
          ),
          Expanded(
            child: _results.isEmpty
                ? const Center(child:Text('(검색 결과가 없습니다)'))
                : ListView.builder(
              itemCount:_results.length,
              itemBuilder:(ctx,i){
                final b = _results[i];
                final d = b.detail??'';
                final shortDetail = d.length>50 ? (d.substring(0,50)+'...') : d;
                return ListTile(
                  leading: (b.imageUrl!=null)
                      ? Image.network(b.imageUrl!, width:50, fit:BoxFit.cover)
                      : const Icon(Icons.bakery_dining),
                  title: Text(b.name),
                  subtitle: Text(shortDetail),
                  onTap: (){
                    // 페이지 1개만 유지 => pushReplacement
                    Navigator.pushReplacementNamed(context, '/breadDetail', arguments:b.breadId);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
