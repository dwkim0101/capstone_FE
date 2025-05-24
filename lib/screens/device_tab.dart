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

class _DeviceTabState extends State<DeviceTab> {
  int? _selectedRoomId;
  late Future<List<Room>> _roomFuture;
  Future<List<Device>>? _deviceFuture;

  @override
  void initState() {
    super.initState();
    _roomFuture = fetchRoomList();
  }

  void _onRoomSelected(int roomId) {
    setState(() {
      _selectedRoomId = roomId;
      _deviceFuture = fetchDeviceList(roomId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('기기 관리', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<Room>>(
        future: _roomFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                '방 목록을 불러올 수 없습니다.',
                style: TextStyle(color: Colors.white),
              ),
            );
          } else if (snapshot.hasData) {
            final rooms = snapshot.data!;
            return Column(
              children: [
                DropdownButton<int>(
                  value: _selectedRoomId,
                  hint: const Text(
                    '방 선택',
                    style: TextStyle(color: Colors.white),
                  ),
                  dropdownColor: Colors.black,
                  items:
                      rooms
                          .map(
                            (room) => DropdownMenuItem(
                              value: room.id,
                              child: Text(
                                room.name,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: (roomId) {
                    if (roomId != null) _onRoomSelected(roomId);
                  },
                ),
                if (_selectedRoomId != null && _deviceFuture != null)
                  Expanded(
                    child: FutureBuilder<List<Device>>(
                      future: _deviceFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        } else if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              '기기 목록을 불러올 수 없습니다.',
                              style: TextStyle(color: Colors.white),
                            ),
                          );
                        } else if (snapshot.hasData) {
                          final devices = snapshot.data!;
                          if (devices.isEmpty) {
                            return const Center(
                              child: Text(
                                '등록된 기기가 없습니다.',
                                style: TextStyle(color: Colors.white70),
                              ),
                            );
                          }
                          return ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: devices.length,
                            itemBuilder: (context, i) {
                              final device = devices[i];
                              return Card(
                                color: Colors.blue,
                                child: ListTile(
                                  leading: const Icon(
                                    Icons.air,
                                    color: Colors.white,
                                  ),
                                  title: Text(
                                    device.alias,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              );
                            },
                          );
                        } else {
                          return const Center(
                            child: Text(
                              '알 수 없는 오류',
                              style: TextStyle(color: Colors.white),
                            ),
                          );
                        }
                      },
                    ),
                  ),
              ],
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
