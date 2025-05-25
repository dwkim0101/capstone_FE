import 'package:flutter/material.dart';
import '../utils/api_constants.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/room.dart';
import '../utils/api_client.dart';
import 'device_detail_screen.dart' hide Device;
import '../models/device.dart';
import 'dart:ui';
import 'login_screen.dart';

Future<List<Room>?> fetchRoomList() async {
  final res = await authorizedRequest('GET', Uri.parse(ApiConstants.roomList));
  if (res?.statusCode == 200) {
    final List data = json.decode(res?.body ?? '[]');
    return data.map((e) => Room.fromJson(e)).toList();
  } else {
    return null;
  }
}

Future<List<Device>?> fetchDeviceList(int roomId) async {
  print("[fetchDeviceList] GET: ${ApiConstants.thinqDeviceList(roomId)}");
  final res = await authorizedRequest(
    'GET',
    Uri.parse(ApiConstants.thinqDeviceList(roomId)),
  );
  print("[fetchDeviceList] status: ${res?.statusCode}, body: ${res?.body}");
  if (res?.statusCode == 200) {
    final List data = json.decode(res?.body ?? '[]');
    return data.map((e) => Device.fromJson(e)).toList();
  } else if (res?.statusCode == 403) {
    throw Exception('403');
  } else {
    throw Exception('기기 목록 불러오기 실패');
  }
}

Future<void> toggleDevice(int deviceId) async {
  print('[toggleDevice] POST: /thinq/power/\u001b[36m$deviceId\u001b[0m');
  final res = await authorizedRequest(
    'POST',
    Uri.parse('${ApiConstants.baseUrl}/thinq/power/$deviceId'),
  );
  print('[toggleDevice] status: \'${res?.statusCode}\', body: \\${res?.body}');
  if (res?.statusCode != 200) {
    throw Exception('기기 제어 실패');
  }
}

Future<String> fetchDevicePowerStatus(int deviceId) async {
  final res = await authorizedRequest(
    'GET',
    Uri.parse('${ApiConstants.baseUrl}/thinq/status/$deviceId'),
  );
  if (res?.statusCode == 200) {
    final data = json.decode(res?.body ?? '{}');
    final op = data['response']?['operation']?['airFanOperationMode'];
    if (op == 'POWER_ON') return 'ON';
    if (op == 'POWER_OFF') return 'OFF';
    return 'UNKNOWN';
  } else {
    return 'UNKNOWN';
  }
}

Future<List<Map<String, dynamic>>> fetchDeviceListWithStatus(int roomId) async {
  final devices = await fetchDeviceList(roomId) ?? [];
  final List<Map<String, dynamic>> result = [];
  for (final device in devices) {
    if (device.isRegistered == true) {
      final status = await fetchDevicePowerStatus(device.id);
      result.add({'device': device, 'status': status});
    }
    // isRegistered==false인 기기는 status 요청/추가하지 않음
  }
  return result;
}

Room? _findRoomById(List<Room> rooms, int? id) {
  if (id == null) return null;
  for (final r in rooms) {
    if (r.id == id) return r;
  }
  return null;
}

class DeviceTab extends StatefulWidget {
  const DeviceTab({super.key});
  @override
  State<DeviceTab> createState() => _DeviceTabState();
}

