import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../services/bread_service.dart';
import '../services/review_service.dart';
import '../services/favorite_service.dart';
import '../services/auth_service.dart';

import '../models/bread.dart';
import '../models/review.dart';

import '../widgets/common/custom_appbar.dart';
import '../widgets/popups/edit_bread_popup.dart';
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
  List<Review> _reviews = [];
  Review? _myReview;
  bool _loading = true;
  bool _isFavorited = false;

  String _searchKeyword = '';
  List<Bread> _suggestionBreads = [];

  // 리뷰 정렬/필터
  String _reviewSort = '추천순';
  int? _filterRating;

  // Markdown 목차
  final ScrollController _scrollCtrl = ScrollController();
  List<String> _headings = [];

  bool get isLoggedIn => AuthService.isLoggedIn;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    // 빵 상세
    final b = await BreadService.getBreadDetail(widget.breadId);

    // 리뷰 목록
    final r = await ReviewService.getBreadReviews(widget.breadId);

    // 찜 여부
    bool fav = false;
    if (isLoggedIn) {
      final uid = AuthService.currentUserId ?? 0;
      final favList = await FavoriteService.getUserFavorites(uid);
      fav = favList.any((f) => f['breadId'] == widget.breadId);
    }

    // 내 리뷰 찾기
    Review? mine;
    if (isLoggedIn) {
      final uid = AuthService.currentUserId ?? 0;
      final found = r.where((rv) => rv.userId == uid).toList();
      if (found.isNotEmpty) mine = found.first;
    }

    setState(() {
      _bread = b;
      _reviews = r;
      _isFavorited = fav;
      _myReview = mine;
      _loading = false;
    });

    _parseHeadings(b?.detail);
  }

  void _parseHeadings(String? md) {
    if (md == null) {
      _headings.clear();
      return;
    }
    final lines = md.split('\n');
    _headings = [];
    for (final line in lines) {
      if (line.startsWith('# ')) {
        _headings.add(line.replaceFirst('# ', ''));
      } else if (line.startsWith('## ')) {
        _headings.add(line.replaceFirst('## ', ''));
      }
    }
  }

  // ────────────────────────── 검색/자동완성 ──────────────────────────
  Future<void> _onSearchTextChanged(String keyword) async {
    setState(() => _searchKeyword = keyword.trim());
    if (_searchKeyword.isEmpty) {
      setState(() => _suggestionBreads = []);
      return;
    }
    final results = await BreadService.searchBreads(_searchKeyword);
    setState(() => _suggestionBreads = results);
  }

  void _onSearch(String keyword) {
    Navigator.pushReplacementNamed(context, '/searchResult', arguments: keyword);
  }

  // ────────────────────────── 찜 토글 ──────────────────────────
  Future<void> _toggleFavorite() async {
    if (!isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('로그인 필요')));
      return;
    }
    final uid = AuthService.currentUserId ?? 0;
    if (_isFavorited) {
      // 해제
      final ok = await FavoriteService.unsetFavorite(userId: uid, breadId: widget.breadId);
      if (ok) {
        setState(() => _isFavorited = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('찜 해제 완료')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('찜 해제 실패')));
      }
    } else {
      // 등록
      final ok = await FavoriteService.setFavorite(userId: uid, breadId: widget.breadId);
      if (ok) {
        setState(() => _isFavorited = true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('찜 완료')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('찜 실패')));
      }
    }
  }

  // ────────────────────────── 빵 문서 수정 ──────────────────────────
  Future<void> _editDoc() async {
    if (!isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('로그인 필요')));
      return;
    }
    if (_bread == null) return;
    final result = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => EditBreadPopup(bread: _bread!),
    );
    if (result == true) {
      await _loadData(); // 수정 후 다시 로딩
    }
  }

  // ────────────────────────── 리뷰 작성/수정 ──────────────────────────
  Future<void> _openReviewPopup() async {
    if (!isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('로그인 필요')));
      return;
    }
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ReviewPopup(
        breadId: widget.breadId,
        existingReview: _myReview,
      ),
    );
    if (result == true) {
      // 작성/수정 성공 -> 다시 로딩
      await _loadData();
    }
  }

  // ────────────────────────── 리뷰 삭제 ──────────────────────────
  Future<void> _deleteReview(Review rv) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('리뷰 삭제'),
        content: const Text('정말 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final ok = await ReviewService.deleteReview(rv.reviewId);
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('리뷰 삭제 완료')));
        await _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('리뷰 삭제 실패')));
      }
    }
  }

  // ────────────────────────── 좋아요 토글 ──────────────────────────
  Future<void> _toggleReviewLike(Review rv) async {
    if (!isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('로그인 필요')));
      return;
    }
    final uid = AuthService.currentUserId ?? 0;
    final doLike = !(rv.liked ?? false);

    final result = await ReviewService.toggleReviewLike(
      reviewId: rv.reviewId,
      userId: uid,
      doLike: doLike,
    );
    if (result != null) {
      final updatedLiked = result['liked'] as bool?;
      final updatedLikes = result['totalLikes'] as int?;
      setState(() {
        for (int i = 0; i < _reviews.length; i++) {
          if (_reviews[i].reviewId == rv.reviewId) {
            _reviews[i] = Review(
              reviewId: rv.reviewId,
              breadId: rv.breadId,
              userId: rv.userId,
              rating: rv.rating,
              content: rv.content,
              createdAt: rv.createdAt,
              likes: updatedLikes,
              liked: updatedLiked,
              imageUrl: rv.imageUrl,
            );
            break;
          }
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('좋아요 처리 실패')));
    }
  }

  // ────────────────────────── 리뷰 정렬/필터 ──────────────────────────
  void _pickReviewSort() async {
    final val = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('리뷰 정렬'),
        children: [
          SimpleDialogOption(
            child: const Text('추천순'),
            onPressed: () => Navigator.pop(ctx, '추천순'),
          ),
          SimpleDialogOption(
            child: const Text('최신순'),
            onPressed: () => Navigator.pop(ctx, '최신순'),
          ),
        ],
      ),
    );
    if (val != null) {
      setState(() => _reviewSort = val);
      _applyReviewSort();
    }
  }

  void _pickRatingFilter() async {
    final val = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('별점 필터'),
        children: [
          SimpleDialogOption(child: const Text('전체'), onPressed: () => Navigator.pop(ctx, 0)),
          for (int i = 1; i <= 5; i++)
            SimpleDialogOption(child: Text('$i점'), onPressed: () => Navigator.pop(ctx, i)),
        ],
      ),
    );
    if (val != null) {
      setState(() => _filterRating = val == 0 ? null : val);
      _applyReviewSort();
    }
  }

  void _applyReviewSort() {
    List<Review> list = [..._reviews];
    if (_filterRating != null) {
      list = list.where((r) => r.rating == _filterRating).toList();
    }
    if (_reviewSort == '추천순') {
      list.sort((a, b) => (b.likes ?? 0).compareTo(a.likes ?? 0));
    } else {
      list.sort((a, b) => b.reviewId.compareTo(a.reviewId));
    }
    setState(() => _reviews = list);
  }

  // ────────────────────────── UI build ──────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        isHome: false,
        onSearchSubmitted: _onSearch,
        onSearchChanged: _onSearchTextChanged,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        controller: _scrollCtrl,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_searchKeyword.isNotEmpty) _buildSuggestions(),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _toggleFavorite,
                  icon: Icon(_isFavorited ? Icons.favorite : Icons.favorite_border),
                  label: const Text('찜'),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: _editDoc,
                  icon: const Icon(Icons.edit),
                  label: const Text('수정'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_bread != null) _buildBreadInfo(_bread!),
            const Divider(),
            _buildTOC(),
            const Divider(),
            _buildReviewSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestions() {
    if (_suggestionBreads.isEmpty) {
      return Container(
        color: Colors.orange[50],
        height: 40,
        child: const Center(child: Text('검색 결과가 없습니다')),
      );
    }
    return Container(
      color: Colors.orange[50],
      height: 100,
      child: ListView.builder(
        itemCount: _suggestionBreads.length,
        itemBuilder: (ctx, i) {
          final bread = _suggestionBreads[i];
          return InkWell(
            onTap: () {
              Navigator.pushReplacementNamed(context, '/breadDetail', arguments: bread.breadId);
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(bread.name, style: const TextStyle(color: Colors.blue)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBreadInfo(Bread b) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (b.imageUrl != null)
          SizedBox(
            height: 200,
            child: Image.network(b.imageUrl!, fit: BoxFit.contain),
          ),
        const SizedBox(height: 8),
        Text('${b.name}  ${b.price}원', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('재고: ${b.count ?? 0}'),
        if (b.stores != null && b.stores!.isNotEmpty)
          Text('판매 지점: ${b.stores!.map((s) => s.storeName).join(", ")}'),
        const SizedBox(height: 8),
        Text('생성: ${b.createdAt ?? "-"} / 수정: ${b.updatedAt ?? "-"}'),
        const SizedBox(height: 16),
        if (b.detail != null && b.detail!.isNotEmpty) _buildMarkdown(b.detail!)
      ],
    );
  }

  Widget _buildMarkdown(String md) {
    return ExpansionPanelList(
      expansionCallback: (panelIndex, isExpanded) {
        setState(() {});
      },
      children: [
        ExpansionPanel(
          headerBuilder: (_, __) => const ListTile(title: Text('문서 내용(마크다운)')),
          body: SizedBox(
            height: 300,
            child: Markdown(data: md, selectable: true),
          ),
          isExpanded: true,
        )
      ],
    );
  }

  Widget _buildTOC() {
    if (_headings.isEmpty) {
      return const SizedBox();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('목차:', style: TextStyle(fontWeight: FontWeight.bold)),
        for (final h in _headings)
          InkWell(
            onTap: () {
              _scrollCtrl.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Text('- $h', style: const TextStyle(color: Colors.blue)),
            ),
          )
      ],
    );
  }

  /// 좋아요 버튼 & 좋아요 수가 함께 보이도록 수정
  Widget _buildReviewSection() {
    final myId = AuthService.currentUserId ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 상단
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('리뷰', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Row(
              children: [
                TextButton(
                  onPressed: _pickReviewSort,
                  child: Text('정렬: $_reviewSort'),
                ),
                TextButton(
                  onPressed: _pickRatingFilter,
                  child: Text('별점: ${_filterRating ?? "전체"}'),
                ),
                ElevatedButton(
                  onPressed: _openReviewPopup,
                  child: Text(_myReview == null ? '작성' : '수정'),
                ),
              ],
            )
          ],
        ),
        const SizedBox(height: 8),

        // 리뷰 카드 목록
        for (final rv in _reviews)
          Card(
            child: ListTile(
              title: Text('[${rv.rating}★] ${rv.content}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('작성자: ${rv.userId} / ${rv.createdAt ?? ""}'),
                  if (rv.imageUrl != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Image.network(rv.imageUrl!, height: 80, fit: BoxFit.cover),
                    ),
                ],
              ),
              // 오른쪽에 "따봉 아이콘 + 좋아요 수" / "삭제 버튼(내 리뷰인 경우)"
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 좋아요 버튼
                  IconButton(
                    icon: Icon((rv.liked ?? false) ? Icons.thumb_up : Icons.thumb_up_outlined),
                    onPressed: () => _toggleReviewLike(rv),
                  ),
                  // 좋아요 수
                  Text('${rv.likes ?? 0}'),
                  // 내 리뷰면 삭제
                  if (rv.userId == myId)
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.grey),
                      onPressed: () => _deleteReview(rv),
                    ),
                ],
              ),
            ),
          )
      ],
    );
  }
}
