import 'package:flutter/material.dart';
import '../utils/api_constants.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sensor.dart';
import '../utils/api_client.dart';
import 'login_screen.dart';

class SensorDetailScreen extends StatefulWidget {
  final Sensor sensor;
  const SensorDetailScreen({required this.sensor, super.key});
  @override
  State<SensorDetailScreen> createState() => _SensorDetailScreenState();
}

class _SensorDetailScreenState extends State<SensorDetailScreen> {
  Map<String, dynamic>? _data;
  List<dynamic>? _history;
  bool _loading = false;
  Map<String, dynamic>? _status;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _fetchHistory();
    _fetchStatus();
  }

  Future<void> _fetchData() async {
    print(
      '[_fetchData] GET: ${ApiConstants.sensorLatestSnapshot(widget.sensor.serialNumber)}',
    );
    setState(() => _loading = true);
    try {
      final res = await authorizedRequest(
        'GET',
        Uri.parse(
          ApiConstants.sensorLatestSnapshot(widget.sensor.serialNumber),
        ),
      );
      print('[_fetchData] status: \'${res?.statusCode}\', body: ${res?.body}');
      if (res?.statusCode == 200) {
        setState(() {
          _data = json.decode(res?.body ?? '{}');
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

  Future<void> _fetchHistory() async {
    // 최근 1시간 스냅샷 (start, end)
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day, now.hour);
    final end = start.add(Duration(hours: 1));
    final startStr = start.toIso8601String();
    final endStr = end.toIso8601String();
    print(
      '[_fetchHistory] GET: '
      '${ApiConstants.sensorHourlySnapshot(widget.sensor.serialNumber, startStr, endStr)}',
    );
    try {
      final res = await authorizedRequest(
        'GET',
        Uri.parse(
          ApiConstants.sensorHourlySnapshot(
            widget.sensor.serialNumber,
            startStr,
            endStr,
          ),
        ),
      );
      print(
        '[_fetchHistory] status: \'${res?.statusCode}\', body: ${res?.body}',
      );
      if (res?.statusCode == 200) {
        setState(() {
          _history = json.decode(res?.body ?? '[]');
        });
      }
    } catch (e) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _fetchStatus() async {
    print(
      '[fetchStatus] GET: /sensor/status?deviceSerialNumber=${widget.sensor.serialNumber}',
    );
    try {
      final res = await authorizedRequest(
        'GET',
        Uri.parse(
          '${ApiConstants.baseUrl}/sensor/status?deviceSerialNumber=${widget.sensor.serialNumber}',
        ),
      );
      print('[fetchStatus] status: \'${res?.statusCode}\', body: ${res?.body}');
      if (res?.statusCode == 200) {
        try {
          final decoded = json.decode(res?.body ?? '{}');
          setState(() {
            _status = decoded is Map<String, dynamic> ? decoded : null;
          });
        } catch (e) {
          print('센서 상태 JSON 파싱 에러: $e');
          setState(() {
            _status = null;
          });
        }
      }
    } catch (e) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _deleteSensor() async {
    setState(() => _loading = true);
    final body = {
      'serialNumber': widget.sensor.serialNumber,
      // roomId는 필요시 별도 전달(예: widget.sensor.roomId)
    };
    try {
      await authorizedRequest(
        'DELETE',
        Uri.parse(ApiConstants.sensorDelete),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );
      setState(() => _loading = false);
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _loading = false);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.sensor.name} 상세',
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.sensor.name,
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(color: Colors.white),
                        ),
                        const Divider(
                          color: Colors.white24,
                          thickness: 1,
                          height: 28,
                        ),
                        Text(
                          '실시간 데이터',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: Colors.white70),
                        ),
                        const SizedBox(height: 8),
                        _data != null
                            ? Text(
                              _data.toString(),
                              style: const TextStyle(color: Colors.white),
                            )
                            : const Text(
                              '데이터 없음',
                              style: TextStyle(color: Colors.white70),
                            ),
                        const SizedBox(height: 20),
                        const Divider(
                          color: Colors.white24,
                          thickness: 1,
                          height: 28,
                        ),
                        Text(
                          '이력',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: Colors.white70),
                        ),
                        const SizedBox(height: 8),
                        _history != null
                            ? Column(
                              children:
                                  _history!
                                      .map(
                                        (e) => Text(
                                          e.toString(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                      )
                                      .toList(),
                            )
                            : const Text(
                              '이력 없음',
                              style: TextStyle(color: Colors.white70),
                            ),
                        const SizedBox(height: 20),
                        const Divider(
                          color: Colors.white24,
                          thickness: 1,
                          height: 28,
                        ),
                        Text(
                          '실시간 데이터(상태)',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: Colors.white70),
                        ),
                        const SizedBox(height: 8),
                        _status != null
                            ? Text(
                              _status.toString(),
                              style: const TextStyle(color: Colors.white),
                            )
                            : const Text(
                              '상태 정보 없음',
                              style: TextStyle(color: Colors.white70),
                            ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.error,
                          ),
                          onPressed: _deleteSensor,
                          child: const Text(
                            '센서 삭제',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }
}
