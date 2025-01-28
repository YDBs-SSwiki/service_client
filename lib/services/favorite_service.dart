// lib/services/favorite_service.dart

import 'dart:developer';
import 'package:dio/dio.dart';
import 'api_client.dart';

class FavoriteService {
  static Future<bool> setFavorite({required int userId, required int breadId}) async {
    try {
      final body = {"userId": userId, "breadId": breadId};
      final res = await ApiClient.dio.post('/favorites', data: body);
      return (res.statusCode == 200);
    } catch (e) {
      log('setFavorite error: $e');
      return false;
    }
  }

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

  static Future<bool> unsetFavorite({required int userId, required int breadId}) async {
    try {
      final body = {"userId": userId, "breadId": breadId};
      final res = await ApiClient.dio.delete('/favorites/delete', data: body);
      return (res.statusCode == 200);
    } catch (e) {
      log('unsetFavorite error: $e');
      return false;
    }
  }
}
