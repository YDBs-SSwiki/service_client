// lib/services/favorite_service.dart
import 'dart:developer';
import 'api_client.dart';

class FavoriteService {
  // POST /favorites
  static Future<bool> setFavorite({required int userId, required int breadId}) async {
    try {
      final body = {
        "userId": userId,
        "breadId": breadId,
      };
      final res = await ApiClient.dio.post('/favorites', data: body);
      return res.statusCode==200;
    } catch(e){
      log('setFavorite error: $e');
      return false;
    }
  }

  // GET /users/{userId}/favorites
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
}
