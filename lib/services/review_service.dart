// lib/services/review_service.dart

import 'dart:developer';
import 'package:dio/dio.dart';
import '../models/review.dart';
import 'api_client.dart';

class ReviewService {
  /// GET /bread/{breadId}/reviews
  /// 서버 응답 예:
  /// {
  ///   "breadId": 10,
  ///   "reviews": [
  ///     {
  ///       "reviewId":101,
  ///       "userId":50,
  ///       "rating":5,
  ///       "content":"정말 맛있어요!",
  ///       "likes":10,
  ///       "createdAt":"2025-01-05T11:30:00"
  ///     }, ...
  ///   ]
  /// }
  static Future<List<Review>> getBreadReviews(int breadId) async {
    try {
      final res = await ApiClient.dio.get('/bread/$breadId/reviews');
      final data = res.data as Map<String, dynamic>;

      final arr = data['reviews'] as List<dynamic>;
      // Review 모델로 변환
      final list = arr.map((e) => Review.fromJson(e as Map<String, dynamic>)).toList();
      return list;
    } catch (e) {
      log('getBreadReviews error: $e');
      return [];
    }
  }

  /// POST /reviews (새 리뷰 작성)
  /// RequestParam:
  ///   - breadId, userId, rating, content, (image?) ...
  /// 서버가 JSON body가 아닌 FormData나 RequestParam 방식을 요구한다면 주의 필요.
  static Future<Review?> createReview({
    required int breadId,
    required int userId,
    required int rating,
    required String content,
  }) async {
    try {
      // 일단 JSON body로 보낸다고 가정 (만약 서버가 RequestParam이라면 queryParameters로 보낼 수도 있음)
      final body = {
        "breadId": breadId,
        "userId": userId,
        "rating": rating,
        "content": content,
      };

      final res = await ApiClient.dio.post('/reviews', data: body);
      if (res.statusCode == 200) {
        final json = res.data as Map<String, dynamic>;
        return Review.fromJson(json);
      }
      return null;
    } catch (e) {
      log('createReview error: $e');
      return null;
    }
  }

  /// POST /reviews/{reviewId}/update (기존 리뷰 수정)
  /// Body(JSON):
  /// {
  ///   "breadId": 1,
  ///   "userId": 2,
  ///   "rating": 5,
  ///   "content": "맛있고 바삭해요!"
  /// }
  static Future<Review?> updateReview({
    required int reviewId,
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
      final res = await ApiClient.dio.post('/reviews/$reviewId/update', data: body);
      if (res.statusCode == 200) {
        final json = res.data as Map<String, dynamic>;
        return Review.fromJson(json);
      }
      return null;
    } catch (e) {
      log('updateReview error: $e');
      return null;
    }
  }

  /// DELETE /reviews/{reviewId} (리뷰 삭제)
  static Future<bool> deleteReview(int reviewId) async {
    try {
      final res = await ApiClient.dio.delete('/reviews/$reviewId');
      return (res.statusCode == 200);
    } catch (e) {
      log('deleteReview error: $e');
      return false;
    }
  }
}
