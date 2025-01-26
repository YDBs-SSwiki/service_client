// lib/services/user_service.dart
import 'dart:developer';
import '../models/user.dart';
import 'api_client.dart';

class UserService {
  /// GET /users/{userId}
  static Future<UserInfo?> getUserInfo(int userId) async {
    try {
      final res = await ApiClient.dio.get('/users/$userId');
      return UserInfo.fromJson(res.data);
    } catch(e){
      log('getUserInfo error: $e');
      return null;
    }
  }

  /// POST /users/{userId}/update => { "newUsername":... }
  static Future<bool> updateUserNickname(int userId, String newUsername) async {
    try {
      final body = {
        "newUsername": newUsername,
      };
      final res = await ApiClient.dio.post('/users/$userId/update', data: body);
      return (res.statusCode==200);
    } catch(e){
      log('updateUserNickname error: $e');
      return false;
    }
  }

  /// GET /users/{userId}/reviews => { userId, reviews:[ ... ] }
  static Future<List<Map<String,dynamic>>> getUserReviews(int userId) async {
    try {
      final res = await ApiClient.dio.get('/users/$userId/reviews');
      final data = res.data as Map<String,dynamic>;
      final arr = data['reviews'] as List<dynamic>;
      return arr.map((e)=> e as Map<String,dynamic>).toList();
    } catch(e){
      log('getUserReviews error: $e');
      return [];
    }
  }
}
