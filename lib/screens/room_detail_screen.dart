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
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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

  Future<void> _deleteRoom() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('방 삭제'),
            content: Text('정말 이 방을 삭제하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('취소'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('삭제'),
              ),
            ],
          ),
    );
    if (confirm != true) return;
    try {
      final res = await authorizedRequest(
        'DELETE',
        Uri.parse(ApiConstants.roomDelete(widget.room.id)),
      );
      if (res?.statusCode == 204 || res?.statusCode == 200) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('방 삭제 실패: \\${res?.body}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('방 삭제 오류: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.room.name,
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.delete, color: Colors.redAccent),
            tooltip: '방 삭제',
            onPressed: _deleteRoom,
          ),
        ],
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
      body: Column(
        children: [
          if (widget.room.latitude != null && widget.room.longitude != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // const SizedBox(height: 20),
                  Text(
                    '위치 정보',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: Colors.white70),
                  ),
                  const Divider(
                    color: Colors.white24,
                    thickness: 1,
                    height: 24,
                  ),
                  Card(
                    color: Colors.grey[900],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: SizedBox(
                      height: 180,
                      child: FlutterMap(
                        options: MapOptions(
                          center: LatLng(
                            widget.room.latitude!,
                            widget.room.longitude!,
                          ),
                          zoom: 16.0,
                          interactiveFlags: InteractiveFlag.none,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                            subdomains: const ['a', 'b', 'c'],
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                width: 40,
                                height: 40,
                                point: LatLng(
                                  widget.room.latitude!,
                                  widget.room.longitude!,
                                ),
                                child: const Icon(
                                  Icons.location_on,
                                  color: Colors.red,
                                  size: 40,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: FutureBuilder<List<Sensor>?>(
              future: _sensorFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return const Center(child: Text('센서 목록을 불러올 수 없습니다.'));
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
                        const SizedBox(height: 20),
                        Text(
                          '센서 목록',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: Colors.white70),
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
                                  builder:
                                      (_) => SensorDetailScreen(
                                        sensor: sensor,
                                        roomId: widget.room.id,
                                      ),
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
          ),
        ],
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    route?.addScopedWillPopCallback(() async {
      final result = route.settings.arguments;
      if (result == true) _refresh();
      return true;
    });
  }
}
