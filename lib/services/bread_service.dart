// lib/services/bread_service.dart
import 'dart:developer';
import 'package:dio/dio.dart';
import '../models/bread.dart';
import 'api_client.dart';

class BreadService {
  static List<Bread> allBreadsCache = [];

  /// GET /bread
  static Future<void> fetchAllBreads() async {
    try {
      final res = await ApiClient.dio.get('/bread');
      final data = res.data as Map<String,dynamic>;
      final arr = data['breads'] as List<dynamic>;
      allBreadsCache = arr.map((e)=> Bread.fromJson(e)).toList();
    } catch(e){
      log('fetchAllBreads error: $e');
      rethrow;
    }
  }

  /// GET /bread/{breadId}
  static Future<Bread> getBreadDetail(int breadId) async {
    try {
      final res = await ApiClient.dio.get('/bread/$breadId');
      return Bread.fromJson(res.data);
    } catch(e){
      rethrow;
    }
  }

  /// GET /bread/search?keyword=
  static Future<List<Bread>> searchBreads(String keyword) async {
    try {
      final res = await ApiClient.dio.get('/bread/search', queryParameters: {
        'keyword': keyword,
      });
      final data = res.data as Map<String,dynamic>;
      final arr = data['searchResults'] as List<dynamic>;
      return arr.map((e)=> Bread.fromJson(e)).toList();
    } catch(e){
      log('searchBreads error: $e');
      return [];
    }
  }

  /// POST /bread/addBread => 새 빵 생성 or 수정
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
        'storeIds': storeIds.map((i)=> i.toString()).toList(),
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

  /// 빵 문서 수정 (이미지 없이)
  /// POST /bread/{breadId}/update
  /// Body(JSON):
  /// {
  ///   "name": "부추빵",
  ///   "detail": "부추빵입니다.",
  ///   "price": 3500,
  ///   "count": 50,
  ///   "storeIds": [1, 2, 3]
  /// }
  ///
  /// 서버 응답 예(200 OK):
  /// {
  ///   "breadId": 101,
  ///   "name": "부추빵",
  ///   "detail": "부추가 들어가 맛있는 빵입니다.",
  ///   "price": 2500,
  ///   "count": 10,
  ///   "imageUrl": null,
  ///   "createdAt": "...",
  ///   "updatedAt": "..."
  /// }
  static Future<Bread?> updateBreadDocNoImage({
    required int breadId,
    required String name,
    required String detail,
    required int price,
    required int count,
    required List<int> storeIds,
  }) async {
    try {
      // JSON Body
      final body = {
        'name': name,
        'detail': detail,
        'price': price,
        'count': count,
        'storeIds': storeIds,
      };

      // "application/json" 로 전송
      final res = await ApiClient.dio.post(
        '/bread/$breadId/update',
        data: body,
        options: Options(contentType: Headers.jsonContentType),
      );

      if (res.statusCode == 200) {
        // 서버가 성공적으로 Bread 정보를 반환했다고 가정
        return Bread.fromJson(res.data);
      }
      return null;
    } catch (e) {
      log('updateBreadDocNoImage error: $e');
      return null;
    }
  }
}