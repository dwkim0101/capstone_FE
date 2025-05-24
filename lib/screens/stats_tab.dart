import '../models/room.dart';
import '../models/sensor.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/api_constants.dart';
import 'package:flutter/material.dart';
import '../utils/api_client.dart';

class StatsTab extends StatefulWidget {
  const StatsTab({super.key});

  @override
  State<StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends State<StatsTab> {
  int? _selectedRoomId;
  String? _selectedSensorSerial;
  late Future<List<Room>> _roomFuture;
  Future<List<Sensor>>? _sensorFuture;
  Future<Map<String, dynamic>>? _scoreFuture;

  @override
  void initState() {
    super.initState();
    _roomFuture = fetchRoomList();
  }

  void _onRoomSelected(int roomId) {
    setState(() {
      _selectedRoomId = roomId;
      _sensorFuture = fetchSensorList(roomId);
      _scoreFuture = fetchRoomScore(roomId);
      _selectedSensorSerial = null;
    });
  }

  void _onSensorSelected(String serial) {
    setState(() {
      _selectedSensorSerial = serial;
      _scoreFuture = fetchSensorScore(serial);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('통계', style: TextStyle(color: Colors.white)),
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
                        return DropdownButton<String>(
                          value: _selectedSensorSerial,
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
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
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
                if (_scoreFuture != null)
                  FutureBuilder<Map<String, dynamic>>(
                    future: _scoreFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            '점수 정보를 불러올 수 없습니다.',
                            style: TextStyle(color: Colors.white),
                          ),
                        );
                      } else if (snapshot.hasData) {
                        final score = snapshot.data!;
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            score.toString(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        );
                      } else {
                        return const SizedBox();
                      }
                    },
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
