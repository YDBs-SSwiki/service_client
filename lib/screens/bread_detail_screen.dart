// lib/screens/bread_detail_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/bread_service.dart';
import '../services/review_service.dart';
import '../services/favorite_service.dart';
import '../models/bread.dart';
import '../models/review.dart';
import '../widgets/common/custom_appbar.dart';
import '../widgets/popups/review_popup.dart';

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
  List<Review> _reviews=[];
  bool _loading=true;

  String _reviewSort='추천순';
  int? _filterRating;

  bool get isLoggedIn => AuthService.isLoggedIn;

  @override
  void initState(){
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final b = await BreadService.getBreadDetail(widget.breadId);
    final r = await ReviewService.getBreadReviews(widget.breadId);
    setState(() {
      _bread = b;
      _reviews = r;
      _loading=false;
    });
  }

  void _toggleFavorite() async {
    if(!isLoggedIn) return;
    final uid = AuthService.currentUserId??0;
    final ok = await FavoriteService.setFavorite(userId: uid, breadId: widget.breadId);
    if(ok){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('찜 완료')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('찜 실패')));
    }
  }

  void _goEditDoc() {
    // TODO: 편집(POST /bread/addBread?) or update?
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('편집 기능 미구현')));
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
      _loadAll();
    }
  }

  void _toggleLike(Review rv) async {
    if(!isLoggedIn){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('로그인 필요')));
      return;
    }
    final uid = AuthService.currentUserId??0;
    final newLikes = await ReviewService.updateReviewLike(rv.reviewId, uid, true);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('좋아요=$newLikes')));
    _loadAll();
  }

  void _pickReviewSort() async {
    final newVal = await showDialog<String>(
        context: context,
        builder:(ctx)=> SimpleDialog(
          title: const Text('리뷰 정렬'),
          children: [
            SimpleDialogOption(child: const Text('추천순'), onPressed:()=>Navigator.pop(ctx,'추천순')),
            SimpleDialogOption(child: const Text('최신순'), onPressed:()=>Navigator.pop(ctx,'최신순')),
          ],
        )
    );
    if(newVal!=null){
      setState(()=>_reviewSort=newVal);
      _applyReviewSort();
    }
  }

  void _pickRatingFilter() async {
    final newVal = await showDialog<int>(
        context:context,
        builder:(ctx)=> SimpleDialog(
          title: const Text('별점 필터'),
          children: [
            SimpleDialogOption(child: const Text('전체'), onPressed:()=>Navigator.pop(ctx,0)),
            for(int i=1;i<=5;i++)
              SimpleDialogOption(child: Text('$i점'), onPressed:()=>Navigator.pop(ctx,i)),
          ],
        )
    );
    if(newVal!=null){
      setState(()=>_filterRating=(newVal==0)?null:newVal);
      _applyReviewSort();
    }
  }

  void _applyReviewSort(){
    List<Review> list=[..._reviews];
    if(_filterRating!=null){
      list=list.where((r)=>r.rating==_filterRating).toList();
    }
    if(_reviewSort=='추천순'){
      list.sort((a,b)=>b.likes.compareTo(a.likes));
    } else {
      // 최신순 => b.reviewId-a.reviewId
      list.sort((a,b)=> b.reviewId.compareTo(a.reviewId));
    }
    setState(()=>_reviews=list);
  }

  void _onSearch(String val){
    Navigator.pushNamed(context, '/searchResult', arguments: val);
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: CustomAppBar(
        isHome:false,
        onSearchSubmitted: _onSearch,
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
            onPressed:_goEditDoc,
          ),
        ]
            : [],
      ),
      body: _loading
          ? const Center(child:CircularProgressIndicator())
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
      children: [
        if(b.imageUrl!=null)
          Image.network(b.imageUrl!),
        const SizedBox(height:8),
        Text('${b.name}  ${b.price}원', style: const TextStyle(fontSize:20, fontWeight:FontWeight.bold)),
        const SizedBox(height:4),
        Text(b.detail),
        const SizedBox(height:16),
        const Text('위키 내용...'),
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
                  onPressed: _pickReviewSort,
                  child: Text('정렬: $_reviewSort'),
                ),
                TextButton(
                  onPressed: _pickRatingFilter,
                  child: Text('별점: ${_filterRating??"전체"}'),
                ),
                if(isLoggedIn)
                  ElevatedButton(
                    onPressed: ()=>_openReviewPopup(),
                    child: const Text('작성'),
                  ),
              ],
            )
          ],
        ),
        const SizedBox(height:8),
        for(final rv in _reviews)
          Card(
            child: ListTile(
              leading: rv.likes>0 ? Text('👍${rv.likes}') : const Text('👍0'),
              title: Text('[${rv.rating}★] ${rv.content}'),
              subtitle: Text('작성자: ${rv.userId}'),
              trailing: IconButton(
                icon: const Icon(Icons.thumb_up_off_alt),
                onPressed: ()=>_toggleLike(rv),
              ),
              onTap: (){
                // 수정
                if(rv.userId==AuthService.currentUserId){
                  _openReviewPopup(existing: rv);
                }
              },
            ),
          ),
      ],
    );
  }
}
