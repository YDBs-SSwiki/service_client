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
  bool _canChangeName = true; // 30일 제한

  List<Map<String,dynamic>> _favorites = [];
  List<Map<String,dynamic>> _myReviews = [];

  // 찜 목록에 “이미지+제목” 보여주기 위해 summary 캐시
  Map<int,Bread> _favoriteDetails = {};

  @override
  void initState(){
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    final uid = AuthService.currentUserId??0;
    if(uid==0) return;

    // 유저 정보
    final info = await UserService.getUserInfo(uid);
    if(info!=null){
      setState(()=> nickname = info.username);
    }
    // 찜 목록
    final favs = await FavoriteService.getUserFavorites(uid);
    // 내 리뷰
    final reviews = await UserService.getUserReviews(uid);

    setState(() {
      _favorites = favs; // ex) [ {breadId:10, name:'단팥빵'}, ... ]
      _myReviews = reviews;
    });

    // “이미지” “디테일”을 위해 breadId마다 BreadService.getBreadDetail or Summary
    for(final f in favs){
      final bid = f['breadId'] as int?;
      if(bid!=null){
        final summary = await _fetchBreadSummary(bid);
        if(summary!=null){
          _favoriteDetails[bid] = summary;
        }
      }
    }
    setState(()=>{});
  }

  // 간단히 bread_detail 불러오거나 /bread/{id}/summary API가 있다고 가정
  Future<Bread?> _fetchBreadSummary(int breadId) async {
    try {
      // 예: /bread/{breadId}/summary
      // 여기선 그냥 detail API로...
      final b = await BreadService.getBreadDetail(breadId);
      return b;
    } catch(_){
      return null;
    }
  }

  void _onLogout(){
    AuthService.logout();
    Navigator.pushNamedAndRemoveUntil(context, '/', (route)=>false);
  }

  void _onSearch(String keyword){
    Navigator.pushReplacementNamed(context, '/searchResult', arguments: keyword);
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: CustomAppBar(
        isHome:false,
        onSearchSubmitted:_onSearch,
        actions:[
          ElevatedButton.icon(
            onPressed:_onLogout,
            icon: const Icon(Icons.logout),
            label: const Text('로그아웃'),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children:[
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

  Widget _buildMyReviewsSection(){
    final displayedCount = _showAllReviews ? _myReviews.length : (_myReviews.isEmpty?0:1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:[
        const Text('내가 쓴 리뷰', style: TextStyle(fontSize:18, fontWeight:FontWeight.bold)),
        for(int i=0; i<displayedCount; i++)
          ListTile(
            title: Text(
                '리뷰${_myReviews[i]['reviewId']}: ${_myReviews[i]['content']} (★${_myReviews[i]['rating']})'
            ),
            subtitle: Text(
                'breadId=${_myReviews[i]['breadId']} createdAt=${_myReviews[i]['createdAt']}'
            ),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children:[
            TextButton(
              onPressed: (){
                // 정렬 or 페이지네이션
              },
              child: const Text('정렬'),
            ),
            TextButton(
              onPressed: (){
                setState(()=>_showAllReviews=!_showAllReviews);
              },
              child: Text(_showAllReviews?'접기':'더보기'),
            )
          ],
        )
      ],
    );
  }

  Widget _buildFavoritesSection(){
    final displayed = _showAllFavorites ? _favorites : _favorites.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:[
        const Text('찜 목록', style: TextStyle(fontSize:18, fontWeight:FontWeight.bold)),
        SizedBox(
          height: 200, // 높이 좀 더
          child: GridView.count(
            crossAxisCount:3,
            children: displayed.map((f){
              final bid = f['breadId'] as int;
              final bSummary = _favoriteDetails[bid];
              if(bSummary==null){
                // 아직 로딩 안됨
                return Container(
                  margin: const EdgeInsets.all(4),
                  color: Colors.yellow,
                  child: Center(child: Text('${f['name']}')),
                );
              } else {
                // 이미지+제목
                return InkWell(
                  onTap: (){
                    Navigator.pushReplacementNamed(context, '/breadDetail', arguments:bid);
                  },
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color:Colors.brown),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children:[
                        // 썸네일
                        if(bSummary.imageUrl!=null)
                          SizedBox(
                            height:60, width:60,
                            child: Image.network(bSummary.imageUrl!, fit:BoxFit.cover),
                          )
                        else
                          const Icon(Icons.bakery_dining, size:40),
                        const SizedBox(height:4),
                        Text(bSummary.name, overflow:TextOverflow.ellipsis),
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
          children:[
            TextButton(
              onPressed: (){
                setState(()=>_showAllFavorites = !_showAllFavorites);
              },
              child: Text(_showAllFavorites?'접기':'더보기'),
            )
          ],
        )
      ],
    );
  }

  Widget _buildUpdateUserSection(){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:[
        const Text('내 정보 변경', style: TextStyle(fontSize:18, fontWeight:FontWeight.bold)),
        Row(
          children:[
            Expanded(
              child: TextField(
                controller:_nickController,
                decoration: InputDecoration(labelText:'닉네임 (현재: $nickname)'),
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

  Future<void> _changeNickname() async {
    final newNick = _nickController.text.trim();
    if(newNick.isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('닉네임 입력')));
      return;
    }
    final confirm = await showDialog<bool>(
        context: context,
        builder:(ctx)=> AlertDialog(
          title: const Text('닉네임 변경'),
          content: Text('정말 "$newNick" 으로 변경하시겠습니까?'),
          actions:[
            TextButton(onPressed:()=>Navigator.pop(ctx,false), child: const Text('아니오')),
            TextButton(onPressed:()=>Navigator.pop(ctx,true), child: const Text('예')),
          ],
        )
    );
    if(confirm==true){
      final uid = AuthService.currentUserId??0;
      if(uid==0){
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('로그인 안됨')));
        return;
      }
      final ok = await UserService.updateUserNickname(uid, newNick);
      if(ok){
        setState(()=> nickname=newNick);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('변경 완료')));
      } else {
        // 서버: 중복 or 30일 미만
        showDialog(
            context: context,
            builder:(_)=> AlertDialog(
              title: const Text('닉네임 변경 실패'),
              content: const Text('이미 존재하거나 30일 제한.'),
              actions:[TextButton(onPressed:()=>Navigator.pop(_), child: const Text('확인'))],
            )
        );
      }
    }
  }
}
