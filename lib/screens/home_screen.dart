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

  // 자동완성: Bread 목록으로 보관
  List<Bread> _suggestionBreads = [];

  @override
  void initState() {
    super.initState();
    _initFetch();
  }

  /// 초기 빵 목록 + 캐싱
  Future<void> _initFetch() async {
    await BreadService.fetchAllBreads();
    setState(() {
      _allBreads = BreadService.allBreadsCache;
      _filteredBreads = _applySortFilter(_allBreads);
      _loading = false;
    });
  }

  /// (1) 검색창 onChanged -> 실시간 자동완성
  /// 홈 화면 빵 목록(_filteredBreads) 자체는 변경 없음
  Future<void> onSearchTextChanged(String keyword) async {
    setState(() => _searchKeyword = keyword.trim());

    if (_searchKeyword.isEmpty) {
      setState(() => _suggestionBreads = []);
      return;
    }
    // 서버에 검색 API 호출
    final results = await BreadService.searchBreads(_searchKeyword);
    // 결과 없으면 빈 리스트
    setState(() => _suggestionBreads = results);
  }

  /// (2) Enter 시 -> 검색 결과 페이지 이동
  void _onSearch(String keyword) {
    Navigator.pushReplacementNamed(context, '/searchResult', arguments: keyword);
  }

  /// 정렬 & 지점 필터
  List<Bread> _applySortFilter(List<Bread> list) {
    List<Bread> filtered = [...list];

    // 지점 필터
    if (_selectedStores.isNotEmpty) {
      filtered = filtered.where((b) {
        if (b.stores == null) return false;
        final storeNames = b.stores!.map((s) => s.storeName).toSet();
        return storeNames.intersection(_selectedStores).isNotEmpty;
      }).toList();
    }

    // 간단 정렬
    if (_sortKey == '조회순') {
      filtered.sort((a, b) => b.breadId.compareTo(a.breadId));
    } else if (_sortKey == '최신순') {
      filtered.sort((a, b) => b.breadId.compareTo(a.breadId));
    } else if (_sortKey == '리뷰수') {
      filtered.sort((a, b) => a.breadId.compareTo(b.breadId));
    } else if (_sortKey == '평점순') {
      // TODO
    }
    return filtered;
  }

  // 정렬 기준 선택
  void _pickSort() async {
    final val = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('정렬 기준'),
        children: [
          SimpleDialogOption(child: const Text('조회순'), onPressed: () => Navigator.pop(ctx, '조회순')),
          SimpleDialogOption(child: const Text('최신순'), onPressed: () => Navigator.pop(ctx, '최신순')),
          SimpleDialogOption(child: const Text('리뷰수'), onPressed: () => Navigator.pop(ctx, '리뷰수')),
          SimpleDialogOption(child: const Text('평점순'), onPressed: () => Navigator.pop(ctx, '평점순')),
        ],
      ),
    );
    if (val != null) {
      setState(() => _sortKey = val);
      _filteredBreads = _applySortFilter(_allBreads);
    }
  }

  // 지점 필터 선택
  void _pickStoreFilter() async {
    final chosen = await showDialog<Set<String>>(
      context: context,
      builder: (ctx) {
        Set<String> temp = {..._selectedStores};
        return AlertDialog(
          title: const Text('지점 필터'),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _storeCheckbox('대전역점', temp, setStateDialog),
                  _storeCheckbox('은행동점(본점)', temp, setStateDialog),
                  _storeCheckbox('스마트시티점', temp, setStateDialog),
                ],
              );
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('취소')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, temp), child: const Text('확인')),
          ],
        );
      },
    );
    if (chosen != null) {
      setState(() => _selectedStores = chosen);
      _filteredBreads = _applySortFilter(_allBreads);
    }
  }

  Widget _storeCheckbox(String name, Set<String> temp, void Function(void Function()) setStateDialog) {
    final isChecked = temp.contains(name);
    return CheckboxListTile(
      title: Text(name),
      value: isChecked,
      onChanged: (v) {
        setStateDialog(() {
          if (v == true) temp.add(name);
          else temp.remove(name);
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        isHome: true,
        onSearchSubmitted: _onSearch,         // 엔터 시
        onSearchChanged: onSearchTextChanged, // 입력 변경 시 자동완성
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // 정렬/필터 버튼
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _pickSort,
                child: Text('정렬: $_sortKey'),
              ),
              TextButton(
                onPressed: _pickStoreFilter,
                child: const Text('지점 필터'),
              ),
            ],
          ),

          // 자동완성 (검색 키워드 존재할 때만 표시)
          if (_searchKeyword.isNotEmpty)
            _buildSuggestions(),

          // 홈 빵 목록 그리드
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _filteredBreads.length,
              itemBuilder: (ctx, i) {
                final b = _filteredBreads[i];
                return InkWell(
                  onTap: () {
                    Navigator.pushReplacementNamed(context, '/breadDetail', arguments: b.breadId);
                  },
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          color: Colors.grey[300],
                          child: (b.imageUrl == null)
                              ? const Icon(Icons.bakery_dining, size: 40)
                              : Image.network(
                            b.imageUrl!,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
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

  /// 자동완성 위젯
  Widget _buildSuggestions() {
    // 검색 키워드는 있으나 결과가 비어있으면 "검색 결과 없음"
    if (_suggestionBreads.isEmpty) {
      return Container(
        height: 40,
        color: Colors.orange[50],
        child: const Center(
          child: Text('검색 결과가 없습니다'),
        ),
      );
    }
    // 결과가 있으면 리스트
    return Container(
      color: Colors.orange[50],
      height: 100,
      child: ListView.builder(
        itemCount: _suggestionBreads.length,
        itemBuilder: (ctx, i) {
          final bread = _suggestionBreads[i];
          return InkWell(
            onTap: () {
              // 자동완성 탭 시 곧바로 해당 빵 상세 이동
              Navigator.pushReplacementNamed(context, '/breadDetail', arguments: bread.breadId);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
              child: Text(bread.name, style: const TextStyle(color: Colors.blue)),
            ),
          );
        },
      ),
    );
  }
}
