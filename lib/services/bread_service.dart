import 'dart:convert'; // for jsonEncode
import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart'; // for MediaType
import '../models/bread.dart';
import 'api_client.dart';

class BreadService {
  static List<Bread> allBreadsCache = [];

  /// GET /bread
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

  /// GET /bread/{breadId}
  static Future<Bread> getBreadDetail(int breadId) async {
    try {
      final res = await ApiClient.dio.get('/bread/$breadId');
      return Bread.fromJson(res.data);
    } catch (e) {
      rethrow;
    }
  }

  /// GET /bread/search?keyword=
  static Future<List<Bread>> searchBreads(String keyword) async {
    try {
      final res = await ApiClient.dio.get(
        '/bread/search',
        queryParameters: {
          'keyword': keyword,
        },
      );
      final data = res.data as Map<String, dynamic>;
      final arr = data['searchResults'] as List<dynamic>;
      return arr.map((e) => Bread.fromJson(e)).toList();
    } catch (e) {
      log('searchBreads error: $e');
      return [];
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // (1) 새 빵 등록: /bread/addBread
  //     서버는 @RequestParam("name"),("detail"),("price"),("count"),("storeIds"),("image")
  //     ⇒ 클라이언트는 FormData로 'name','detail','price','count','storeIds' 등
  //        + 파일 파트("image")
  // ─────────────────────────────────────────────────────────────────────
  static Future<bool> addBreadAPI({
    required String name,
    required String detail,
    required int price,
    required int count,
    required List<int> storeIds,
    required MultipartFile imageFile, // 파일 파트 이름 = "image"
  }) async {
    try {
      // FormData 개별 필드로 구성
      // 서버 @RequestParam("...") => name, detail, price, count, storeIds, image
      final formData = FormData();

      // 1) text fields (String)
      formData.fields.add(MapEntry('name', name));
      formData.fields.add(MapEntry('detail', detail));
      formData.fields.add(MapEntry('price', price.toString()));
      formData.fields.add(MapEntry('count', count.toString()));
      // storeIds (List<Integer>) => 보통 Spring에서 [storeIds=1, storeIds=2, ...] 형태
      // 간단히 아래처럼:
      for (final sid in storeIds) {
        formData.fields.add(MapEntry('storeIds', sid.toString()));
      }

      // 2) image => 파일 파트
      // ★ imageFile 자체가 이미 contentType을 가질 수 있음
      formData.files.add(MapEntry('image', imageFile));

      // 3) 전송
      final res = await ApiClient.dio.post(
        '/bread/addBread',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data', // multipart
        ),
      );

      return (res.statusCode == 200);
    } catch (e) {
      log('addBreadAPI error: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // (2) 기존 빵 수정: /bread/{breadId}/update
  //     서버는 @RequestPart("bread") UpdateBreadRequestDTO, @RequestPart("imageFile", required=false)
  // ─────────────────────────────────────────────────────────────────────
  static Future<bool> updateBreadDocWithImage({
    required int breadId,
    required String name,
    required String detail,
    required int price,
    required int count,
    required List<int> storeIds,
    MultipartFile? imageFile, // optional
  }) async {
    try {
      // (A) JSON -> "bread" 파트
      final breadMap = {
        'name': name,
        'detail': detail,
        'price': price,
        'count': count,
        'storeIds': storeIds,
      };
      final breadString = jsonEncode(breadMap);

      // ★ multipart/form-data에서 "bread"를 Content-Type: application/json으로
      //   보내고 싶다면, MultipartFile.fromString(...) 사용
      final breadPart = MultipartFile.fromString(
        breadString,
        filename: 'bread.json',
        contentType: MediaType('application', 'json'),
      );

      // (B) FormData
      final formData = FormData();

      // "bread" 파트 (JSON, application/json)
      formData.files.add(MapEntry('bread', breadPart));

      // "imageFile" 파트 (파일, optional)
      if (imageFile != null) {
        formData.files.add(MapEntry('imageFile', imageFile));
      }

      // (C) POST
      final res = await ApiClient.dio.post(
        '/bread/$breadId/update',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data', // multipart
        ),
      );
      return (res.statusCode == 200);
    } catch (e) {
      log('updateBreadDocWithImage error: $e');
      return false;
    }
  }
}
