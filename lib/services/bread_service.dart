// lib/services/bread_service.dart

import 'dart:developer';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import '../models/bread.dart';
import 'api_client.dart';

class BreadService {
  static List<Bread> allBreadsCache = [];

  static Future<void> fetchAllBreads() async {
    try {
      final res = await ApiClient.dio.get('/bread');
      final data = res.data as Map<String, dynamic>;
      final arr = data['breads'] as List<dynamic>;
      allBreadsCache = arr.map((e) => Bread.fromJson(e)).toList();
    } catch (e) {
      log('fetchAllBreads error: $e');
      rethrow;
    }
  }

  static Future<Bread> getBreadDetail(int breadId) async {
    try {
      final res = await ApiClient.dio.get('/bread/$breadId');
      return Bread.fromJson(res.data);
    } catch (e) {
      log('getBreadDetail error: $e');
      rethrow;
    }
  }

  static Future<List<Bread>> searchBreads(String keyword) async {
    try {
      final res = await ApiClient.dio.get('/bread/search', queryParameters: {'keyword': keyword});
      final data = res.data as Map<String, dynamic>;
      final arr = data['searchResults'] as List<dynamic>;
      return arr.map((e) => Bread.fromJson(e)).toList();
    } catch (e) {
      log('searchBreads error: $e');
      return [];
    }
  }

  static Future<bool> addBreadAPI({
    required String name,
    required String detail,
    required int price,
    required int count,
    required List<int> storeIds,
    required MultipartFile imageFile,
  }) async {
    try {
      final formData = FormData();
      formData.fields.add(MapEntry('name', name));
      formData.fields.add(MapEntry('detail', detail));
      formData.fields.add(MapEntry('price', price.toString()));
      formData.fields.add(MapEntry('count', count.toString()));
      for (final sid in storeIds) {
        formData.fields.add(MapEntry('storeIds', sid.toString()));
      }
      formData.files.add(MapEntry('image', imageFile));

      final res = await ApiClient.dio.post('/bread/addBread', data: formData);
      return (res.statusCode == 200);
    } catch (e) {
      log('addBreadAPI error: $e');
      return false;
    }
  }

  static Future<bool> updateBreadDocWithImage({
    required int breadId,
    required String name,
    required String detail,
    required int price,
    required int count,
    required List<int> storeIds,
    MultipartFile? imageFile,
  }) async {
    try {
      final breadMap = {
        'name': name,
        'detail': detail,
        'price': price,
        'count': count,
        'storeIds': storeIds,
      };
      final breadJson = jsonEncode(breadMap);

      final breadPart = MultipartFile.fromString(
        breadJson,
        filename: 'bread.json',
        contentType: MediaType('application', 'json'),
      );

      final formData = FormData();
      formData.files.add(MapEntry('bread', breadPart));
      if (imageFile != null) {
        formData.files.add(MapEntry('imageFile', imageFile));
      }

      final res = await ApiClient.dio.post('/bread/$breadId/update', data: formData);
      return (res.statusCode == 200);
    } catch (e) {
      log('updateBreadDocWithImage error: $e');
      return false;
    }
  }
}
