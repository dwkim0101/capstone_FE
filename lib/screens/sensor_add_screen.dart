import 'package:flutter/material.dart';
import '../utils/api_constants.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/api_client.dart';

class SensorAddScreen extends StatefulWidget {
  final String roomId;
  const SensorAddScreen({required this.roomId, super.key});
  @override
  State<SensorAddScreen> createState() => _SensorAddScreenState();
}

class _SensorAddScreenState extends State<SensorAddScreen> {
  final _nameController = TextEditingController();
  bool _loading = false;

  Future<void> _addSensor() async {
    setState(() => _loading = true);
    final body = {
      'serialNumber': widget.roomId, // 실제 serialNumber 입력 UI 필요시 분리
      'name': _nameController.text,
    };
    await authorizedRequest(
      'POST',
      Uri.parse(ApiConstants.sensorCreate),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );
    setState(() => _loading = false);
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('센서 추가')),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: '센서 이름'),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _addSensor,
                      child: const Text('추가'),
                    ),
                  ],
                ),
              ),
    );
  }
}
