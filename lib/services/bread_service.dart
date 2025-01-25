// lib/services/bread_service.dart
import 'dart:developer';
import 'package:dio/dio.dart';
import '../models/bread.dart';
import 'api_client.dart';

class BreadService {
  static List<Bread> allBreadsCache = [];

  // GET /bread
  static Future<void> fetchAllBreads() async {
    try {
      final res = await ApiClient.dio.get('/bread');
      final data = res.data as Map<String,dynamic>;
      final arr = data['breads'] as List<dynamic>;
      allBreadsCache = arr.map((e) => Bread.fromJson(e)).toList();
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
    } catch(e){
      rethrow;
    }
  }

  // GET /bread/search?keyword=...
  static Future<List<Bread>> searchBreads(String keyword) async {
    try {
      final res = await ApiClient.dio.get('/bread/search', queryParameters: {
        'keyword': keyword,
      });
      final data = res.data as Map<String,dynamic>;
      final arr = data['searchResults'] as List<dynamic>;
      return arr.map((e) => Bread.fromJson(e)).toList();
    } catch(e){
      log('searchBreads error: $e');
      return [];
    }
  }

  // POST /bread/addBread (multipart) => 새 빵 생성
  static Future<Bread?> addBread({
    required String name,
    required String detail,
    required int price,
    required int count,
    required String imageFilePath,
    required List<int> storeIds,
  }) async {
    try {
      final formData = FormData.fromMap({
        'name': name,
        'detail': detail,
        'price': price.toString(),
        'count': count.toString(),
        'storeIds': storeIds.map((i)=>i.toString()).toList(),
        'image': await MultipartFile.fromFile(imageFilePath),
      });
      final res = await ApiClient.dio.post('/bread/addBread', data: formData);
      if(res.statusCode==200){
        return Bread.fromJson(res.data);
      }
      return null;
    } catch(e){
      log('addBread error: $e');
      return null;
    }
  }

  // 예시: PUT or POST /bread/updateBread => 빵 수정
  static Future<bool> updateBread({
    required int breadId,
    required String name,
    required String detail,
    required int price,
    required int count,
    String? imageFilePath,
    required List<int> storeIds,
  }) async {
    try {
      // 실제 API가 어떻게 생겼는지 확정X, 예시
      final formData = FormData();
      formData.fields.add(MapEntry('name', name));
      formData.fields.add(MapEntry('detail', detail));
      formData.fields.add(MapEntry('price', price.toString()));
      formData.fields.add(MapEntry('count', count.toString()));
      for(final sid in storeIds){
        formData.fields.add(MapEntry('storeIds', sid.toString()));
      }
      if(imageFilePath!=null){
        formData.files.add(MapEntry(
          'image',
          await MultipartFile.fromFile(imageFilePath),
        ));
      }

      final res = await ApiClient.dio.post('/bread/updateBread/$breadId',
          data: formData);
      return res.statusCode==200;
    } catch(e){
      log('updateBread error: $e');
      return false;
    }
  }
}
