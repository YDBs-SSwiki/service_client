// lib/services/favorite_service.dart

import 'dart:developer';
import 'package:dio/dio.dart';
import 'api_client.dart';

class FavoriteService {
  /// POST /favorites => 찜 등록
  /// Body 예:
  /// {
  ///   "userId": 50,
  ///   "breadId": 10
  /// }
  static Future<bool> setFavorite({
    required int userId,
    required int breadId,
  }) async {
    try {
      final body = {
        "userId": userId,
        "breadId": breadId,
      };

      // 서버 응답 예 (HTTP 200):
      // {
      //   "userId": 50,
      //   "breadId": 10,
      //   "favoriteSet": true,
      //   "createdAt": "2025-01-05T11:00:00"
      // }

      final res = await ApiClient.dio.post('/favorites', data: body);
      return (res.statusCode == 200);
    } catch (e) {
      log('setFavorite error: $e');
      return false;
    }
  }

  /// GET /users/{userId}/favorites
  /// 서버 응답 예 (배열):
  /// [
  ///   {
  ///     "userId":1,
  ///     "favorites":[
  ///       {"breadId":2,"name":"소보로빵"},
  ///       {"breadId":3,"name":"부추빵"}
  ///     ]
  ///   }
  /// ]
  static Future<List<Map<String, dynamic>>> getUserFavorites(int userId) async {
    try {
      final res = await ApiClient.dio.get('/users/$userId/favorites');
      final list = res.data as List<dynamic>;
      if (list.isEmpty) {
        return [];
      }
      final firstObj = list[0] as Map<String, dynamic>;
      final favArr = firstObj['favorites'] as List<dynamic>? ?? [];
      return favArr.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      log('getUserFavorites error: $e');
      return [];
    }
  }

  /// DELETE /favorites/delete => 찜 해제
  /// Body 예:
  /// {
  ///   "userId": 50,
  ///   "breadId": 10
  /// }
  ///
  /// 성공 시 (200 OK):
  /// { "message": "찜이 성공적으로 삭제되었습니다." }
  static Future<bool> unsetFavorite({
    required int userId,
    required int breadId,
  }) async {
    try {
      final body = {
        "userId": userId,
        "breadId": breadId,
      };

      // DELETE 메서드이지만, 여기서는 body를 함께 전송
      final res = await ApiClient.dio.delete(
        '/favorites/delete',
        data: body,
      );
      return (res.statusCode == 200);
    } catch (e) {
      log('unsetFavorite error: $e');
      return false;
    }
  }
}
