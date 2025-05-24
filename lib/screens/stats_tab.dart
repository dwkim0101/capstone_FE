import '../models/room.dart';
import '../models/sensor.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/api_constants.dart';
import 'package:flutter/material.dart';
import '../utils/api_client.dart';
import 'package:flutter/rendering.dart';

class StatsTab extends StatefulWidget {
  const StatsTab({super.key});

  @override
  State<StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends State<StatsTab>
    with AutomaticKeepAliveClientMixin {
  List<dynamic> _rooms = [];
  int? _selectedRoomId;
  bool _loading = true;
  Map<String, dynamic>? _stats;
  String? _selectedSensorSerial;
  Future<List<Sensor>>? _sensorFuture;

  @override
  void initState() {
    super.initState();
    _fetchRooms();
  }

  @override
  bool get wantKeepAlive => true;

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
        if (rooms.isNotEmpty && rooms[0]['id'] != null) {
          _selectedRoomId = rooms[0]['id'];
          _sensorFuture = fetchSensorList(_selectedRoomId!);
          _fetchStats();
        } else {
          _selectedRoomId = null;
          _sensorFuture = null;
        }
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _fetchStats() async {
    if (_selectedRoomId == null) return;
    final res = await authorizedRequest(
      'GET',
      Uri.parse(ApiConstants.roomScore(_selectedRoomId!)),
    );
    if (res.statusCode == 200) {
      setState(() {
        _stats = json.decode(res.body);
      });
    }
  }

  void _onRoomSelected(int? roomId) {
    if (roomId == null) return;
    setState(() {
      _selectedRoomId = roomId;
      _sensorFuture = fetchSensorList(roomId);
      _fetchStats();
    });
  }

  void _onSensorSelected(String serial) {
    setState(() {
      _selectedSensorSerial = serial;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('통계', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
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
          if (_selectedRoomId != null && _sensorFuture != null)
            FutureBuilder<List<Sensor>>(
              future: _sensorFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      '센서 목록을 불러올 수 없습니다.',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                } else if (snapshot.hasData) {
                  final sensors = snapshot.data!;
                  if (sensors.isNotEmpty && _selectedSensorSerial == null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() {
                          _selectedSensorSerial = sensors[0].serialNumber;
                        });
                      }
                    });
                  }
                  return DropdownButton<String>(
                    value: sensors.isEmpty ? null : _selectedSensorSerial,
                    hint: const Text(
                      '센서 선택',
                      style: TextStyle(color: Colors.white),
                    ),
                    dropdownColor: Colors.black,
                    items:
                        sensors
                            .map(
                              (sensor) => DropdownMenuItem(
                                value: sensor.serialNumber,
                                child: Text(
                                  sensor.name,
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            )
                            .toList(),
                    onChanged: (serial) {
                      if (serial != null) _onSensorSelected(serial);
                    },
                  );
                } else {
                  return const SizedBox();
                }
              },
            ),
          if (_stats != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _stats.toString(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

Future<List<Room>> fetchRoomList() async {
  final res = await authorizedRequest('GET', Uri.parse(ApiConstants.roomList));
  if (res.statusCode == 200) {
    final List data = json.decode(res.body);
    return data.map((e) => Room.fromJson(e)).toList();
  } else {
    throw Exception('방 목록 불러오기 실패');
  }
}

Future<List<Sensor>> fetchSensorList(int roomId) async {
  final res = await authorizedRequest(
    'GET',
    Uri.parse('${ApiConstants.sensorList}?roomId=$roomId'),
  );
  if (res.statusCode == 200) {
    final List data = json.decode(res.body);
    return data.map((e) => Sensor.fromJson(e)).toList();
  } else {
    throw Exception('센서 목록 불러오기 실패');
  }
}

Future<Map<String, dynamic>> fetchRoomScore(int roomId) async {
  final res = await authorizedRequest(
    'GET',
    Uri.parse(ApiConstants.roomScore(roomId)),
  );
  if (res.statusCode == 200) {
    return json.decode(res.body);
  } else {
    throw Exception('방 점수 불러오기 실패');
  }
}

Future<Map<String, dynamic>> fetchSensorScore(String serial) async {
  final res = await authorizedRequest(
    'GET',
    Uri.parse(ApiConstants.sensorScore(serial)),
  );
  if (res.statusCode == 200) {
    return json.decode(res.body);
  } else {
    throw Exception('센서 점수 불러오기 실패');
  }
}
