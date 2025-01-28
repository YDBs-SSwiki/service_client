// lib/widgets/popups/review_popup.dart
import 'package:flutter/material.dart';
import '../../services/review_service.dart';
import '../../services/auth_service.dart';
import '../../models/review.dart';

/// 팝업에서 리뷰 작성 or 수정
/// - existingReview가 null이면 "작성"
/// - existingReview가 있으면 "수정"
class ReviewPopup extends StatefulWidget {
  final int breadId;
  final Review? existingReview;

  const ReviewPopup({
    Key? key,
    required this.breadId,
    this.existingReview,
  }) : super(key: key);

  @override
  State<ReviewPopup> createState() => _ReviewPopupState();
}

class _ReviewPopupState extends State<ReviewPopup> {
  int _rating = 5;
  final TextEditingController _contentCtrl = TextEditingController();

  bool get isUpdate => widget.existingReview != null;

  @override
  void initState() {
    super.initState();
    if (isUpdate) {
      // 이미 작성된 리뷰 => 기존 값 로드
      _rating = widget.existingReview!.rating;
      _contentCtrl.text = widget.existingReview!.content;
    }
  }

  /// 평점 선택
  Future<void> _pickRating() async {
    final val = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('평점 선택'),
        children: [
          for (int i = 1; i <= 5; i++)
            SimpleDialogOption(
              child: Text('$i점'),
              onPressed: () => Navigator.pop(ctx, i),
            )
        ],
      ),
    );
    if (val != null) {
      setState(() => _rating = val);
    }
  }

  /// 실제 제출 로직
  Future<void> _onSubmit() async {
    final uid = AuthService.currentUserId ?? 0;
    if (uid == 0) {
      // 로그인 안 되어 있음
      Navigator.pop(context, false);
      return;
    }

    final content = _contentCtrl.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('리뷰 내용을 입력해주세요.')),
      );
      return;
    }

    bool success = false;

    if (isUpdate) {
      // 기존 리뷰 수정
      final updated = await ReviewService.updateReview(
        reviewId: widget.existingReview!.reviewId,
        breadId: widget.breadId,
        userId: uid,
        rating: _rating,
        content: content,
      );
      success = (updated != null);
    } else {
      // 새 리뷰 작성
      final created = await ReviewService.createReview(
        breadId: widget.breadId,
        userId: uid,
        rating: _rating,
        content: content,
      );
      success = (created != null);
    }

    Navigator.pop(context, success);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ★ 이미지 첨부 부분은 주석 처리/제외
            // (필요 시 multipart/form-data 로직 추가)

            Row(
              children: [
                ElevatedButton(
                  onPressed: _pickRating,
                  child: Text('평점: $_rating'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentCtrl,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: '리뷰 내용...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _onSubmit,
              child: Text(isUpdate ? '수정' : '작성'),
            )
          ],
        ),
      ),
    );
  }
}
