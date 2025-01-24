// lib/services/review_service.dart
import 'dart:developer';
import '../models/review.dart';
import 'api_client.dart';
import '../services/auth_service.dart';

class ReviewService {
  // GET /bread/{breadId}/reviews
  static Future<List<Review>> getBreadReviews(int breadId) async {
    try {
      final res = await ApiClient.dio.get('/bread/$breadId/reviews');
      final data = res.data as Map<String,dynamic>;
      final arr = data['reviews'] as List<dynamic>;
      return arr.map((e) => Review.fromJson(e)).toList();
    } catch(e) {
      log('getBreadReviews error: $e');
      return [];
    }
  }

  // POST /reviews
  static Future<bool> createOrUpdateReview({
    required int breadId,
    required int userId,
    required int rating,
    required String content,
  }) async {
    try {
      final body = {
        "breadId": breadId,
        "userId": userId,
        "rating": rating,
        "content": content,
      };
      final res = await ApiClient.dio.post('/reviews', data: body);
      return res.statusCode == 200;
    } catch(e) {
      log('createReview error: $e');
      return false;
    }
  }

  // POST /reviews/{reviewId}/likes
  static Future<int> updateReviewLike(int reviewId, int userId, bool like) async {
    try {
      final body = {
        "userId": userId,
        "like": like,
      };
      final res = await ApiClient.dio.post('/reviews/$reviewId/likes', data: body);
      final data = res.data as Map<String,dynamic>;
      return data['totalLikes'] as int? ?? 0;
    } catch(e) {
      log('updateReviewLike error: $e');
      return 0;
    }
  }
}
