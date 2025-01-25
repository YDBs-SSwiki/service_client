// lib/services/review_service.dart
import 'dart:developer';
import 'package:dio/dio.dart';
import '../models/review.dart';
import 'api_client.dart';

class ReviewService {
  // GET /bread/{breadId}/reviews
  static Future<List<Review>> getBreadReviews(int breadId) async {
    try {
      final res = await ApiClient.dio.get('/bread/$breadId/reviews');
      final data = res.data as Map<String,dynamic>;
      final arr = data['reviews'] as List<dynamic>;
      return arr.map((e)=>Review.fromJson(e)).toList();
    } catch(e){
      log('getBreadReviews error: $e');
      return [];
    }
  }

  // POST /reviews => 리뷰 생성/수정 (multipart)
  static Future<bool> createOrUpdateReview({
    required int breadId,
    required int userId,
    required int rating,
    required String content,
    String? imagePath,
  }) async {
    try {
      final formData = FormData.fromMap({
        'breadId': breadId.toString(),
        'userId': userId.toString(),
        'rating': rating.toString(),
        'content': content,
      });
      if(imagePath!=null){
        formData.files.add(MapEntry(
          'image',
          await MultipartFile.fromFile(imagePath),
        ));
      }

      final res = await ApiClient.dio.post('/reviews', data: formData);
      return res.statusCode==200;
    } catch(e){
      log('createReview error: $e');
      return false;
    }
  }

  // POST /reviews/{reviewId}/likes => { userId, like:true/false }
  static Future<int> updateReviewLike({
    required int reviewId,
    required int userId,
    required bool like,
  }) async {
    try {
      final body = {
        'userId': userId,
        'like': like,
      };
      final res = await ApiClient.dio.post('/reviews/$reviewId/likes', data: body);
      final data = res.data as Map<String,dynamic>;
      return data['totalLikes']??0;
    } catch(e){
      log('updateReviewLike error: $e');
      return 0;
    }
  }

  // DELETE /reviews/{reviewId}
  static Future<bool> deleteReview(int reviewId) async {
    try {
      final res = await ApiClient.dio.delete('/reviews/$reviewId');
      return res.statusCode==200;
    } catch(e){
      log('deleteReview error: $e');
      return false;
    }
  }
}
