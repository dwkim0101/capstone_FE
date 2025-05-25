import 'package:flutter/material.dart';
import '../utils/api_constants.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sensor.dart';
import '../utils/api_client.dart';

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
    final res = await authorizedRequest(
      'GET',
      Uri.parse(ApiConstants.sensorLatestSnapshot(widget.sensor.serialNumber)),
    );
    print('[_fetchData] status: \'${res.statusCode}\', body: ${res.body}');
    if (res.statusCode == 200) {
      setState(() {
        _data = json.decode(res.body);
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _fetchHistory() async {
    // 예시: 최근 1시간 스냅샷 (실제 시간대는 동적으로 생성 필요)
    final now = DateTime.now();
    final hour = DateTime(now.year, now.month, now.day, now.hour);
    final snapshotHour = hour.toIso8601String();
    print(
      '[_fetchHistory] GET: ${ApiConstants.sensorHourlySnapshot(widget.sensor.serialNumber, snapshotHour)}',
    );
    final res = await authorizedRequest(
      'GET',
      Uri.parse(
        ApiConstants.sensorHourlySnapshot(
          widget.sensor.serialNumber,
          snapshotHour,
        ),
      ),
    );
    print('[_fetchHistory] status: \'${res.statusCode}\', body: ${res.body}');
    if (res.statusCode == 200) {
      setState(() {
        _history = json.decode(res.body);
      });
    }
  }

  Future<void> _fetchStatus() async {
    print(
      '[fetchStatus] GET: /sensor/status?deviceSerialNumber=${widget.sensor.serialNumber}',
    );
    final res = await authorizedRequest(
      'GET',
      Uri.parse(
        '${ApiConstants.baseUrl}/sensor/status?deviceSerialNumber=${widget.sensor.serialNumber}',
      ),
    );
    print('[fetchStatus] status: \'${res.statusCode}\', body: ${res.body}');
    if (res.statusCode == 200) {
      try {
        final decoded = json.decode(res.body);
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
  }

  Future<void> _deleteSensor() async {
    setState(() => _loading = true);
    final body = {
      'serialNumber': widget.sensor.serialNumber,
      // roomId는 필요시 별도 전달(예: widget.sensor.roomId)
    };
    final res = await authorizedRequest(
      'DELETE',
      Uri.parse(ApiConstants.sensorDelete),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );
    setState(() => _loading = false);
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.sensor.name} 상세')),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(24),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.sensor.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '실시간 데이터',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (_data != null)
                          Text(_data.toString())
                        else
                          const Text('데이터 없음'),
                        const SizedBox(height: 16),
                        Text(
                          '이력',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (_history != null)
                          ..._history!.map((e) => Text(e.toString()))
                        else
                          const Text('이력 없음'),
                        const SizedBox(height: 16),
                        Text(
                          '실시간 데이터(상태)',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (_status != null)
                          Text(_status.toString())
                        else
                          const Text('상태 정보 없음'),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.error,
                          ),
                          onPressed: _deleteSensor,
                          child: const Text('센서 삭제'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }
}
