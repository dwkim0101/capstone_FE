import 'package:flutter/material.dart';
import '../utils/api_constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'signup_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import '../utils/api_client.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  bool _keepLogin = false;

  @override
  void initState() {
    super.initState();
    _loadKeepLogin();
  }

  Future<void> _loadKeepLogin() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _keepLogin = prefs.getBool('keepLogin') ?? false;
    });
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      print('로그인 요청: \\${ApiConstants.login}');
      print(
        'body: \\${jsonEncode({'email': _emailController.text, 'password': _passwordController.text})}',
      );
      final response = await authorizedRequest(
        'POST',
        Uri.parse(ApiConstants.login),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text,
          'password': _passwordController.text,
        }),
      );
      print('응답 status: \\${response.statusCode}');
      print('응답 body: \\${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('accessToken', data['accessToken']);
          await prefs.setString('refreshToken', data['refreshToken']);
          await prefs.setBool('keepLogin', _keepLogin);
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const SmartAirHome()),
          );
        } catch (e) {
          print('로그인 후처리 에러: $e');
          setState(() {
            _error = '로그인 후처리 에러: $e';
          });
        }
      } else {
        setState(() {
          _error = '로그인 실패: \\${response.statusCode}';
        });
      }
    } catch (e) {
      print('네트워크 오류: $e');
      setState(() {
        _error = '네트워크 오류: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D1A4F), Color(0xFF23272F)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Card(
              color: const Color(0xFF23272F),
              elevation: 12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 32),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 로고
                    Image.asset('assets/logo.png', width: 80, height: 80),
                    const SizedBox(height: 16),
                    Text(
                      'SMARTAIR 로그인',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _emailController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: '이메일',
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white54),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        fillColor: Colors.white10,
                        filled: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: '비밀번호',
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white54),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        fillColor: Colors.white10,
                        filled: true,
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Checkbox(
                          value: _keepLogin,
                          onChanged: (val) {
                            setState(() {
                              _keepLogin = val ?? false;
                            });
                          },
                          activeColor: const Color(0xFF3971FF),
                          checkColor: Colors.white,
                        ),
                        const Text(
                          '로그인 유지',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                    // const SizedBox(height: 16),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Text(_error!, style: TextStyle(color: Colors.redAccent)),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3971FF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: _isLoading ? null : _login,
                        child:
                            _isLoading
                                ? SizedBox(
                                  height: 16,
                                  child: const CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                )
                                : const Text(
                                  '로그인',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SignupScreen(),
                          ),
                        );
                        if (result is Map) {
                          _emailController.text = result['email'] ?? '';
                          _passwordController.text = result['password'] ?? '';
                        }
                      },
                      child: const Text(
                        '회원가입',
                        style: TextStyle(color: Color(0xFF4FC3F7)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
