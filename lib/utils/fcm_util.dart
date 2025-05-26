import 'package:firebase_messaging/firebase_messaging.dart';
import 'api_constants.dart';
import 'api_client.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

Future<void> getAndRegisterFcmToken() async {
  try {
    // iOS 권한 요청 및 APNS 토큰 대기
    if (Platform.isIOS) {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      // APNS 토큰이 세팅될 때까지 최대 3초(10회) 대기
      String? apnsToken;
      int retry = 0;
      while (apnsToken == null && retry < 10) {
        apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        if (apnsToken == null)
          await Future.delayed(const Duration(milliseconds: 300));
        retry++;
      }
      if (kDebugMode) print('[FCM] APNS 토큰: $apnsToken');
    }
    final fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken != null) {
      await registerFcmTokenToServer(fcmToken);
      if (kDebugMode) print('[FCM] 토큰 등록: $fcmToken');
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
    await authorizedRequest(
      'POST',
      Uri.parse('${ApiConstants.baseUrl}/login/fcmToken?fcmToken=$token'),
    );
  } catch (e) {
    if (kDebugMode) print('[FCM] 서버 등록 오류: $e');
  }
}
