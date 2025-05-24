import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/api_constants.dart';
import 'package:flutter/material.dart';
import '../utils/api_client.dart';

class MyPageTab extends StatefulWidget {
  const MyPageTab({super.key});

  @override
  State<MyPageTab> createState() => _MyPageTabState();
}

class _MyPageTabState extends State<MyPageTab> {
  late Future<Map<String, dynamic>> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = fetchUserInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('마이페이지', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                '사용자 정보를 불러올 수 없습니다.',
                style: TextStyle(color: Colors.white),
              ),
            );
          } else if (snapshot.hasData) {
            final user = snapshot.data!;
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.person, color: Colors.white, size: 48),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user['username'] ?? '유저 이름',
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user['email'] ?? 'user@email.com',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.blue,
                    ),
                    onPressed: () {},
                    child: const Text('로그아웃'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.blue,
                    ),
                    onPressed: () {},
                    child: const Text('설정'),
                  ),
                ],
              ),
            );
          } else {
            return const Center(
              child: Text('알 수 없는 오류', style: TextStyle(color: Colors.white)),
            );
          }
        },
      ),
    );
  }
}

Future<Map<String, dynamic>> fetchUserInfo() async {
  final res = await authorizedRequest('GET', Uri.parse(ApiConstants.userInfo));
  if (res.statusCode == 200) {
    return json.decode(res.body);
  } else {
    throw Exception('사용자 정보 불러오기 실패');
  }
}
