// lib/screens/search_result_screen.dart
import 'package:flutter/material.dart';
import '../services/bread_service.dart';
import '../models/bread.dart';
import '../widgets/common/custom_appbar.dart';
import 'bread_detail_screen.dart';

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
  bool _loading=true;
  List<Bread> _results=[];

  @override
  void initState(){
    super.initState();
    _doSearch();
  }

  Future<void> _doSearch() async {
    final res = await BreadService.searchBreads(widget.keyword);
    setState(() {
      _results=res;
      _loading=false;
    });
  }

  void _onSearchSubmitted(String val){
    Navigator.pushReplacementNamed(context, '/searchResult', arguments: val);
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: CustomAppBar(
        isHome:false,
        onSearchSubmitted:_onSearchSubmitted,
      ),
      body: _loading
          ? const Center(child:CircularProgressIndicator())
          : ListView.builder(
        itemCount:_results.length,
        itemBuilder:(ctx,i){
          final b = _results[i];
          return ListTile(
            leading: b.imageUrl!=null
                ? Image.network(b.imageUrl!, width:50, fit:BoxFit.cover)
                : const Icon(Icons.bakery_dining),
            title: Text(b.name),
            subtitle: Text(b.detail),
            onTap: (){
              Navigator.pushNamed(context, '/breadDetail', arguments:b.breadId);
            },
          );
        },
      ),
    );
  }
}
