// lib/services/review_service.dart

import 'dart:developer';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import '../models/review.dart';
import 'api_client.dart';

class ReviewService {
  static Future<List<Review>> getBreadReviews(int breadId) async {
    try {
      final res = await ApiClient.dio.get('/bread/$breadId/reviews');
      final data = res.data as Map<String, dynamic>;
      final arr = data['reviews'] as List<dynamic>;
      return arr.map((e) => Review.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      log('getBreadReviews error: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> toggleReviewLike({
    required int reviewId,
    required int userId,
    required bool doLike,
  }) async {
    try {
      final body = {"userId": userId, "like": doLike};
      final res = await ApiClient.dio.post('/reviews/$reviewId/likes', data: body);

      final code = res.statusCode ?? 0;
      if (code >= 200 && code < 300) {
        // 2xx 범위면 성공
        return res.data as Map<String, dynamic>;
      }

      log('toggleReviewLike: status=$code, data=${res.data}');
      return null;
    } catch (e) {
      log('toggleReviewLike error: $e');
      return null;
    }
  }

  /// 리뷰 작성 (createReview)
  static Future<Review?> createReviewWithImage({
    required int breadId,
    required int userId,
    required int rating,
    required String content,
    String? title,
    MultipartFile? imageFile,
  }) async {
    try {
      final formData = FormData();
      formData.fields.add(MapEntry('breadId', breadId.toString()));
      formData.fields.add(MapEntry('userId', userId.toString()));
      formData.fields.add(MapEntry('rating', rating.toString()));
      formData.fields.add(MapEntry('content', content));
      if (title != null) {
        formData.fields.add(MapEntry('title', title));
      }
      if (imageFile != null) {
        formData.files.add(MapEntry('image', imageFile));
      }

      final res = await ApiClient.dio.post('/reviews/createReview', data: formData);
      final code = res.statusCode ?? 0;
      if (code >= 200 && code < 300) {
        // 2xx 범위면 성공
        return Review.fromJson(res.data as Map<String, dynamic>);
      }

      log('createReviewWithImage fail: status=$code, data=${res.data}');
      return null;
    } catch (e) {
      log('createReviewWithImage error: $e');
      return null;
    }
  }

  /// 리뷰 수정 (updateReview)
  static Future<Review?> updateReviewWithImage({
    required int reviewId,
    required int breadId,
    required int userId,
    required int rating,
    required String content,
    String? title,
    MultipartFile? imageFile,
  }) async {
    try {
      final reviewMap = {
        "breadId": breadId,
        "userId": userId,
        "rating": rating,
        "content": content,
      };
      if (title != null) {
        reviewMap["title"] = title;
      }

      final reviewJson = jsonEncode(reviewMap);
      final formData = FormData();
      formData.files.add(MapEntry(
        'review',
        MultipartFile.fromString(
          reviewJson,
          filename: 'review.json',
          contentType: MediaType('application', 'json'),
        ),
      ));
      if (imageFile != null) {
        formData.files.add(MapEntry('imageFile', imageFile));
      }

      final res = await ApiClient.dio.post('/reviews/$reviewId/update', data: formData);
      final code = res.statusCode ?? 0;
      if (code >= 200 && code < 300) {
        // 2xx 범위면 성공
        return Review.fromJson(res.data as Map<String, dynamic>);
      }

      log('updateReviewWithImage fail: status=$code, data=${res.data}');
      return null;
    } catch (e) {
      log('updateReviewWithImage error: $e');
      return null;
    }
  }

  /// 리뷰 삭제
  static Future<bool> deleteReview(int reviewId) async {
    try {
      final res = await ApiClient.dio.delete('/reviews/$reviewId');
      final code = res.statusCode ?? 0;
      if (code >= 200 && code < 300) {
        // 2xx 범위면 성공
        return true;
      } else {
        log('deleteReview fail: status=$code, data=${res.data}');
        return false;
      }
    } catch (e) {
      log('deleteReview error: $e');
      return false;
    }
  }
}
