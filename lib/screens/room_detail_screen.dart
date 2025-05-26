import 'package:flutter/material.dart';
import '../utils/api_constants.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'sensor_detail_screen.dart';
import 'sensor_add_screen.dart';
import '../models/sensor.dart';
import '../models/room.dart';
import '../utils/api_client.dart';
import 'device_register_screen.dart';

Future<Room?> fetchRoomDetail(int roomId) async {
  final res = await authorizedRequest(
    'GET',
    Uri.parse(ApiConstants.roomDetail(roomId)),
  );
  if (res?.statusCode == 200) {
    final data = json.decode(res?.body ?? '{}');
    return Room.fromJson(data);
  } else {
    return null;
  }
}

Future<List<Sensor>?> fetchSensorList(int roomId) async {
  print('[fetchSensorList] roomId: $roomId');
  final res = await authorizedRequest(
    'GET',
    Uri.parse('${ApiConstants.apiBase}/room/$roomId/sensors'),
  );
  print(
    '[fetchSensorList] status: \'${res?.statusCode}\', body: \\${res?.body}',
  );
  if (res?.statusCode == 200) {
    final List data = json.decode(res?.body ?? '[]');
    return data.map((e) => Sensor.fromJson(e)).toList();
  } else {
    return null;
  }
}

class SensorCard extends StatelessWidget {
  final Sensor sensor;
  final VoidCallback onTap;
  const SensorCard({required this.sensor, required this.onTap, super.key});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF3971FF), Color(0xFF6A82FB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.sensors, color: Color(0xFF3971FF), size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  sensor.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white38),
            ],
          ),
        ),
      ),
    );
  }
}

class RoomDetailScreen extends StatefulWidget {
  final Room room;
  const RoomDetailScreen({required this.room, super.key});
  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen> {
  late Future<List<Sensor>?> _sensorFuture;
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
      appBar: AppBar(
        title: Text(
          '${widget.room.name} - 센서 목록',
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_sensor',
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
        tooltip: '센서 추가',
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<Sensor>?>(
        future: _sensorFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          '센서 목록을 불러올 수 없습니다.',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyLarge?.copyWith(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3971FF),
                            foregroundColor: Colors.white,
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                            minimumSize: const Size.fromHeight(48),
                          ),
                          onPressed: _refresh,
                          child: const Text('다시 시도'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          } else if (snapshot.hasData) {
            final sensors = snapshot.data!;
            if (sensors.isEmpty) {
              return const Center(child: Text('등록된 센서가 없습니다.'));
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.room.name,
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '센서 목록',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: Colors.white70),
                  ),
                  const Divider(
                    color: Colors.white24,
                    thickness: 1,
                    height: 24,
                  ),
                  ...sensors.map(
                    (sensor) => SensorCard(
                      sensor: sensor,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SensorDetailScreen(sensor: sensor),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          } else {
            return const Center(child: Text('알 수 없는 오류'));
          }
        },
      ),
    );
  }
}
