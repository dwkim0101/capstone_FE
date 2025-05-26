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
      '${ApiConstants.thinqDevicePower(widget.device.id)}',
    );
    print(
      '[_toggleDevice] body: ${json.encode({'id': widget.device.id, 'on': !isActive})}',
    );
    setState(() => _loading = true);
    final res = await authorizedRequest(
      'POST',
      Uri.parse(ApiConstants.thinqDevicePower(widget.device.id)),
      headers: {'Content-Type': 'application/json'},
      // body: json.encode({'id': widget.device.id, 'on': !isActive}), // 실제 명세상 body 필요없으면 제거
    );
    print(
      '[_toggleDevice] status: \\${res?.statusCode}\', body: \\${res?.body}',
    );
    setState(() {
      isActive = !isActive;
      _loading = false;
    });
  }

  Future<void> _updateName() async {
    // Swagger 명세에 기기 이름 변경 엔드포인트가 없으므로, 임시로 주석처리 또는 안내
    print('[_updateName] 기기 이름 변경 엔드포인트 없음 (Swagger 기준)');
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('기기 이름 변경 API가 지원되지 않습니다.')));
  }

  Future<void> _deleteDevice() async {
    setState(() => _loading = true);
    try {
      final res = await authorizedRequest(
        'DELETE',
        Uri.parse(ApiConstants.thinqDeviceDelete(widget.device.id)),
      );
      if (res?.statusCode == 200) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('기기 삭제 실패: \\${res?.body}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('기기 삭제 오류: $e')));
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('기기 상세', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Card(
                  margin: const EdgeInsets.all(24),
                  color: Colors.grey[900],
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '기기 이름',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: Colors.white70),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.device.name,
                          style: Theme.of(
                            context,
                          ).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Divider(
                          color: Colors.white24,
                          thickness: 1,
                          height: 32,
                        ),
                        SwitchListTile(
                          value: isActive,
                          onChanged: (_) => _toggleDevice(),
                          title: const Text(
                            '전원',
                            style: TextStyle(color: Colors.white),
                          ),
                          activeColor: Theme.of(context).colorScheme.primary,
                          inactiveThumbColor: Colors.white54,
                          inactiveTrackColor: Colors.white24,
                          contentPadding: EdgeInsets.zero,
                        ),
                        const Divider(
                          color: Colors.white24,
                          thickness: 1,
                          height: 32,
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: '새 기기 이름',
                            labelStyle: TextStyle(color: Colors.white70),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white24),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.white),
                            ),
                          ),
                          style: const TextStyle(color: Colors.white),
                          cursorColor: Colors.white,
                        ),
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF3971FF),
                                  foregroundColor: Colors.white,
                                  textStyle: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  minimumSize: const Size.fromHeight(48),
                                ),
                                onPressed: _updateName,
                                child: const Text('이름 변경'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).colorScheme.error,
                                  foregroundColor: Colors.white,
                                  textStyle: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  minimumSize: const Size.fromHeight(48),
                                ),
                                onPressed: _deleteDevice,
                                child: const Text('기기 삭제'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }
}