class _DeviceTabState extends State<DeviceTab>
    with AutomaticKeepAliveClientMixin {
  List<Room> _rooms = [];
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
    try {
      final res = await authorizedRequest(
        'GET',
        Uri.parse(ApiConstants.roomList),
      );
      if (res?.statusCode == 200) {
        final List data = json.decode(res?.body ?? '[]');
        setState(() {
          _rooms = data.map((e) => Room.fromJson(e)).toList();
          if (_rooms.isNotEmpty) {
            final validIds = _rooms.map((r) => r.id).toSet();
            if (_selectedRoomId == null ||
                !validIds.contains(_selectedRoomId)) {
              _selectedRoomId = _rooms[0].id;
            }
            _fetchDevices();
          }
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _fetchDevices() async {
    if (_selectedRoomId == null) return;
    try {
      setState(() {
        _deviceFutureWithStatus = fetchDeviceListWithStatus(_selectedRoomId!);
      });
    } catch (e) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
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
            backgroundColor: Colors.grey[900],
            title: const Text('기기 추가', style: TextStyle(color: Colors.white)),
            content: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: '기기명 입력',
                hintStyle: TextStyle(color: Colors.white54),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
              ),
              cursorColor: Colors.white,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  '취소',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, controller.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF3971FF),
                  foregroundColor: Colors.white,
                ),
                child: const Text('추가', style: TextStyle(color: Colors.white)),
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
    if (res?.statusCode != 200) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('기기 추가 실패')));
    }
  }

  Future<void> _showPatRegisterDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text('PAT 등록', style: TextStyle(color: Colors.white)),
            content: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'PAT 값을 입력하세요',
                hintStyle: TextStyle(color: Colors.white54),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
              ),
              cursorColor: Colors.white,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  '취소',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, controller.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF3971FF),
                  foregroundColor: Colors.white,
                ),
                child: const Text('등록', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
    );
    if (result != null && result.trim().isNotEmpty) {
      await _registerPat(result.trim());
    }
  }

  Future<void> _registerPat(String pat) async {
    final res = await authorizedRequest(
      'POST',
      Uri.parse('${ApiConstants.apiBase}/pat'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'pat': pat}),
    );
    if (res?.statusCode == 200) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('PAT 등록 완료!')));
      _fetchDevices();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('PAT 등록 실패')));
    }
  }

  Future<void> _requestPatPermission(int roomId) async {
    final res = await authorizedRequest(
      'POST',
      Uri.parse('${ApiConstants.apiBase}/room/$roomId/pat-permission-request'),
    );
    if (res?.statusCode == 200) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('방장에게 PAT 권한 요청을 보냈습니다.')));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('권한 요청 실패: ${res?.body}')));
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
                    '현재 방: ${_findRoomById(_rooms, _selectedRoomId)?.name ?? '-'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Builder(
                    builder: (context) {
                      final validRoomIds = _rooms.map((r) => r.id).toSet();
                      final dropdownItems =
                          validRoomIds.map((id) {
                            final Room? room = _findRoomById(_rooms, id);
                            return DropdownMenuItem<int>(
                              value: id,
                              child: Text(room?.name ?? '-'),
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
                            final error = snapshot.error.toString();
                            if (error.contains('403')) {
                              final room = _findRoomById(
                                _rooms,
                                _selectedRoomId,
                              );
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.lock_outline,
                                      color: Colors.redAccent,
                                      size: 48,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      '이 방의 기기 목록을 볼 권한이 없습니다.\n(PAT 등록 필요)',
                                      style: const TextStyle(
                                        color: Colors.redAccent,
                                        fontSize: 16,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: _showPatRegisterDialog,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Color(0xFF3971FF),
                                        foregroundColor: Colors.white,
                                        textStyle: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      child: const Text(
                                        'PAT 등록하기',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                    if (room != null) ...[
                                      const SizedBox(height: 16),
                                      Text(
                                        '방 이름: ${room.name}',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      ElevatedButton.icon(
                                        onPressed:
                                            () =>
                                                _requestPatPermission(room.id),
                                        icon: const Icon(
                                          Icons.send,
                                          color: Colors.white,
                                        ),
                                        label: const Text(
                                          '방장에게 PAT 권한 요청',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.deepPurple,
                                          foregroundColor: Colors.white,
                                          textStyle: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            }
                            // 기타 에러
                            return Center(
                              child: Text(
                                '기기 오류: $error',
                                style: TextStyle(color: Colors.white),
                              ),
                            );
                          } else if (snapshot.hasData) {
                            final devices = snapshot.data!;
                            final filteredDevices =
                                devices
                                    .where(
                                      (d) =>
                                          (d['device'] as Device)
                                              .isRegistered ==
                                          true,
                                    )
                                    .toList();
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
                                        filteredDevices.isEmpty
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
                                              itemCount: filteredDevices.length,
                                              separatorBuilder:
                                                  (_, __) => const SizedBox(
                                                    height: 16,
                                                  ),
                                              itemBuilder: (context, i) {
                                                final device =
                                                    filteredDevices[i]['device']
                                                        as Device;
                                                final status =
                                                    filteredDevices[i]['status']
                                                        as String;
                                                final isOn = status == 'ON';
                                                return Container(
                                                  decoration: BoxDecoration(
                                                    color:
                                                        isOn
                                                            ? Color(0xFF3971FF)
                                                            : Colors.white
                                                                .withOpacity(
                                                                  0.10,
                                                                ),
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
                                                    enabled: true,
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
                                                                  isRegistered:
                                                                      device
                                                                          .isRegistered,
                                                                ),
                                                              ),
                                                        ),
                                                      );
                                                      if (result == true)
                                                        _fetchDevices();
                                                    },
                                                    trailing: Switch(
                                                      value: isOn,
                                                      onChanged: (_) async {
                                                        await toggleDevice(
                                                          device.id,
                                                        );
                                                        _fetchDevices();
                                                      },
                                                      activeColor: Color(
                                                        0xFF3971FF,
                                                      ),
                                                      inactiveThumbColor:
                                                          Colors.white54,
                                                      inactiveTrackColor:
                                                          Colors.white24,
                                                    ),
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
