// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import '../models/bread.dart';
import '../services/bread_service.dart';
import '../widgets/common/custom_appbar.dart';
import 'bread_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onToggleDarkMode;

  const HomeScreen({
    Key? key,
    required this.isDarkMode,
    required this.onToggleDarkMode,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

/// 홈화면:
/// - AppBar(성심위키+검색)
/// - 3열 빵 목록
/// - 정렬/필터
class _HomeScreenState extends State<HomeScreen> {
  bool _loading=true;
  List<Bread> _breads=[];
  String sortKey='조회순';
  List<String> storeFilter=[];

  @override
  void initState(){
    super.initState();
    _initFetch();
  }

  Future<void> _initFetch() async {
    await BreadService.fetchAllBreads();
    setState(() {
      _breads = BreadService.allBreadsCache;
      _loading=false;
    });
  }

  void _pickSort(){}
  void _pickStoreFilter(){}

  void _onSearch(String val){
    // pushNamed('/searchResult', arguments: val)
    Navigator.pushNamed(context, '/searchResult', arguments: val);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        isHome:true,
        onSearchSubmitted: _onSearch,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children:[
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children:[
              TextButton(
                onPressed:_pickSort,
                child: Text('정렬: $sortKey'),
              ),
              TextButton(
                onPressed:_pickStoreFilter,
                child: const Text('지점 필터'),
              )
            ],
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount:3,
                mainAxisSpacing:8,
                crossAxisSpacing:8,
              ),
              itemCount:_breads.length,
              itemBuilder:(ctx,i){
                final b = _breads[i];
                return InkWell(
                  onTap: (){
                    Navigator.pushNamed(context, '/breadDetail', arguments: b.breadId);
                  },
                  child: Column(
                    children:[
                      Expanded(
                        child: Container(
                          color:Colors.grey[300],
                          child: b.imageUrl==null
                              ? const Icon(Icons.bakery_dining, size:40)
                              : Image.network(b.imageUrl!, fit:BoxFit.cover),
                        ),
                      ),
                      const SizedBox(height:4),
                      Text(b.name),
                    ],
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
