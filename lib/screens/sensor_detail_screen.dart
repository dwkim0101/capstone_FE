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

  @override
  void initState() {
    super.initState();
    _fetchData();
    _fetchHistory();
  }

  Future<void> _fetchData() async {
    print(
      '[_fetchData] GET: ${ApiConstants.sensorCreate}/data?id=${widget.sensor.serialNumber}',
    );
    setState(() => _loading = true);
    final res = await authorizedRequest(
      'GET',
      Uri.parse(
        '${ApiConstants.sensorCreate}/data?id=${widget.sensor.serialNumber}',
      ),
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
    print(
      '[_fetchHistory] GET: ${ApiConstants.sensorCreate}/data/history?id=${widget.sensor.serialNumber}',
    );
    final res = await authorizedRequest(
      'GET',
      Uri.parse(
        '${ApiConstants.sensorCreate}/data/history?id=${widget.sensor.serialNumber}',
      ),
    );
    print('[_fetchHistory] status: \'${res.statusCode}\', body: ${res.body}');
    if (res.statusCode == 200) {
      setState(() {
        _history = json.decode(res.body);
      });
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
              : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '실시간 데이터',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (_data != null)
                      Text(_data.toString())
                    else
                      const Text('데이터 없음'),
                    const SizedBox(height: 24),
                    const Text(
                      '이력',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (_history != null)
                      ..._history!.map((e) => Text(e.toString()))
                    else
                      const Text('이력 없음'),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.red,
                      ),
                      onPressed: _deleteSensor,
                      child: const Text('센서 삭제'),
                    ),
                  ],
                ),
              ),
    );
  }
}
