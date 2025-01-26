// lib/services/favorite_service.dart
import 'dart:developer';
import 'package:dio/dio.dart';
import 'api_client.dart';

class FavoriteService {
  /// POST /favorites => 찜 등록
  static Future<bool> setFavorite({required int userId, required int breadId}) async {
    try {
      final body = {
        "userId": userId,
        "breadId": breadId,
      };
      final res = await ApiClient.dio.post('/favorites', data: body);
      return (res.statusCode==200);
    } catch(e){
      log('setFavorite error: $e');
      return false;
    }
  }

  /// GET /users/{userId}/favorites => [{breadId, name}, ...]
  static Future<List<Map<String,dynamic>>> getUserFavorites(int userId) async {
    try {
      final res = await ApiClient.dio.get('/users/$userId/favorites');
      final data = res.data as Map<String,dynamic>;
      final arr = data['favorites'] as List<dynamic>;
      return arr.map((e)=> e as Map<String,dynamic>).toList();
    } catch(e){
      log('getUserFavorites error: $e');
      return [];
    }
  }

  /// (추가) DELETE /favorites/{breadId}?userId=xxx => 찜 해제
  /// 실제 서버 구현이 없을 수도 있으니 참고
  static Future<bool> unsetFavorite({required int userId, required int breadId}) async {
    try {
      final res = await ApiClient.dio.delete(
          '/favorites/$breadId',
          queryParameters: {'userId': userId}
      );
      return (res.statusCode==200);
    } catch(e){
      log('unsetFavorite error: $e');
      return false;
    }
  }
}
