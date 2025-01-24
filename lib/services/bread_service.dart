// lib/services/bread_service.dart
import 'dart:developer';
import '../models/bread.dart';
import 'api_client.dart';

class BreadService {
  static List<Bread> allBreadsCache = [];

  // GET /bread
  static Future<void> fetchAllBreads() async {
    try {
      final res = await ApiClient.dio.get('/bread');
      final data = res.data as Map<String,dynamic>;
      final list = data['breads'] as List<dynamic>;
      allBreadsCache = list.map((e) => Bread.fromJson(e)).toList();
    } catch(e) {
      log('fetchAllBreads error: $e');
      rethrow;
    }
  }

  // GET /bread/{breadId}
  static Future<Bread> getBreadDetail(int breadId) async {
    try {
      final res = await ApiClient.dio.get('/bread/$breadId');
      return Bread.fromJson(res.data);
    } catch(e) {
      log('getBreadDetail error: $e');
      rethrow;
    }
  }

  // GET /bread/search?keyword=...
  static Future<List<Bread>> searchBreads(String keyword) async {
    try {
      final res = await ApiClient.dio.get('/bread/search', queryParameters: {"keyword": keyword});
      final data = res.data as Map<String,dynamic>;
      final list = data['searchResults'] as List<dynamic>;
      return list.map((e) => Bread.fromJson(e)).toList();
    } catch(e) {
      log('searchBreads error: $e');
      return [];
    }
  }

  static List<Bread> applySortFilter(List<Bread> breads, String sortKey, List<String> storeFilter) {
    // TODO
    return breads;
  }
}
