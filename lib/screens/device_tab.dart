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
import 'device_register_screen.dart';
import 'package:provider/provider.dart';

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
  print("[fetchDeviceList] GET: [36m/thinq/devices/registered/$roomId[0m");
  final res = await authorizedRequest(
    'GET',
    Uri.parse('${ApiConstants.baseUrl}/thinq/devices/registered/$roomId'),
  );
  print("[fetchDeviceList] status: [36m");
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
  final Map<int, bool> _deviceLoading = {}; // deviceId -> loading

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
    // Provider로 기기 리스트 fetch
    Provider.of<DeviceProvider>(
      context,
      listen: false,
    ).fetchDevices(_selectedRoomId!);
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
        onPressed: () async {
          if (_selectedRoomId == null) return;
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DeviceRegisterScreen(roomId: _selectedRoomId!),
            ),
          );
          if (result == true) _fetchDevices();
        },
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
              child: Consumer<DeviceProvider>(
                builder: (context, deviceProvider, _) {
                  if (deviceProvider.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final filteredDevices = deviceProvider.devices;
                  if (filteredDevices.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
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
                            child: SizedBox(
                              width: double.infinity,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
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
                                      padding: EdgeInsets.only(top: 8.0),
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
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: filteredDevices.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 18),
                      itemBuilder: (context, i) {
                        final device = filteredDevices[i];
                        final isOn = device.isActive == true;
                        final isLoading =
                            deviceProvider.deviceLoading[device.id] == true;
                        return Stack(
                          children: [
                            GestureDetector(
                              onTap:
                                  isLoading
                                      ? null
                                      : () async {
                                        final result = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (_) => DeviceDetailScreen(
                                                  device: device,
                                                ),
                                          ),
                                        );
                                        if (result == true) _fetchDevices();
                                      },
                              child: Container(
                                decoration: BoxDecoration(
                                  color:
                                      isOn
                                          ? Color(0xFF3971FF)
                                          : Colors.white.withOpacity(0.10),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    if (isOn)
                                      BoxShadow(
                                        color: Color(
                                          0xFF3971FF,
                                        ).withOpacity(0.18),
                                        blurRadius: 16,
                                        offset: Offset(0, 6),
                                      ),
                                  ],
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 18,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color:
                                            isOn
                                                ? Colors.white
                                                : Colors.white12,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.air,
                                        color:
                                            isOn
                                                ? Color(0xFF3971FF)
                                                : Colors.white54,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 18),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            device.name,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            isOn ? '켜짐' : '꺼짐',
                                            style: TextStyle(
                                              color:
                                                  isOn
                                                      ? Colors.white
                                                      : Colors.white54,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    isLoading
                                        ? SizedBox(
                                          width: 32,
                                          height: 32,
                                          child: SizedBox.shrink(),
                                        )
                                        : Switch(
                                          value: isOn,
                                          onChanged:
                                              isLoading
                                                  ? null
                                                  : (_) async {
                                                    await Provider.of<
                                                      DeviceProvider
                                                    >(
                                                      context,
                                                      listen: false,
                                                    ).toggleDevice(device.id);
                                                  },
                                          activeColor: Colors.white,
                                          activeTrackColor: Color(0xFF2351B5),
                                          inactiveThumbColor: Colors.white54,
                                          inactiveTrackColor: Colors.white24,
                                        ),
                                  ],
                                ),
                              ),
                            ),
                            if (isLoading)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
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
