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
  // 화면에 표시할 빵 목록(정렬/필터 적용)
  List<Bread> _filteredBreads = [];

  String _sortKey = '조회순'; // 조회순 / 최신순 / 리뷰수 / 평점
  Set<String> _selectedStores = {}; // 대전역점, 은행동점(본점), 스마트시티점
  String _searchKeyword = '';

  @override
  void initState(){
    super.initState();
    _initFetch();
  }

  Future<void> _initFetch() async {
    // 서버에서 빵 목록 가져옴
    await BreadService.fetchAllBreads();
    setState(() {
      _allBreads = BreadService.allBreadsCache;
      _filteredBreads = [..._allBreads];
      _loading = false;
    });
  }

  // 실시간 검색 (AppBar의 TextField onChanged)
  void onSearchTextChanged(String keyword) async {
    setState(() {
      _searchKeyword = keyword.trim();
    });
    // 만약 빈 문자열이면 검색 목록 비우거나 전체 반환
    if(_searchKeyword.isEmpty){
      // 그냥 전체 목록으로
      setState(() {
        _filteredBreads = _applySortFilter(_allBreads);
      });
      return;
    }
    // 서버에 실시간 요청 (자동완성) or 로컬 검색
    // 여기서는 간단히 BreadService.searchBreads(...) 사용
    final results = await BreadService.searchBreads(_searchKeyword);
    // 실시간 검색 응답을 다시 정렬/필터에 반영
    setState(() {
      _filteredBreads = _applySortFilter(results);
    });
  }

  // 정렬/필터 + existing 목록 -> 최종
  List<Bread> _applySortFilter(List<Bread> list){
    // 1) 스토어 필터
    List<Bread> filtered = [...list];
    if(_selectedStores.isNotEmpty){
      filtered = filtered.where((b){
        if(b.stores==null) return false;
        // 이 빵이 가진 storeName 중 하나라도 _selectedStores에 있으면 통과
        final storeNames = b.stores!.map((s)=> s.storeName).toSet();
        // 모든 선택된 지점이 이 빵에 포함돼야 하는지? or 교집합 있으면?
        // 요구사항 모호 → 교집합(ANY match)라고 가정
        return storeNames.intersection(_selectedStores).isNotEmpty;
      }).toList();
    }

    // 2) 정렬
    // 실제론 서버 정렬 or local
    if(_sortKey=='조회순'){
      // 가정: breadId가 높을수록 많이 조회된다고 가정(임시)
      filtered.sort((a,b)=> b.breadId.compareTo(a.breadId));
    } else if(_sortKey=='최신순'){
      // createdAt 기준 or breadId 기준? 임시로 breadId desc
      filtered.sort((a,b)=> b.breadId.compareTo(a.breadId));
    } else if(_sortKey=='리뷰수'){
      // 여기선 임시(디테일 없음). 그냥 breadId asc
      filtered.sort((a,b)=> a.breadId.compareTo(b.breadId));
    } else if(_sortKey=='평점순'){
      // 임시. rating이 없음. 그냥 random
      // or do nothing
    }

    return filtered;
  }

  void _onSearch(String keyword){
    // Enter 시 검색 결과 페이지 이동
    Navigator.pushNamed(context, '/searchResult', arguments: keyword);
  }

  // 정렬 선택
  void _pickSort() async {
    final val = await showDialog<String>(
        context: context,
        builder:(ctx)=> SimpleDialog(
          title: const Text('정렬 기준'),
          children: [
            SimpleDialogOption(
              child: const Text('조회순'),
              onPressed: ()=>Navigator.pop(ctx,'조회순'),
            ),
            SimpleDialogOption(
              child: const Text('최신순'),
              onPressed: ()=>Navigator.pop(ctx,'최신순'),
            ),
            SimpleDialogOption(
              child: const Text('리뷰수'),
              onPressed: ()=>Navigator.pop(ctx,'리뷰수'),
            ),
            SimpleDialogOption(
              child: const Text('평점순'),
              onPressed: ()=>Navigator.pop(ctx,'평점순'),
            ),
          ],
        )
    );
    if(val!=null){
      setState(()=> _sortKey=val);
      _filteredBreads = _applySortFilter((_searchKeyword.isEmpty)
          ? _allBreads
          : await BreadService.searchBreads(_searchKeyword));
    }
  }

  // 스토어 필터
  void _pickStoreFilter() async {
    final result = await showDialog<Set<String>>(
        context: context,
        builder:(ctx){
          Set<String> temp = {..._selectedStores};
          return AlertDialog(
            title: const Text('지점 필터'),
            content: StatefulBuilder(
              builder:(context,setStateDialog){
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildStoreCheckbox('대전역점', temp, setStateDialog),
                    _buildStoreCheckbox('은행동점(본점)', temp, setStateDialog),
                    _buildStoreCheckbox('스마트시티점', temp, setStateDialog),
                  ],
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: ()=>Navigator.pop(ctx,null),
                child: const Text('취소'),
              ),
              ElevatedButton(
                onPressed: ()=>Navigator.pop(ctx,temp),
                child: const Text('확인'),
              )
            ],
          );
        }
    );
    if(result!=null){
      setState(()=>_selectedStores=result);
      _filteredBreads = _applySortFilter((_searchKeyword.isEmpty)
          ? _allBreads
          : await BreadService.searchBreads(_searchKeyword));
    }
  }

  Widget _buildStoreCheckbox(String storeName, Set<String> temp, void Function(void Function()) setStateDialog){
    final isSelected = temp.contains(storeName);
    return CheckboxListTile(
        title: Text(storeName),
        value: isSelected,
        onChanged: (val){
          setStateDialog((){
            if(val==true){
              temp.add(storeName);
            } else {
              temp.remove(storeName);
            }
          });
        }
    );
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      // AppBar: 검색창의 onChanged를 실시간 호출하기 위해 CustomAppBar 수정
      appBar: CustomAppBar(
        isHome:true,
        onSearchSubmitted: _onSearch,
        // leading, actions 필요 없으므로 생략
        // 실시간 검색은 custom_appbar.dart를 수정해서 onChanged 지원 (아래에서 수정)
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
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
                    Navigator.pushNamed(context, '/breadDetail', arguments:b.breadId);
                  },
                  child: Column(
                    children: [
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
