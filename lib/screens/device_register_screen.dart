import 'package:flutter/material.dart';
import '../utils/api_constants.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/api_client.dart';
import '../models/device.dart';

class DeviceRegisterScreen extends StatefulWidget {
  final int roomId;
  const DeviceRegisterScreen({required this.roomId, super.key});
  @override
  State<DeviceRegisterScreen> createState() => _DeviceRegisterScreenState();
}

class _DeviceRegisterScreenState extends State<DeviceRegisterScreen> {
  List<Device> _devices = [];
  int? _selectedDeviceId;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchDevices();
  }

  Future<void> _fetchDevices() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await authorizedRequest(
        'GET',
        Uri.parse('${ApiConstants.baseUrl}/thinq/devices/all/${widget.roomId}'),
      );
      if (res?.statusCode == 200) {
        final List data = json.decode(res?.body ?? '[]');
        setState(() {
          _devices = data.map((e) => Device.fromJson(e)).toList();
          _loading = false;
        });
      } else {
        setState(() {
          _error = '기기 목록을 불러올 수 없습니다.';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = '기기 목록 오류: $e';
        _loading = false;
      });
    }
  }

  Future<void> _registerDevice() async {
    if (_selectedDeviceId == null) return;
    setState(() => _loading = true);
    try {
      final device = _devices.firstWhere((d) => d.id == _selectedDeviceId);
      final isRegistered = device.isRegistered == true;
      final url =
          '${ApiConstants.baseUrl}/thinq/${_selectedDeviceId!}/${widget.roomId}';
      final method = isRegistered ? 'PUT' : 'POST';
      final res = await authorizedRequest(method, Uri.parse(url));
      if (res?.statusCode == 200) {
        Navigator.pop(context, true);
      } else {
        setState(() {
          _error = '기기 등록 실패: ${res?.body}';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = '기기 등록 오류: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final cardColor = isDark ? Colors.grey[900] : Colors.white;
    final borderColor = isDark ? Colors.white12 : Colors.black12;
    return Scaffold(
      appBar: AppBar(
        title: const Text('기기 등록', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              )
              : Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '등록 가능한 기기 목록',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child:
                          _devices.isEmpty
                              ? Center(
                                child: Text(
                                  '기기가 없습니다.',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                  ),
                                ),
                              )
                              : ListView.separated(
                                itemCount: _devices.length,
                                separatorBuilder:
                                    (_, __) => const SizedBox(height: 12),
                                itemBuilder: (context, idx) {
                                  final device = _devices[idx];
                                  return Card(
                                    color: cardColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: BorderSide(color: borderColor),
                                    ),
                                    elevation: 2,
                                    child: ListTile(
                                      leading: Icon(
                                        Icons.devices_other,
                                        color: Colors.blueAccent,
                                        size: 32,
                                      ),
                                      title: Text(
                                        device.name.isNotEmpty
                                            ? device.name
                                            : '(이름 없음)',
                                        style: TextStyle(
                                          color: textColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      subtitle:
                                          device.isRegistered == true
                                              ? Text(
                                                '이미 등록됨',
                                                style: TextStyle(
                                                  color: Colors.green,
                                                  fontSize: 13,
                                                ),
                                              )
                                              : null,
                                      trailing: Radio<int>(
                                        value: device.id,
                                        groupValue: _selectedDeviceId,
                                        onChanged:
                                            (v) => setState(
                                              () => _selectedDeviceId = v,
                                            ),
                                        activeColor: Colors.blueAccent,
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                      onTap:
                                          () => setState(
                                            () => _selectedDeviceId = device.id,
                                          ),
                                    ),
                                  );
                                },
                              ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            _selectedDeviceId == null ? null : _registerDevice,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('선택한 기기 등록'),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
