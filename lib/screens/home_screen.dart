// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import '../services/bread_service.dart';
import '../models/bread.dart';
import '../widgets/common/custom_appbar.dart';

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

class _HomeScreenState extends State<HomeScreen> {
  bool _loading = true;

  // 전체 빵 목록
  List<Bread> _allBreads = [];
  List<Bread> _filteredBreads = [];

  String _sortKey = '조회순';
  Set<String> _selectedStores = {};
  String _searchKeyword = '';

  // 자동완성 목록
  List<String> _suggestions = [];

  @override
  void initState(){
    super.initState();
    _initFetch();
  }

  Future<void> _initFetch() async {
    await BreadService.fetchAllBreads();
    setState(() {
      _allBreads = BreadService.allBreadsCache;
      _filteredBreads = [..._allBreads];
      _loading = false;
    });
  }

  // (1) 검색창 onChanged -> 실시간 자동완성
  Future<void> onSearchTextChanged(String keyword) async {
    setState(()=> _searchKeyword = keyword.trim());
    if(_searchKeyword.isEmpty){
      // 전체 목록
      setState(()=>_filteredBreads = _applySortFilter(_allBreads));
      _suggestions = [];
      return;
    }
    // 서버 호출
    final results = await BreadService.searchBreads(_searchKeyword);
    setState(() {
      _filteredBreads = _applySortFilter(results);
      // suggestions: 빵 이름만 표시
      _suggestions = results.map((e)=> e.name).toList();
    });
  }

  // (2) Enter 시 -> 검색 결과 페이지 이동
  void _onSearch(String keyword) {
    // 페이지 1개만 유지 => pushReplacement
    Navigator.pushReplacementNamed(context, '/searchResult', arguments: keyword);
  }

  List<Bread> _applySortFilter(List<Bread> list) {
    List<Bread> filtered = [...list];
    if(_selectedStores.isNotEmpty){
      filtered = filtered.where((b){
        if(b.stores==null) return false;
        final storeNames = b.stores!.map((s)=> s.storeName).toSet();
        return storeNames.intersection(_selectedStores).isNotEmpty;
      }).toList();
    }

    // 간단 정렬
    if(_sortKey=='조회순'){
      filtered.sort((a,b)=> b.breadId.compareTo(a.breadId));
    } else if(_sortKey=='최신순'){
      filtered.sort((a,b)=> b.breadId.compareTo(a.breadId));
    } else if(_sortKey=='리뷰수'){
      filtered.sort((a,b)=> a.breadId.compareTo(b.breadId));
    } else if(_sortKey=='평점순'){
      // no data
    }
    return filtered;
  }

  void _pickSort() async {
    final val = await showDialog<String>(
        context: context,
        builder:(ctx)=> SimpleDialog(
          title: const Text('정렬 기준'),
          children:[
            SimpleDialogOption(child: const Text('조회순'), onPressed: ()=>Navigator.pop(ctx,'조회순')),
            SimpleDialogOption(child: const Text('최신순'), onPressed: ()=>Navigator.pop(ctx,'최신순')),
            SimpleDialogOption(child: const Text('리뷰수'), onPressed: ()=>Navigator.pop(ctx,'리뷰수')),
            SimpleDialogOption(child: const Text('평점순'), onPressed: ()=>Navigator.pop(ctx,'평점순')),
          ],
        )
    );
    if(val!=null){
      setState(()=> _sortKey=val);
      final results = _searchKeyword.isEmpty
          ? _allBreads
          : await BreadService.searchBreads(_searchKeyword);
      _filteredBreads = _applySortFilter(results);
    }
  }

  void _pickStoreFilter() async {
    final chosen = await showDialog<Set<String>>(
        context: context,
        builder:(ctx){
          Set<String> temp = {..._selectedStores};
          return AlertDialog(
            title: const Text('지점 필터'),
            content: StatefulBuilder(
              builder:(context,setStateDialog){
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children:[
                    _storeCheckbox('대전역점', temp, setStateDialog),
                    _storeCheckbox('은행동점(본점)', temp, setStateDialog),
                    _storeCheckbox('스마트시티점', temp, setStateDialog),
                  ],
                );
              },
            ),
            actions:[
              TextButton(onPressed:()=>Navigator.pop(ctx,null), child: const Text('취소')),
              ElevatedButton(onPressed:()=>Navigator.pop(ctx,temp), child: const Text('확인')),
            ],
          );
        }
    );
    if(chosen!=null){
      setState(()=> _selectedStores=chosen);
      final results = _searchKeyword.isEmpty
          ? _allBreads
          : await BreadService.searchBreads(_searchKeyword);
      _filteredBreads = _applySortFilter(results);
    }
  }

  Widget _storeCheckbox(String name, Set<String> temp, void Function(void Function()) setStateDialog){
    final isChecked = temp.contains(name);
    return CheckboxListTile(
      title: Text(name),
      value: isChecked,
      onChanged:(v){
        setStateDialog(() {
          if(v==true) temp.add(name); else temp.remove(name);
        });
      },
    );
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      // CustomAppBar에서 onChanged -> onSearchTextChanged 연결
      appBar: CustomAppBar(
        isHome:true,
        onSearchSubmitted:_onSearch,
        leading: null,
        actions: const [],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children:[
          // 정렬/필터
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children:[
              TextButton(
                onPressed:_pickSort,
                child: Text('정렬: $_sortKey'),
              ),
              TextButton(
                onPressed:_pickStoreFilter,
                child: const Text('지점 필터'),
              ),
            ],
          ),

          // (자동완성) _suggestions
          if(_suggestions.isNotEmpty)
            Container(
              color: Colors.orange[50],
              height:100,
              child: ListView.builder(
                itemCount: _suggestions.length,
                itemBuilder:(ctx,i){
                  final s = _suggestions[i];
                  return InkWell(
                    onTap: (){
                      // 해당 suggestion으로 검색
                      _onSearch(s);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical:6, horizontal:10),
                      child: Text(s, style: const TextStyle(color:Colors.blue)),
                    ),
                  );
                },
              ),
            ),

          // 그리드
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount:3,
                crossAxisSpacing:8,
                mainAxisSpacing:8,
              ),
              itemCount:_filteredBreads.length,
              itemBuilder:(ctx,i){
                final b = _filteredBreads[i];
                return InkWell(
                  onTap: (){
                    // 단일 페이지 => pushReplacement
                    Navigator.pushReplacementNamed(context, '/breadDetail', arguments:b.breadId);
                  },
                  child: Column(
                    children:[
                      Expanded(
                        child: Container(
                          color: Colors.grey[300],
                          child: (b.imageUrl==null)
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
