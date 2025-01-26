// lib/screens/bread_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

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

  // 찜 상태
  bool _isFavorited = false; // true면 Icons.favorite, false면 Icons.favorite_border

  // 리뷰 정렬/필터
  String _reviewSort = '추천순';
  int? _filterRating;

  // Markdown headings
  final ScrollController _scrollCtrl = ScrollController();
  List<String> _headings = [];

  bool get isLoggedIn => AuthService.isLoggedIn;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// 데이터 로드: 빵 상세 + 리뷰 + 내 찜 목록 확인
  Future<void> _loadData() async {
    setState(()=>_loading=true);
    final b = await BreadService.getBreadDetail(widget.breadId);
    final r = await ReviewService.getBreadReviews(widget.breadId);

    // 빵/리뷰 세팅
    setState(() {
      _bread = b;
      _reviews = r;
      _loading = false;
    });

    // 목차(마크다운 heading) 파싱
    _parseHeadings(_bread?.detail);

    // 내 찜 목록에서 해당 breadId가 있는지 확인
    if(isLoggedIn){
      final uid = AuthService.currentUserId ?? 0;
      final favList = await FavoriteService.getUserFavorites(uid);
      final found = favList.any((f)=> f['breadId']==widget.breadId);
      setState(()=> _isFavorited = found);
    }
  }

  void _parseHeadings(String? md) {
    if(md==null){
      _headings.clear();
      return;
    }
    final lines = md.split('\n');
    _headings = [];
    for(final line in lines){
      if(line.startsWith('# ')){
        _headings.add(line.replaceFirst('# ', ''));
      } else if(line.startsWith('## ')){
        _headings.add(line.replaceFirst('## ', ''));
      }
      // 필요 시 ###, ####도
    }
  }

  /// 찜 토글 (이미 찜이면 해제, 아니면 등록)
  Future<void> _toggleFavorite() async {
    if(!isLoggedIn){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('로그인 필요')));
      return;
    }
    final uid = AuthService.currentUserId ?? 0;

    if(_isFavorited){
      // 이미 찜 => 해제 시도
      // 만약 서버에 DELETE /favorites/{breadId}?userId=xx 같은게 있다면:
      final ok = await FavoriteService.unsetFavorite(userId: uid, breadId: widget.breadId);
      if(ok){
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('찜 해제 완료')));
        setState(()=> _isFavorited=false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('찜 해제 실패/서버 API없음')));
      }
    } else {
      // 아직 찜 아님 => 등록
      final ok = await FavoriteService.setFavorite(userId: uid, breadId: widget.breadId);
      if(ok){
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('찜 완료')));
        setState(()=> _isFavorited=true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('찜 실패/중복')));
      }
    }
  }

  /// 문서 수정 팝업 => 성공시 다시 load
  Future<void> _editDoc() async {
    if(!isLoggedIn){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('로그인 필요')));
      return;
    }
    if(_bread==null) return;
    final result = await showDialog(
        context: context,
        barrierDismissible:false,
        builder:(_)=> EditBreadPopup(bread: _bread!)
    );
    if(result==true){
      await _loadData();
    }
  }

  /// 리뷰 작성/수정
  Future<void> _openReviewPopup({Review? existing}) async {
    if(!isLoggedIn){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('로그인 필요')));
      return;
    }
    final ok = await showDialog(
        context: context,
        barrierDismissible:false,
        builder:(_)=> ReviewPopup(
          breadId: widget.breadId,
          existingReview: existing,
        )
    );
    if(ok==true){
      // reload
      await _loadData();
    }
  }

  /// 리뷰 삭제
  Future<void> _deleteReview(Review rv) async {
    final ok = await ReviewService.deleteReview(rv.reviewId);
    if(ok){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('리뷰 삭제 완료')));
      await _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('리뷰 삭제 실패')));
    }
  }

  /// 좋아요 토글
  Future<void> _toggleLike(Review rv) async {
    if(!isLoggedIn){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('로그인 필요')));
      return;
    }
    if(rv.userId==AuthService.currentUserId){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('본인 리뷰는 좋아요 불가')));
      return;
    }
    final already = rv.liked==true;
    final uid = AuthService.currentUserId??0;
    final total = await ReviewService.updateReviewLike(
      reviewId: rv.reviewId,
      userId: uid,
      like: !already,
    );
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('좋아요=$total')));
    await _loadData();
  }

  /// 리뷰 정렬/필터
  void _pickReviewSort() async {
    final val = await showDialog<String>(
        context: context,
        builder:(ctx)=> SimpleDialog(
          title: const Text('리뷰 정렬'),
          children:[
            SimpleDialogOption(
              child: const Text('추천순'),
              onPressed:()=>Navigator.pop(ctx,'추천순'),
            ),
            SimpleDialogOption(
              child: const Text('최신순'),
              onPressed:()=>Navigator.pop(ctx,'최신순'),
            ),
          ],
        )
    );
    if(val!=null){
      setState(()=>_reviewSort = val);
      _applyReviewSort();
    }
  }

  void _pickRatingFilter() async {
    final val = await showDialog<int>(
        context: context,
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
      setState(()=>_filterRating = val==0? null: val);
      _applyReviewSort();
    }
  }

  void _applyReviewSort(){
    List<Review> list = [..._reviews];
    if(_filterRating!=null){
      list = list.where((r)=> r.rating==_filterRating).toList();
    }
    if(_reviewSort=='추천순'){
      list.sort((a,b)=>(b.likes??0).compareTo(a.likes??0));
    } else {
      list.sort((a,b)=> b.reviewId.compareTo(a.reviewId));
    }
    setState(()=>_reviews = list);
  }

  void _onSearch(String keyword){
    // 페이지 1개만 유지 => pushReplacementNamed
    Navigator.pushReplacementNamed(context, '/searchResult', arguments: keyword);
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: CustomAppBar(
        isHome:false,
        onSearchSubmitted:_onSearch,
        leading: null, // 상단 leading버튼 제거
        actions: const [],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        controller:_scrollCtrl,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children:[
            // 최상단: 찜/수정 버튼
            _buildTopButtons(),
            const SizedBox(height:8),
            if(_bread!=null) _buildBreadInfo(_bread!),
            const Divider(),
            _buildTOC(),
            const Divider(),
            _buildReviewSection(),
          ],
        ),
      ),
    );
  }

  /// 최상단 버튼 Row
  Widget _buildTopButtons(){
    return Row(
      children: [
        ElevatedButton.icon(
          onPressed: _toggleFavorite,
          icon: Icon(_isFavorited? Icons.favorite : Icons.favorite_border),
          label: const Text('찜'),
        ),
        const SizedBox(width:10),
        ElevatedButton.icon(
          onPressed: _editDoc,
          icon: const Icon(Icons.edit),
          label: const Text('수정'),
        )
      ],
    );
  }

  Widget _buildBreadInfo(Bread b){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:[
        // 사진 크기 제한
        if(b.imageUrl!=null)
          SizedBox(
            height:200,
            child: Image.network(
              b.imageUrl!,
              fit: BoxFit.contain,
            ),
          ),
        const SizedBox(height:8),
        Text('${b.name}  ${b.price}원',
            style: const TextStyle(fontSize:20, fontWeight:FontWeight.bold)
        ),
        const SizedBox(height:4),
        Text('재고: ${b.count??0}'),
        if(b.stores!=null && b.stores!.isNotEmpty)
          Text('판매 지점: ${b.stores!.map((e)=> e.storeName).join(", ")}'),
        const SizedBox(height:8),
        Text('생성: ${b.createdAt??"-"} / 수정: ${b.updatedAt??"-"}'),
        const SizedBox(height:16),
        if(b.detail!=null && b.detail!.isNotEmpty)
          _buildMarkdown(b.detail!)
      ],
    );
  }

  Widget _buildMarkdown(String md){
    return ExpansionPanelList(
      expansionCallback: (panelIndex, isExpanded){
        setState(()=>{/*toggle if needed*/});
      },
      children:[
        ExpansionPanel(
          headerBuilder: (_,__)=> const ListTile(title: Text('문서 내용(마크다운)')),
          body: SizedBox(
            height:300,
            child: Markdown(
              data: md,
              selectable: true,
            ),
          ),
          isExpanded: true,
        )
      ],
    );
  }

  Widget _buildTOC(){
    if(_headings.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('목차:', style: TextStyle(fontWeight: FontWeight.bold)),
        for(final h in _headings)
          InkWell(
            onTap: (){
              // 단순히 맨 위로 스크롤
              _scrollCtrl.animateTo(
                  0,
                  duration: const Duration(milliseconds:300),
                  curve: Curves.easeInOut
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical:4.0),
              child: Text('- $h', style: const TextStyle(color: Colors.blue)),
            ),
          )
      ],
    );
  }

  Widget _buildReviewSection(){
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children:[
                  IconButton(
                    icon: const Icon(Icons.thumb_up_off_alt),
                    onPressed: ()=>_toggleLike(rv),
                  ),
                  if(rv.userId==AuthService.currentUserId)
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: ()=>_deleteReview(rv),
                    )
                ],
              ),
              onTap: (){
                // 본인 리뷰 => 수정 팝업
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
