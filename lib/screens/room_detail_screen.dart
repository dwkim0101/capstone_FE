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
              return const Center(
                child: Text(
                  '등록된 센서가 없습니다.',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: sensors.length,
                separatorBuilder: (_, __) => const SizedBox(height: 18),
                itemBuilder: (context, i) {
                  final sensor = sensors[i];
                  return GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SensorDetailScreen(sensor: sensor),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.10),
                            blurRadius: 12,
                            offset: Offset(0, 4),
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
                              color: Colors.white12,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.sensors,
                              color: Color(0xFF3971FF),
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Text(
                              sensor.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(
                            Icons.chevron_right,
                            color: Colors.white38,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          } else {
            return const Center(
              child: Text(
                '알 수 없는 오류',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            );
          }
        },
      ),
    );
  }
}
