import 'package:firebase_messaging/firebase_messaging.dart';
import 'api_constants.dart';
import 'api_client.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

Future<void> getAndRegisterFcmToken() async {
  try {
    // iOS 권한 요청 및 APNS 토큰 대기
    if (Platform.isIOS) {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        if (kDebugMode) print('[FCM] 알림 권한이 거부됨');
        return;
      }
      // APNS 토큰이 세팅될 때까지 최대 3초(10회) 대기
      String? apnsToken;
      int retry = 0;
      while (apnsToken == null && retry < 10) {
        apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        if (apnsToken == null) {
          await Future.delayed(const Duration(milliseconds: 300));
        }
        retry++;
      }
      if (kDebugMode) print('[FCM] APNS 토큰: $apnsToken');
      if (apnsToken == null) {
        if (kDebugMode) print('[FCM] APNS 토큰이 끝내 발급되지 않았습니다.');
        return;
      }
    }
    final fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken != null) {
      await registerFcmTokenToServer(fcmToken);
      if (kDebugMode) print('[FCM] 토큰 등록: $fcmToken');
    } else {
      if (kDebugMode) print('[FCM] FCM 토큰 발급 실패');
    }
    // 토큰 갱신 이벤트도 등록
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      registerFcmTokenToServer(newToken);
      if (kDebugMode) print('[FCM] 토큰 갱신 등록: $newToken');
    });
  } catch (e) {
    if (kDebugMode) print('[FCM] 토큰 발급/등록 오류: $e');
  }
}

Future<void> registerFcmTokenToServer(String token) async {
  try {
    final res = await authorizedRequest(
      'POST',
      Uri.parse('${ApiConstants.baseUrl}/login/fcmToken?fcmToken=$token'),
      onAuthFail: () async {
        // accessToken 재발급 후 재시도
        if (kDebugMode) print('[FCM] accessToken 재발급 후 FCM 토큰 재등록 시도');
        await Future.delayed(const Duration(milliseconds: 300));
        await authorizedRequest(
          'POST',
          Uri.parse('${ApiConstants.baseUrl}/login/fcmToken?fcmToken=$token'),
        );
      },
    );
    if (kDebugMode) print('[FCM] 서버 등록 응답: \\${res?.statusCode}');
  } catch (e) {
    if (kDebugMode) print('[FCM] 서버 등록 오류: $e');
  }
}
