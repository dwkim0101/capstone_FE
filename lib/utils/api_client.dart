import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'api_constants.dart';

Future<http.Response> authorizedRequest(
  String method,
  Uri url, {
  Map<String, String>? headers,
  Object? body,
  VoidCallback? onAuthFail,
}) async {
  final prefs = await SharedPreferences.getInstance();
  String? accessToken = prefs.getString('accessToken');
  headers ??= {};
  if (accessToken != null) {
    headers['Authorization'] = 'Bearer $accessToken';
  }

  print('[API] $method $url');
  if (body != null) print('[API] body: $body');
  print('[API] headers: $headers');

  http.Response response;
  switch (method) {
    case 'GET':
      response = await http.get(url, headers: headers);
      break;
    case 'POST':
      response = await http.post(url, headers: headers, body: body);
      break;
    case 'PUT':
      response = await http.put(url, headers: headers, body: body);
      break;
    case 'DELETE':
      response = await http.delete(url, headers: headers, body: body);
      break;
    default:
      throw Exception('지원하지 않는 HTTP 메서드');
  }

  print('[API] response.status: ${response.statusCode}');
  print('[API] response.body: ${response.body}');

  if (response.statusCode == 401) {
    print('[API] 401 Unauthorized. Try reissue...');
    // refreshToken을 Cookie로 전달
    final refreshToken = prefs.getString('refreshToken');
    if (refreshToken == null || refreshToken.isEmpty) {
      print('[API] refreshToken 없음. 재로그인 필요');
      if (onAuthFail != null) onAuthFail();
      throw Exception('refreshToken 없음. 다시 로그인 필요');
    }
    final reissueHeaders = {
      'Content-Type': 'application/json',
      'Cookie': 'refresh=$refreshToken',
    };
    print('[API] reissue headers: $reissueHeaders');
    final reissueRes = await http.post(
      Uri.parse(ApiConstants.reissue),
      headers: reissueHeaders,
    );
    print('[API] reissue.status: ${reissueRes.statusCode}');
    print('[API] reissue.body: ${reissueRes.body}');
    print('[API] reissue.headers: ${reissueRes.headers}');
    if (reissueRes.statusCode == 200) {
      // accessToken은 body 또는 헤더에서 추출
      String? newAccessToken;
      try {
        final data = json.decode(reissueRes.body);
        newAccessToken =
            data['accessToken'] ??
            reissueRes.headers['accessToken'] ??
            reissueRes.headers['authorization'] ??
            reissueRes.headers['access'];
      } catch (_) {
        newAccessToken =
            reissueRes.headers['accessToken'] ??
            reissueRes.headers['authorization'] ??
            reissueRes.headers['access'];
      }
      // refreshToken은 Set-Cookie에서 추출
      String? newRefreshToken;
      final setCookie = reissueRes.headers['set-cookie'];
      if (setCookie != null) {
        final reg = RegExp(r'refresh=([^;]+)');
        final match = reg.firstMatch(setCookie);
        if (match != null) {
          newRefreshToken = match.group(1);
        }
      }
      print(
        '[API] reissue accessToken: [32m${newAccessToken?.substring(0, 10)}...[0m, refreshToken: [32m${newRefreshToken?.substring(0, 10)}...[0m',
      );
      if (newAccessToken != null)
        await prefs.setString('accessToken', newAccessToken);
      if (newRefreshToken != null)
        await prefs.setString('refreshToken', newRefreshToken);
      // accessToken 갱신 후 재시도
      headers['Authorization'] = 'Bearer $newAccessToken';
      print('[API] retry $method $url');
      switch (method) {
        case 'GET':
          response = await http.get(url, headers: headers);
          break;
        case 'POST':
          response = await http.post(url, headers: headers, body: body);
          break;
        case 'PUT':
          response = await http.put(url, headers: headers, body: body);
          break;
        case 'DELETE':
          response = await http.delete(url, headers: headers, body: body);
          break;
      }
      print('[API] retry.response.status: ${response.statusCode}');
      print('[API] retry.response.body: ${response.body}');
    } else {
      print('[API] reissue failed.');
      if (onAuthFail != null) onAuthFail();
      throw Exception('토큰 만료. 다시 로그인 필요');
    }
  }
  return response;
}
