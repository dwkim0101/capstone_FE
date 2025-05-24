import 'package:flutter/material.dart';
import '../utils/api_constants.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/api_client.dart';

class DeviceAddScreen extends StatefulWidget {
  const DeviceAddScreen({super.key});
  @override
  State<DeviceAddScreen> createState() => _DeviceAddScreenState();
}

class _DeviceAddScreenState extends State<DeviceAddScreen> {
  final _nameController = TextEditingController();
  bool _loading = false;

  Future<void> _addDevice() async {
    setState(() => _loading = true);
    await authorizedRequest(
      'POST',
      Uri.parse('${ApiConstants.apiBase}/device/add'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'name': _nameController.text}),
    );
    setState(() => _loading = false);
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('기기 추가')),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: '기기 이름'),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _addDevice,
                      child: const Text('추가'),
                    ),
                  ],
                ),
              ),
    );
  }
}
