// lib/screens/bread_detail_screen.dart

import 'package:flutter/material.dart';
import '../services/bread_service.dart';
import '../services/review_service.dart';
import '../services/favorite_service.dart';
import '../services/auth_service.dart';
import '../models/bread.dart';
import '../models/review.dart';
import '../widgets/common/custom_appbar.dart';
import '../widgets/popups/review_popup.dart';
import '../widgets/popups/edit_bread_popup.dart';

class BreadDetailScreen extends StatefulWidget {
  final int breadId;
  final bool isDarkMode;
  final ValueChanged<bool> onToggleDarkMode;

  const BreadDetailScreen({
    Key? key,
    required this.breadId,
    required this.isDarkMode,
    required this.onToggleDarkMode,
  }) : super(key: key);

  @override
  State<BreadDetailScreen> createState() => _BreadDetailScreenState();
}

class _BreadDetailScreenState extends State<BreadDetailScreen> {
  Bread? _bread;
  List<Review> _reviews = [];
  bool _loading = true;

  String _reviewSort='추천순';
  int? _filterRating;

  bool get isLoggedIn => AuthService.isLoggedIn;

  @override
  void initState(){
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final b = await BreadService.getBreadDetail(widget.breadId);
    final r = await ReviewService.getBreadReviews(widget.breadId);
    setState(() {
      _bread=b;
      _reviews=r;
      _loading=false;
    });
  }

  void _toggleFavorite() async {
    if(!isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('로그인 필요')));
      return;
    }
    final uid = AuthService.currentUserId ?? 0;
    final ok = await FavoriteService.setFavorite(userId: uid, breadId: widget.breadId);
    if(ok){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('찜 완료')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('찜 실패')));
    }
  }

  // 빵 문서 편집 팝업
  void _goEditDoc() async {
    if(!isLoggedIn){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('로그인 필요')));
      return;
    }
    if(_bread==null) return;
    final edited = await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_)=> EditBreadPopup(bread: _bread!)
    );
    if(edited==true){
      // 재로딩
      _loadData();
    }
  }

  void _openReviewPopup({Review? existing}) async {
    if(!isLoggedIn){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('로그인 필요')));
      return;
    }
    final result = await showDialog(
        context: context,
        barrierDismissible:false,
        builder: (_)=> ReviewPopup(
          breadId: widget.breadId,
          existingReview: existing,
        )
    );
    if(result==true){
      _loadData();
    }
  }

  // 좋아요
  void _toggleLike(Review rv) async {
    if(!isLoggedIn){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('로그인 필요')));
      return;
    }
    // 자기 리뷰면 불가
    if(rv.userId == AuthService.currentUserId){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('본인 리뷰는 좋아요 불가')));
      return;
    }
    final uid = AuthService.currentUserId??0;
    // true= 좋아요, 다시 누르면 like=false
    bool alreadyLiked = (rv.liked==true);
    final newLikes = await ReviewService.updateReviewLike(
      reviewId: rv.reviewId,
      userId: uid,
      like: !alreadyLiked, // 토글
    );
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('좋아요=$newLikes')));
    _loadData();
  }

  void _pickReviewSort() async {
    final val = await showDialog<String>(
        context: context,
        builder:(ctx)=> SimpleDialog(
          title: const Text('리뷰 정렬'),
          children:[
            SimpleDialogOption(child: const Text('추천순'), onPressed:()=>Navigator.pop(ctx,'추천순')),
            SimpleDialogOption(child: const Text('최신순'), onPressed:()=>Navigator.pop(ctx,'최신순')),
          ],
        )
    );
    if(val!=null){
      setState(()=>_reviewSort=val);
      _applyReviewSort();
    }
  }

  void _pickRatingFilter() async {
    final val = await showDialog<int>(
        context:context,
        builder:(ctx)=> SimpleDialog(
          title: const Text('별점 필터'),
          children:[
            SimpleDialogOption(child: const Text('전체'), onPressed:()=>Navigator.pop(ctx,0)),
            for(int i=1;i<=5;i++)
              SimpleDialogOption(child: Text('$i점'), onPressed:()=>Navigator.pop(ctx,i)),
          ],
        )
    );
    if(val!=null){
      setState(()=>_filterRating=(val==0)?null:val);
      _applyReviewSort();
    }
  }

  void _applyReviewSort(){
    List<Review> list=[..._reviews];
    // 별점 필터
    if(_filterRating!=null){
      list=list.where((r)=>r.rating==_filterRating).toList();
    }
    // 추천순=likes desc, 최신순= reviewId desc
    if(_reviewSort=='추천순'){
      list.sort((a,b)=>(b.likes??0).compareTo(a.likes??0));
    } else {
      list.sort((a,b)=> b.reviewId.compareTo(a.reviewId));
    }
    setState(()=>_reviews=list);
  }

  void _onSearch(String keyword){
    Navigator.pushNamed(context, '/searchResult', arguments: keyword);
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: CustomAppBar(
        isHome:false,
        onSearchSubmitted:_onSearch,
        leading: isLoggedIn
            ? IconButton(
          icon: const Icon(Icons.favorite_border),
          onPressed: _toggleFavorite,
        )
            : null,
        actions: isLoggedIn
            ? [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _goEditDoc,
          )
        ]
            : [],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:[
            if(_bread!=null) _buildBreadInfo(_bread!),
            const Divider(),
            _buildReviewSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildBreadInfo(Bread b){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:[
        if(b.imageUrl!=null)
          Image.network(b.imageUrl!),
        const SizedBox(height:8),
        Text('${b.name}  ${b.price}원', style: const TextStyle(fontSize:20, fontWeight:FontWeight.bold)),
        const SizedBox(height:4),
        Text('재고: ${b.count??0}'),
        if(b.stores!=null) ...[
          const SizedBox(height:4),
          Text('판매 지점: ${b.stores!.map((e)=>e.storeName).join(", ")}'),
        ],
        const SizedBox(height:8),
        Text('생성: ${b.createdAt??"-"} / 수정: ${b.updatedAt??"-"}'),
        const SizedBox(height:16),
        // detail: markdown
        if(b.detail!=null && b.detail!.isNotEmpty)
          Text('--- Markdown 본문 (아코디언/목차는 간단 구현 생략) ---\n${b.detail}'),
      ],
    );
  }

  Widget _buildReviewSection(){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children:[
            const Text('리뷰', style: TextStyle(fontSize:18, fontWeight:FontWeight.bold)),
            Row(
              children:[
                TextButton(
                  onPressed:_pickReviewSort,
                  child: Text('정렬: $_reviewSort'),
                ),
                TextButton(
                  onPressed:_pickRatingFilter,
                  child: Text('별점: ${_filterRating??"전체"}'),
                ),
                if(isLoggedIn)
                  ElevatedButton(
                    onPressed: ()=>_openReviewPopup(),
                    child: const Text('작성'),
                  )
              ],
            )
          ],
        ),
        const SizedBox(height:8),
        for(final rv in _reviews)
          Card(
            child: ListTile(
              leading: Text('👍${rv.likes??0}'),
              title: Text('[${rv.rating}★] ${rv.content}'),
              subtitle: Text('작성자: ${rv.userId} / ${rv.createdAt??""}'),
              trailing: IconButton(
                icon: const Icon(Icons.thumb_up_off_alt),
                onPressed: ()=>_toggleLike(rv),
              ),
              onTap:(){
                // 리뷰 작성자만 수정
                if(rv.userId==AuthService.currentUserId){
                  _openReviewPopup(existing: rv);
                }
              },
            ),
          )
      ],
    );
  }
}
