import 'package:flutter/material.dart';
import '../utils/api_constants.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/api_client.dart';

class RoomAddScreen extends StatefulWidget {
  const RoomAddScreen({super.key});
  @override
  State<RoomAddScreen> createState() => _RoomAddScreenState();
}

class _RoomAddScreenState extends State<RoomAddScreen> {
  final _nameController = TextEditingController();
  bool _loading = false;

  Future<void> _addRoom() async {
    print('[_addRoom] POST: ${ApiConstants.roomCreate}');
    final body = {
      'name': _nameController.text,
      // 필요시 password, deviceControlEnabled, latitude, longitude 등 추가
    };
    print('[_addRoom] body: ${json.encode(body)}');
    setState(() => _loading = true);
    final res = await authorizedRequest(
      'POST',
      Uri.parse(ApiConstants.roomCreate),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );
    print('[_addRoom] status: \'${res.statusCode}\', body: ${res.body}');
    setState(() => _loading = false);
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('방 추가')),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: '방 이름'),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.blue,
                      ),
                      onPressed: _addRoom,
                      child: const Text('추가'),
                    ),
                  ],
                ),
              ),
    );
  }
}
