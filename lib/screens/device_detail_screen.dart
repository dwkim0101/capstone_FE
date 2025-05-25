import 'package:flutter/material.dart';
import '../utils/api_constants.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/api_client.dart';
import '../models/device.dart';

class DeviceDetailScreen extends StatefulWidget {
  final Device device;
  const DeviceDetailScreen({required this.device, super.key});
  @override
  State<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends State<DeviceDetailScreen> {
  late bool isActive;
  late TextEditingController _nameController;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    isActive = widget.device.isActive ?? false;
    _nameController = TextEditingController(text: widget.device.name);
  }

  Future<void> _toggleDevice() async {
    print(
      '[_toggleDevice] POST: '
      '${ApiConstants.deviceControl}',
    );
    print(
      '[_toggleDevice] body: \\${json.encode({'id': widget.device.id, 'on': !isActive})}',
    );
    setState(() => _loading = true);
    final res = await authorizedRequest(
      'POST',
      Uri.parse(ApiConstants.deviceControl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'id': widget.device.id, 'on': !isActive}),
    );
    print('[_toggleDevice] status: \'${res.statusCode}\', body: ${res.body}');
    setState(() {
      isActive = !isActive;
      _loading = false;
    });
  }

  Future<void> _updateName() async {
    print(
      '[_updateName] POST: '
      '${ApiConstants.apiBase}/device/update',
    );
    print(
      '[_updateName] body: \\${json.encode({'id': widget.device.id, 'name': _nameController.text})}',
    );
    setState(() => _loading = true);
    final res = await authorizedRequest(
      'POST',
      Uri.parse('${ApiConstants.apiBase}/device/update'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'id': widget.device.id, 'name': _nameController.text}),
    );
    print('[_updateName] status: \'${res.statusCode}\', body: ${res.body}');
    setState(() => _loading = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('이름이 변경되었습니다.')));
  }

  Future<void> _deleteDevice() async {
    print(
      '[_deleteDevice] POST: '
      '${ApiConstants.apiBase}/device/delete',
    );
    print('[_deleteDevice] body: \\${json.encode({'id': widget.device.id})}');
    setState(() => _loading = true);
    final res = await authorizedRequest(
      'POST',
      Uri.parse('${ApiConstants.apiBase}/device/delete'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'id': widget.device.id}),
    );
    print('[_deleteDevice] status: \'${res.statusCode}\', body: ${res.body}');
    setState(() => _loading = false);
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('기기 상세')),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    SwitchListTile(
                      value: isActive,
                      onChanged: (_) => _toggleDevice(),
                      title: const Text('전원'),
                    ),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: '기기 이름'),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    ElevatedButton(
                      onPressed: _updateName,
                      child: const Text('이름 변경'),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                      ),
                      onPressed: _deleteDevice,
                      child: const Text('기기 삭제'),
                    ),
                  ],
                ),
              ),
    );
  }
}
