import 'package:flutter/material.dart';
import '../utils/api_constants.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'sensor_detail_screen.dart';
import 'sensor_add_screen.dart';
import '../models/sensor.dart';
import '../models/room.dart';
import '../utils/api_client.dart';

Future<Room> fetchRoomDetail(int roomId) async {
  final res = await authorizedRequest(
    'GET',
    Uri.parse(ApiConstants.roomDetail(roomId)),
  );
  if (res.statusCode == 200) {
    final data = json.decode(res.body);
    return Room.fromJson(data);
  } else {
    throw Exception('방 상세 불러오기 실패');
  }
}

Future<List<Sensor>> fetchSensorList(int roomId) async {
  print('[fetchSensorList] roomId: $roomId');
  final res = await authorizedRequest(
    'GET',
    Uri.parse('${ApiConstants.sensorList}?roomId=$roomId'),
  );
  print('[fetchSensorList] status: \'${res.statusCode}\', body: ${res.body}');
  if (res.statusCode == 200) {
    final List data = json.decode(res.body);
    return data.map((e) => Sensor.fromJson(e)).toList();
  } else {
    throw Exception('센서 목록 불러오기 실패');
  }
}

class RoomDetailScreen extends StatefulWidget {
  final Room room;
  const RoomDetailScreen({required this.room, super.key});
  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen> {
  late Future<List<Sensor>> _sensorFuture;
  @override
  void initState() {
    super.initState();
    _sensorFuture = fetchSensorList(widget.room.id);
  }

  void _refresh() {
    setState(() {
      _sensorFuture = fetchSensorList(widget.room.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.room.name} - 센서 목록')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => SensorAddScreen(roomId: widget.room.id.toString()),
            ),
          );
          if (result == true) _refresh();
        },
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<Sensor>>(
        future: _sensorFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    '센서 목록을 불러올 수 없습니다.',
                    style: TextStyle(color: Colors.black),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.blue,
                    ),
                    onPressed: _refresh,
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            );
          } else if (snapshot.hasData) {
            final sensors = snapshot.data!;
            if (sensors.isEmpty) {
              return const Center(child: Text('등록된 센서가 없습니다.'));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sensors.length,
              itemBuilder: (context, i) {
                final sensor = sensors[i];
                return Card(
                  color: Colors.blue,
                  child: ListTile(
                    leading: const Icon(Icons.sensors, color: Colors.white),
                    title: Text(
                      sensor.name,
                      style: const TextStyle(color: Colors.white),
                    ),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SensorDetailScreen(sensor: sensor),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          } else {
            return const Center(child: Text('알 수 없는 오류'));
          }
        },
      ),
    );
  }
}
