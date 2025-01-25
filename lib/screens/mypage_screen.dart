// lib/screens/mypage_screen.dart

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/favorite_service.dart';
import '../services/user_service.dart';
import '../widgets/common/custom_appbar.dart';

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
  bool _showAllReviews=false;
  bool _showAllFavorites=false;
  final _nickController = TextEditingController();
  String nickname='기존닉네임';

  List<Map<String,dynamic>> _favorites=[];
  List<Map<String,dynamic>> _myReviews=[];

  bool _canChangeName=true; // 30일 제한 남았으면 false

  @override
  void initState(){
    super.initState();
    _fetchFav();
    _fetchMyReviews();
    // 서버에서 유저정보 받아 닉네임 / lastModifiedAt 확인 → 30일 제한
    _checkNicknameStatus();
  }

  Future<void> _checkNicknameStatus() async {
    final uid = AuthService.currentUserId??0;
    if(uid==0) return;
    final info = await UserService.getUserInfo(uid);
    if(info!=null){
      nickname = info.username;
      // 예: lastModifiedAt과 오늘 날짜 차이가 30일 미만이면 false
      // 여기선 더미
      // _canChangeName = false;
    }
    setState(() {});
  }

  Future<void> _fetchFav() async {
    final uid = AuthService.currentUserId??0;
    if(uid==0) return;
    final list = await FavoriteService.getUserFavorites(uid);
    setState(()=>_favorites=list);
  }

  Future<void> _fetchMyReviews() async {
    final uid = AuthService.currentUserId??0;
    if(uid==0) return;
    final list = await UserService.getUserReviews(uid);
    setState(()=>_myReviews=list);
  }

  void _onLogout(){
    AuthService.logout();
    Navigator.pushNamedAndRemoveUntil(context, '/', (route)=>false);
  }

  void _onSearch(String val){
    Navigator.pushNamed(context, '/searchResult', arguments: val);
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
    // 페이지네이션/정렬(추가 가능). 여기선 더보기 토글
    final displayedCount = _showAllReviews ? _myReviews.length : (_myReviews.isEmpty? 0 : 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:[
        const Text('내가 쓴 리뷰', style: TextStyle(fontSize:18, fontWeight:FontWeight.bold)),
        for(int i=0; i<displayedCount; i++)
          ListTile(
            title: Text('리뷰${_myReviews[i]['reviewId']}: ${_myReviews[i]['content']} (★${_myReviews[i]['rating']})'),
            subtitle: Text('breadId=${_myReviews[i]['breadId']} createdAt=${_myReviews[i]['createdAt']}'),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children:[
            TextButton(
              onPressed: (){
                // 정렬 다이얼로그 or 등
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
          height:150,
          child: GridView.count(
            crossAxisCount:3,
            children: displayed.map((f){
              return InkWell(
                onTap: (){
                  // 빵 상세로 이동
                  Navigator.pushNamed(context, '/breadDetail', arguments: f['breadId'] as int);
                },
                child: Container(
                  margin: const EdgeInsets.all(4),
                  color: Colors.yellow,
                  child: Center(child: Text('${f['name']}')),
                ),
              );
            }).toList(),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children:[
            TextButton(
              onPressed: (){
                setState(()=>_showAllFavorites=!_showAllFavorites);
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
                decoration: InputDecoration(
                  labelText:'닉네임 (현재: $nickname)',
                ),
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
        context:context,
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
      if(!ok){
        // 서버에서 "중복" or "30일 제한" 등
        showDialog(
            context:context,
            builder:(_)=> AlertDialog(
              title: const Text('닉네임 변경 실패'),
              content: const Text('이미 존재하는 닉네임이거나 30일 제한입니다.'),
              actions:[
                TextButton(onPressed:()=>Navigator.pop(_), child: const Text('확인'))
              ],
            )
        );
      } else {
        setState(()=>nickname=newNick);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('변경 완료')));
      }
    }
  }
}
