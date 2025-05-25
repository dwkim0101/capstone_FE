import 'package:flutter/material.dart';
import '../utils/api_constants.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/room.dart';
import '../utils/api_client.dart';
import 'device_detail_screen.dart' hide Device;
import '../models/device.dart';
import 'dart:ui';

Future<List<Room>> fetchRoomList() async {
  final res = await authorizedRequest('GET', Uri.parse(ApiConstants.roomList));
  if (res.statusCode == 200) {
    final List data = json.decode(res.body);
    return data.map((e) => Room.fromJson(e)).toList();
  } else {
    throw Exception('방 목록 불러오기 실패');
  }
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

Future<void> toggleDevice(int deviceId) async {
  print('[toggleDevice] POST: /thinq/power/[36m$deviceId[0m');
  final res = await authorizedRequest(
    'POST',
    Uri.parse('${ApiConstants.baseUrl}/thinq/power/$deviceId'),
  );
  print('[toggleDevice] status: \'${res.statusCode}\', body: ${res.body}');
  if (res.statusCode != 200) {
    throw Exception('기기 제어 실패');
  }
}

Future<String> fetchDevicePowerStatus(int deviceId) async {
  final res = await authorizedRequest(
    'GET',
    Uri.parse('${ApiConstants.baseUrl}/thinq/status/$deviceId'),
  );
  if (res.statusCode == 200) {
    final data = json.decode(res.body);
    final op = data['response']?['operation']?['airFanOperationMode'];
    if (op == 'POWER_ON') return 'ON';
    if (op == 'POWER_OFF') return 'OFF';
    return 'UNKNOWN';
  } else {
    return 'UNKNOWN';
  }
}

Future<List<Map<String, dynamic>>> fetchDeviceListWithStatus(int roomId) async {
  final devices = await fetchDeviceList(roomId);
  final List<Map<String, dynamic>> result = [];
  for (final device in devices) {
    final status = await fetchDevicePowerStatus(device.id);
    result.add({'device': device, 'status': status});
  }
  return result;
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
  final List<Device> _devices = [];
  Future<List<Map<String, dynamic>>>? _deviceFutureWithStatus;

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
        if (_rooms.isNotEmpty) {
          final validIds =
              _rooms
                  .where((r) => r['id'] is int)
                  .map<int>((r) => r['id'] as int)
                  .toSet();
          if (_selectedRoomId == null || !validIds.contains(_selectedRoomId)) {
            _selectedRoomId = _rooms[0]['id'];
          }
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
    setState(() {
      _deviceFutureWithStatus = fetchDeviceListWithStatus(_selectedRoomId!);
    });
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
        heroTag: 'device_fab',
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
                    '현재 방: ${_rooms.firstWhere((r) => r['id'] == _selectedRoomId, orElse: () => null)?['name'] ?? '-'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Builder(
                    builder: (context) {
                      final validRoomIds =
                          _rooms
                              .where((r) => r['id'] is int)
                              .map<int>((r) => r['id'] as int)
                              .toSet();
                      final dropdownItems =
                          validRoomIds.map((id) {
                            final room = _rooms.firstWhere(
                              (r) => r['id'] == id,
                            );
                            return DropdownMenuItem<int>(
                              value: id,
                              child: Text(room['name']),
                            );
                          }).toList();
                      int? dropdownValue;
                      if (dropdownItems.isNotEmpty &&
                          _selectedRoomId != null &&
                          dropdownItems
                                  .where(
                                    (item) => item.value == _selectedRoomId,
                                  )
                                  .length ==
                              1) {
                        dropdownValue = _selectedRoomId;
                      } else {
                        dropdownValue = null;
                      }
                      return DropdownButton<int>(
                        value: dropdownValue,
                        isExpanded: true,
                        dropdownColor: Colors.black,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                        ),
                        items: dropdownItems,
                        onChanged: (v) {
                          if (v != null) _onRoomSelected(v);
                        },
                        hint: const Text(
                          '방 선택',
                          style: TextStyle(color: Colors.white70),
                        ),
                      );
                    },
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
          if (_selectedRoomId != null)
            Expanded(
              child:
                  _deviceFutureWithStatus == null
                      ? const Center(child: CircularProgressIndicator())
                      : FutureBuilder<List<Map<String, dynamic>>>(
                        future: _deviceFutureWithStatus,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          } else if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                '기기 오류: \\${snapshot.error}',
                                style: TextStyle(color: Colors.white),
                              ),
                            );
                          } else if (snapshot.hasData) {
                            final devices = snapshot.data!;
                            return Padding(
                              padding: const EdgeInsets.all(16),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 12,
                                    sigmaY: 12,
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.12),
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 20,
                                      horizontal: 12,
                                    ),
                                    child:
                                        devices.isEmpty
                                            ? SizedBox(
                                              width: double.infinity,
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.devices_other,
                                                    color: Colors.white38,
                                                    size: 40,
                                                  ),
                                                  const SizedBox(height: 12),
                                                  const Text(
                                                    '기기를 추가해주세요.',
                                                    style: TextStyle(
                                                      color: Colors.white70,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 16),
                                                  if (_rooms.isEmpty)
                                                    const Padding(
                                                      padding: EdgeInsets.only(
                                                        top: 8.0,
                                                      ),
                                                      child: Text(
                                                        '방을 먼저 추가하세요.',
                                                        style: TextStyle(
                                                          color: Colors.white54,
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            )
                                            : ListView.separated(
                                              shrinkWrap: true,
                                              itemCount: devices.length,
                                              separatorBuilder:
                                                  (_, __) => const SizedBox(
                                                    height: 16,
                                                  ),
                                              itemBuilder: (context, i) {
                                                final device =
                                                    devices[i]['device']
                                                        as Device;
                                                final status =
                                                    devices[i]['status']
                                                        as String;
                                                final isOn = status == 'ON';
                                                return Container(
                                                  decoration: BoxDecoration(
                                                    color: Colors.white
                                                        .withOpacity(0.10),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          16,
                                                        ),
                                                  ),
                                                  child: ListTile(
                                                    leading: Container(
                                                      width: 48,
                                                      height: 48,
                                                      decoration: BoxDecoration(
                                                        color:
                                                            isOn
                                                                ? Color(
                                                                  0xFF3971FF,
                                                                )
                                                                : Colors.white
                                                                    .withOpacity(
                                                                      0.18,
                                                                    ),
                                                        shape: BoxShape.circle,
                                                        boxShadow: [
                                                          if (isOn)
                                                            BoxShadow(
                                                              color: Color(
                                                                0xFF3971FF,
                                                              ).withOpacity(
                                                                0.3,
                                                              ),
                                                              blurRadius: 12,
                                                              offset: Offset(
                                                                0,
                                                                4,
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                      child: Icon(
                                                        Icons.air,
                                                        color:
                                                            isOn
                                                                ? Colors.white
                                                                : Color(
                                                                  0xFF3971FF,
                                                                ),
                                                        size: 28,
                                                      ),
                                                    ),
                                                    title: Text(
                                                      device.name,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                    subtitle: Text(
                                                      isOn ? '켜짐' : '꺼짐',
                                                      style: TextStyle(
                                                        color:
                                                            isOn
                                                                ? Color(
                                                                  0xFF3971FF,
                                                                )
                                                                : Colors
                                                                    .white70,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    trailing: const Icon(
                                                      Icons.chevron_right,
                                                      color: Colors.white,
                                                    ),
                                                    onTap: () async {
                                                      final result = await Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder:
                                                              (
                                                                _,
                                                              ) => DeviceDetailScreen(
                                                                device: Device(
                                                                  id: device.id,
                                                                  name:
                                                                      device
                                                                          .name,
                                                                  isActive:
                                                                      isOn,
                                                                ),
                                                              ),
                                                        ),
                                                      );
                                                      if (result == true)
                                                        _fetchDevices();
                                                    },
                                                  ),
                                                );
                                              },
                                            ),
                                  ),
                                ),
                              ),
                            );
                          } else {
                            return const SizedBox();
                          }
                        },
                      ),
            ),
        ],
      ),
    );
  }
}
