import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import '../../services/auth_service.dart';
import '../../services/review_service.dart';
import '../../models/review.dart';

/// 팝업에서 리뷰 작성/수정
/// - 서버에서 title 파라미터가 필수이므로 title도 입력받아 전송.
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
  /// 서버가 요구하는 "title" (문자열)
  final TextEditingController _titleCtrl = TextEditingController();

  /// 평점 & 내용
  int _rating = 5;
  final TextEditingController _contentCtrl = TextEditingController();

  // 이미지(옵션)
  String? _imagePath;
  Uint8List? _imageBytes;
  String? _imageName;

  bool get isUpdate => widget.existingReview != null;

  @override
  void initState() {
    super.initState();
    if (isUpdate) {
      // 기존 리뷰면 값 세팅
      final rv = widget.existingReview!;
      // title이 없었다면 임시로 content 일부를 넣거나, 빈 문자열
      _titleCtrl.text = '내 리뷰'; // 혹은 rv.content.substring(0, 10) 등
      _rating = rv.rating;
      _contentCtrl.text = rv.content;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      final f = result.files.first;
      _imageName = f.name;
      if (kIsWeb) {
        _imageBytes = f.bytes;
        _imagePath = null;
      } else {
        _imagePath = f.path;
        _imageBytes = null;
      }
      setState(() {});
    }
  }

  Future<void> _pickRating() async {
    final val = await showDialog<int>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('평점 선택'),
        children: [
          for (int i = 1; i <= 5; i++)
            SimpleDialogOption(child: Text('$i점'), onPressed: () => Navigator.pop(ctx, i))
        ],
      ),
    );
    if (val != null) {
      setState(() => _rating = val);
    }
  }

  /// 작성/수정 API 호출
  Future<void> _onSubmit() async {
    final uid = AuthService.currentUserId ?? 0;
    if (uid == 0) {
      Navigator.pop(context, false);
      return;
    }

    final title = _titleCtrl.text.trim();
    final content = _contentCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('제목을 입력하세요.')));
      return;
    }
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('내용을 입력하세요.')));
      return;
    }

    // MultipartFile 이미지 준비
    MultipartFile? imageFile;
    if (kIsWeb && _imageBytes != null) {
      String mimeType = 'image/png';
      final lowerName = (_imageName ?? '').toLowerCase();
      if (lowerName.endsWith('.jpg') || lowerName.endsWith('.jpeg')) {
        mimeType = 'image/jpeg';
      } else if (lowerName.endsWith('.gif')) {
        mimeType = 'image/gif';
      }
      imageFile = MultipartFile.fromBytes(
        _imageBytes!,
        filename: _imageName ?? 'review.jpg',
        contentType: MediaType.parse(mimeType),
      );
    } else if (!kIsWeb && _imagePath != null) {
      imageFile = await MultipartFile.fromFile(_imagePath!, filename: _imageName);
    }

    bool success = false;
    if (isUpdate) {
      final existing = widget.existingReview!;
      final updated = await ReviewService.updateReviewWithImage(
        reviewId: existing.reviewId,
        breadId: widget.breadId,
        userId: uid,
        rating: _rating,
        content: content,
        title: title,         // ← title 추가
        imageFile: imageFile,
      );
      success = (updated != null);
    } else {
      final created = await ReviewService.createReviewWithImage(
        breadId: widget.breadId,
        userId: uid,
        rating: _rating,
        content: content,
        title: title,         // ← title 추가
        imageFile: imageFile,
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(isUpdate ? '리뷰 수정하기' : '리뷰 작성하기', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: '제목',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                const Text('평점: '),
                ElevatedButton(
                  onPressed: _pickRating,
                  child: Text('$_rating 점'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _contentCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: '내용',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                ElevatedButton(
                  onPressed: _pickImage,
                  child: const Text('이미지 선택'),
                ),
                const SizedBox(width: 8),
                if (_imageBytes != null) Text('$_imageName (${_imageBytes!.lengthInBytes} bytes)'),
                if (_imagePath != null) Text(_imagePath!),
              ],
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
                ElevatedButton(onPressed: _onSubmit, child: Text(isUpdate ? '수정' : '작성')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
