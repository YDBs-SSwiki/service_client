// lib/widgets/popups/review_popup.dart
import 'package:flutter/material.dart';
import '../../services/review_service.dart';
import '../../services/auth_service.dart';
import '../../models/review.dart';

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
  int _rating=5;
  final _contentCtrl = TextEditingController();

  String? _imagePath; // 선택 이미지
  bool get isUpdate => widget.existingReview!=null;

  @override
  void initState(){
    super.initState();
    if(isUpdate){
      _rating = widget.existingReview!.rating;
      _contentCtrl.text = widget.existingReview!.content;
      // 이미지 수정은 별도
    }
  }

  void _pickImage() async {
    // TODO: file picker
    setState(()=>_imagePath = null);
  }

  void _pickRating() async {
    final val = await showDialog<int>(
        context: context,
        builder:(ctx)=> SimpleDialog(
          title: const Text('평점'),
          children:[
            for(int i=1;i<=5;i++)
              SimpleDialogOption(
                child: Text('$i점'),
                onPressed: ()=> Navigator.pop(ctx,i),
              )
          ],
        )
    );
    if(val!=null){
      setState(()=> _rating=val);
    }
  }

  Future<void> _onSubmit() async {
    final uid = AuthService.currentUserId??0;
    if(uid==0){
      Navigator.pop(context,false);
      return;
    }
    final ok = await ReviewService.createOrUpdateReview(
      breadId: widget.breadId,
      userId: uid,
      rating:_rating,
      content:_contentCtrl.text,
      imagePath:_imagePath,
    );
    Navigator.pop(context, ok);
  }

  @override
  Widget build(BuildContext context){
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children:[
            Container(
              height:150,
              color: Colors.grey[300],
              child: Center(child:Text(_imagePath==null?'(이미지 없음)':_imagePath!)),
            ),
            const SizedBox(height:8),
            Row(
              children:[
                ElevatedButton(
                  onPressed: _pickImage,
                  child: const Text('사진 선택'),
                ),
                const SizedBox(width:20),
                ElevatedButton(
                  onPressed: _pickRating,
                  child: Text('평점: $_rating'),
                ),
              ],
            ),
            const SizedBox(height:16),
            TextField(
              controller:_contentCtrl,
              maxLines:5,
              decoration: const InputDecoration(
                hintText:'리뷰 내용...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height:16),
            ElevatedButton(
              onPressed: _onSubmit,
              child: Text(isUpdate?'수정':'작성'),
            )
          ],
        ),
      ),
    );
  }
}
