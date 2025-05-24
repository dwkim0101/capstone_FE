import 'package:flutter/material.dart';
import '../utils/api_constants.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/room.dart';
import '../utils/api_client.dart';

Future<List<Room>> fetchRoomList() async {
  final res = await authorizedRequest('GET', Uri.parse(ApiConstants.roomList));
  if (res.statusCode == 200) {
    final List data = json.decode(res.body);
    return data.map((e) => Room.fromJson(e)).toList();
  } else {
    throw Exception('방 목록 불러오기 실패');
  }
}

class Device {
  final int deviceId;
  final String alias;
  Device({required this.deviceId, required this.alias});
  factory Device.fromJson(Map<String, dynamic> json) => Device(
    deviceId:
        json['deviceId'] is int
            ? json['deviceId']
            : int.tryParse(json['deviceId'].toString()) ?? 0,
    alias: json['alias'] ?? '',
  );
}

Future<List<Device>> fetchDeviceList(int roomId) async {
  print('[fetchDeviceList] GET: ${ApiConstants.deviceList(roomId)}');
  final res = await authorizedRequest(
    'GET',
    Uri.parse(ApiConstants.deviceList(roomId)),
  );
  print('[fetchDeviceList] status: \'${res.statusCode}\', body: ${res.body}');
  if (res.statusCode == 200) {
    final List data = json.decode(res.body);
    return data.map((e) => Device.fromJson(e)).toList();
  } else {
    throw Exception('기기 목록 불러오기 실패');
  }
}

Future<void> toggleDevice(String deviceId, bool isOn) async {
  print('[toggleDevice] POST: ${ApiConstants.deviceControl}');
  print('[toggleDevice] body: ${json.encode({'id': deviceId, 'on': isOn})}');
  final res = await authorizedRequest(
    'POST',
    Uri.parse(ApiConstants.deviceControl),
    headers: {'Content-Type': 'application/json'},
    body: json.encode({'id': deviceId, 'on': isOn}),
  );
  print('[toggleDevice] status: \'${res.statusCode}\', body: ${res.body}');
  if (res.statusCode != 200) {
    throw Exception('기기 제어 실패');
  }
}

class DeviceTab extends StatefulWidget {
  const DeviceTab({super.key});
  @override
  State<DeviceTab> createState() => _DeviceTabState();
}

class _DeviceTabState extends State<DeviceTab>
    with AutomaticKeepAliveClientMixin {
  List<dynamic> _rooms = [];
  int? _selectedRoomId;
  bool _loading = true;
  List<Device> _devices = [];

  @override
  void initState() {
    super.initState();
    _fetchRooms();
  }

  Future<void> _fetchRooms() async {
    setState(() => _loading = true);
    final res = await authorizedRequest(
      'GET',
      Uri.parse(ApiConstants.roomList),
    );
    if (res.statusCode == 200) {
      final rooms = json.decode(res.body);
      setState(() {
        _rooms = rooms;
        if (rooms.isNotEmpty) {
          _selectedRoomId = rooms[0]['id'];
          _fetchDevices();
        }
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _fetchDevices() async {
    if (_selectedRoomId == null) return;
    final res = await authorizedRequest(
      'GET',
      Uri.parse(ApiConstants.deviceList(_selectedRoomId!)),
    );
    if (res.statusCode == 200) {
      final List data = json.decode(res.body);
      setState(() {
        _devices = data.map((e) => Device.fromJson(e)).toList();
      });
    }
  }

  void _onRoomSelected(int? roomId) {
    if (roomId == null) return;
    setState(() {
      _selectedRoomId = roomId;
      _fetchDevices();
    });
  }

  Future<void> _showAddDeviceDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('기기 추가'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: '기기명 입력'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, controller.text),
                child: const Text('추가'),
              ),
            ],
          ),
    );
    if (result != null && result.trim().isNotEmpty && _selectedRoomId != null) {
      await _addDevice(result.trim(), _selectedRoomId!);
      await _fetchDevices();
    }
  }

  Future<void> _addDevice(String name, int roomId) async {
    final res = await authorizedRequest(
      'POST',
      Uri.parse('${ApiConstants.apiBase}/device/add'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'name': name, 'roomId': roomId}),
    );
    if (res.statusCode != 200) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('기기 추가 실패')));
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('기기 관리', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDeviceDialog,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          if (_rooms.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '현재 방: \\${_rooms.firstWhere((r) => r['id'] == _selectedRoomId, orElse: () => null)?['name'] ?? '-'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  DropdownButton<int>(
                    value: _selectedRoomId,
                    isExpanded: true,
                    dropdownColor: Colors.black,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    items:
                        _rooms.map<DropdownMenuItem<int>>((room) {
                          return DropdownMenuItem(
                            value: room['id'],
                            child: Text(room['name']),
                          );
                        }).toList(),
                    onChanged: _onRoomSelected,
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                '방을 먼저 추가하세요.',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ),
          if (_selectedRoomId != null && _devices.isNotEmpty)
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _devices.length,
                itemBuilder: (context, i) {
                  final device = _devices[i];
                  return Card(
                    color: Colors.blue,
                    child: ListTile(
                      leading: const Icon(Icons.air, color: Colors.white),
                      title: Text(
                        device.alias,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
