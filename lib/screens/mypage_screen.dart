// lib/screens/mypage_screen.dart

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/favorite_service.dart';
import '../services/user_service.dart';
import '../widgets/common/custom_appbar.dart';
import '../services/bread_service.dart';
import '../models/bread.dart';

class MyPageScreen extends StatefulWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onToggleDarkMode;

  const MyPageScreen({
    Key? key,
    required this.isDarkMode,
    required this.onToggleDarkMode,
  }) : super(key: key);

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  bool _showAllReviews = false;
  bool _showAllFavorites = false;

  final _nickController = TextEditingController();

  String nickname = '로딩중';
  bool _canChangeName = true; // 30일 제한 (예시)

  // 서버에서 받아온 찜 목록 예: [{ "breadId":10, "name":"단팥빵" }, ...]
  List<Map<String, dynamic>> _favorites = [];

  // 내가 쓴 리뷰 목록 예: [{ "reviewId":123, "breadId":10, ... }, ...]
  List<Map<String, dynamic>> _myReviews = [];

  // 찜 목록에 “이미지+제목” 보여주기 위해 breadId별 Bread 상세 캐싱
  Map<int, Bread> _favoriteDetails = {};

  // 자동완성
  String _searchKeyword = '';
  List<Bread> _suggestionBreads = [];

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  /// 초기 데이터 (사용자 정보, 찜 목록, 리뷰 목록) 가져오기
  Future<void> _fetchInitialData() async {
    final uid = AuthService.currentUserId ?? 0;
    if (uid == 0) return; // 로그인 안 된 상태면 그냥 return

    // (1) 유저 정보
    final info = await UserService.getUserInfo(uid);
    if (info != null) {
      setState(() => nickname = info.username);
    }

    // (2) 찜 목록
    //  => GET /users/{userId}/favorites
    //  => 응답 형식:
    //     {
    //       "userId": 50,
    //       "favorites": [
    //         { "breadId":10, "name":"단팥빵" },
    //         { "breadId":11, "name":"크림빵" }
    //       ]
    //     }
    final favs = await FavoriteService.getUserFavorites(uid);

    // (3) 내가 쓴 리뷰 목록
    final reviews = await UserService.getUserReviews(uid);

    // 화면 반영
    setState(() {
      _favorites = favs;    // [{ "breadId":10, "name":"단팥빵" }, ... ]
      _myReviews = reviews;
    });

    // (추가) 만약 서버에서 userId도 넘겨준다면, 확인 가능
    // final favoritesResponse = await FavoriteService.getUserFavorites(uid);
    // print("서버 응답 userId = ${favoritesResponseUserId}"); // 예시

    // (4) 찜 목록에 있는 breadId 별로 Bread 상세(혹은 summary) 불러오기
    for (final f in favs) {
      final bid = f['breadId'] as int?;
      if (bid != null) {
        final summary = await _fetchBreadSummary(bid);
        if (summary != null) {
          _favoriteDetails[bid] = summary;
        }
      }
    }

    // setState로 UI 갱신
    setState(() {});
  }

  /// 간단히 bread_detail 불러오거나, /bread/{breadId}/summary 같은 API 사용
  Future<Bread?> _fetchBreadSummary(int breadId) async {
    try {
      final b = await BreadService.getBreadDetail(breadId);
      return b;
    } catch (_) {
      return null;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 자동완성 관련
  // ─────────────────────────────────────────────────────────────────────────

  /// (1) 실시간 입력 -> 자동완성
  Future<void> _onSearchTextChanged(String keyword) async {
    setState(() => _searchKeyword = keyword.trim());
    if (_searchKeyword.isEmpty) {
      setState(() => _suggestionBreads = []);
      return;
    }
    final results = await BreadService.searchBreads(_searchKeyword);
    setState(() => _suggestionBreads = results);
  }

  /// (2) 엔터 -> 검색 결과 페이지 이동
  void _onSearch(String keyword) {
    Navigator.pushReplacementNamed(context, '/searchResult', arguments: keyword);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 로그아웃
  // ─────────────────────────────────────────────────────────────────────────
  void _onLogout() {
    AuthService.logout();
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // UI 빌드
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        isHome: false,
        onSearchSubmitted: _onSearch,
        onSearchChanged: _onSearchTextChanged,
        actions: [
          ElevatedButton.icon(
            onPressed: _onLogout,
            icon: const Icon(Icons.logout),
            label: const Text('로그아웃'),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 자동완성
            if (_searchKeyword.isNotEmpty) _buildSuggestions(),

            _buildMyReviewsSection(),
            const Divider(),
            _buildFavoritesSection(),
            const Divider(),
            _buildUpdateUserSection(),
          ],
        ),
      ),
    );
  }

  /// 자동완성 위젯
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

  /// 내가 쓴 리뷰 섹션
  Widget _buildMyReviewsSection() {
    final displayedCount = _showAllReviews ? _myReviews.length : (_myReviews.isEmpty ? 0 : 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('내가 쓴 리뷰', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        for (int i = 0; i < displayedCount; i++)
          ListTile(
            title: Text('리뷰${_myReviews[i]['reviewId']}: ${_myReviews[i]['content']} (★${_myReviews[i]['rating']})'),
            subtitle: Text('breadId=${_myReviews[i]['breadId']} createdAt=${_myReviews[i]['createdAt']}'),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () {
                // 예: 정렬 or 페이지네이션
              },
              child: const Text('정렬'),
            ),
            TextButton(
              onPressed: () {
                setState(() => _showAllReviews = !_showAllReviews);
              },
              child: Text(_showAllReviews ? '접기' : '더보기'),
            )
          ],
        )
      ],
    );
  }

  /// 찜 목록 섹션
  Widget _buildFavoritesSection() {
    // _showAllFavorites==true면 전체, 아니면 최대 3개만 보여주기
    final displayed = _showAllFavorites ? _favorites : _favorites.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('찜 목록', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(
          height: 200,
          child: GridView.count(
            crossAxisCount: 3,
            children: displayed.map((f) {
              final bid = f['breadId'] as int;
              final bSummary = _favoriteDetails[bid];
              if (bSummary == null) {
                // 아직 상세 불러오지 못했을 경우
                return Container(
                  margin: const EdgeInsets.all(4),
                  color: Colors.yellow,
                  child: Center(child: Text('${f['name']}')),
                );
              } else {
                // 이미지+제목
                return InkWell(
                  onTap: () {
                    Navigator.pushReplacementNamed(context, '/breadDetail', arguments: bid);
                  },
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.brown),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 썸네일
                        if (bSummary.imageUrl != null)
                          SizedBox(
                            height: 60,
                            width: 60,
                            child: Image.network(bSummary.imageUrl!, fit: BoxFit.cover),
                          )
                        else
                          const Icon(Icons.bakery_dining, size: 40),
                        const SizedBox(height: 4),
                        Text(bSummary.name, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                );
              }
            }).toList(),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () {
                setState(() => _showAllFavorites = !_showAllFavorites);
              },
              child: Text(_showAllFavorites ? '접기' : '더보기'),
            )
          ],
        )
      ],
    );
  }

  /// 닉네임 변경 섹션
  Widget _buildUpdateUserSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('내 정보 변경', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _nickController,
                decoration: InputDecoration(labelText: '닉네임 (현재: $nickname)'),
              ),
            ),
            ElevatedButton(
              onPressed: _canChangeName ? _changeNickname : null,
              child: const Text('변경'),
            )
          ],
        )
      ],
    );
  }

  /// 닉네임 변경 로직
  Future<void> _changeNickname() async {
    final newNick = _nickController.text.trim();
    if (newNick.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('닉네임 입력')));
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('닉네임 변경'),
        content: Text('정말 "$newNick" 으로 변경하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('아니오')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('예')),
        ],
      ),
    );
    if (confirm == true) {
      final uid = AuthService.currentUserId ?? 0;
      if (uid == 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('로그인 안됨')));
        return;
      }
      final ok = await UserService.updateUserNickname(uid, newNick);
      if (ok) {
        setState(() => nickname = newNick);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('변경 완료')));
      } else {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('닉네임 변경 실패'),
            content: const Text('이미 존재하거나 30일 제한.'),
            actions: [TextButton(onPressed: () => Navigator.pop(_), child: const Text('확인'))],
          ),
        );
      }
    }
  }
}
