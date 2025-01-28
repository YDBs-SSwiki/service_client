// lib/services/api_client.dart

import 'package:dio/dio.dart';
import 'dart:developer';
// 아래 두 개는 'kIsWeb' 판별용, 'BrowserHttpClientAdapter' 불러오기용
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio/browser.dart' show BrowserHttpClientAdapter;

class ApiClient {
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: 'https://physically-legible-bengal.ngrok-free.app',
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
      headers: {
        'ngrok-skip-browser-warning': '69420',
      },
    ),
  );

  /// 서버 세션 쿠키(JSESSIONID 등)를 보관할 변수
  static String? sessionCookie;

  /// 인터셉터 초기화 (앱 시작 시 1회 호출)
  static void initInterceptors() {
    // (1) 웹 환경이라면 withCredentials = true 설정
    if (kIsWeb) {
      final httpAdapter = dio.httpClientAdapter;
      if (httpAdapter is BrowserHttpClientAdapter) {
        httpAdapter.withCredentials = true;
        log('BrowserHttpClientAdapter.withCredentials = true 설정 완료');
      }
    }

    // (2) 기존 인터셉터
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // 요청 보낼 때: sessionCookie가 있으면 헤더 Cookie에 넣는다
          if (sessionCookie != null && sessionCookie!.isNotEmpty) {
            options.headers['Cookie'] = sessionCookie;
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          // 응답에서 Set-Cookie 헤더가 있으면 sessionCookie 저장
          final setCookie = response.headers['set-cookie'];
          if (setCookie != null && setCookie.isNotEmpty) {
            // 예: ["JSESSIONID=ABCD1234; Path=/; HttpOnly"]
            final rawCookie = setCookie.first;
            // 세미콜론 전까지만 잘라서 "JSESSIONID=ABCD1234"
            final cookiePart = rawCookie.split(';').first;

            // 여기서 바로 로그로 출력
            log('====== 세션 쿠키 저장됨: $cookiePart ======');

            // sessionCookie 변수에 보관
            sessionCookie = cookiePart;
          }
          return handler.next(response);
        },
        onError: (error, handler) {
          return handler.next(error);
        },
      ),
    );
  }
}
