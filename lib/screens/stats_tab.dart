import '../models/room.dart';
import '../models/sensor.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/api_constants.dart';
import 'package:flutter/material.dart';
import '../utils/api_client.dart';
import 'package:flutter/rendering.dart';
import 'dart:async';
import 'package:fl_chart/fl_chart.dart';

class StatsTab extends StatefulWidget {
  const StatsTab({super.key});

  @override
  State<StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends State<StatsTab>
    with AutomaticKeepAliveClientMixin {
  List<Room> _rooms = [];
  int? _selectedRoomId;
  bool _loading = true;
  Map<String, dynamic>? _stats;
  String? _selectedSensorSerial;
  Future<List<Sensor>>? _sensorFuture;

  // 외부 공기질 상태
  Map<String, dynamic>? _externalAirQuality;
  bool _externalLoading = false;
  String? _externalError;

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
      final List data = json.decode(res.body);
      setState(() {
        _rooms = data.map((e) => Room.fromJson(e)).toList();
        if (_rooms.isNotEmpty) {
          final validIds = _rooms.map((r) => r.id).toSet();
          if (_selectedRoomId == null || !validIds.contains(_selectedRoomId)) {
            _selectedRoomId = _rooms[0].id;
          }
          _sensorFuture = fetchSensorList(_selectedRoomId!);
          _fetchRoomLatestScore();
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

  Future<void> _fetchRoomLatestScore() async {
    if (_selectedRoomId == null) return;
    final res = await authorizedRequest(
      'GET',
      Uri.parse(ApiConstants.roomLatestScore(_selectedRoomId!)),
    );
    if (res.statusCode == 200) {
      setState(() {
        _stats = json.decode(res.body);
      });
    }
  }

  Future<void> _fetchExternalAirQuality(double? lat, double? lon) async {
    if (lat == null || lon == null) return;
    setState(() {
      _externalLoading = true;
      _externalError = null;
    });
    try {
      final url = ApiConstants.openWeatherAirPollution(lat, lon);
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        setState(() {
          _externalAirQuality = data;
          _externalLoading = false;
        });
      } else {
        setState(() {
          _externalError = '외부 공기질 데이터를 불러올 수 없습니다.';
          _externalLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _externalError = '외부 공기질 오류: $e';
        _externalLoading = false;
      });
    }
  }

  Room? _findRoomById(List<Room> rooms, int? id) {
    if (id == null) return null;
    for (final r in rooms) {
      if (r.id == id) return r;
    }
    return null;
  }

  void _onRoomSelected(int? roomId) {
    if (roomId == null) return;
    setState(() {
      _selectedRoomId = roomId;
      _sensorFuture = fetchSensorList(roomId);
      _fetchRoomLatestScore();
      final Room? room = _findRoomById(_rooms, roomId);
      if (room != null && room.latitude != null && room.longitude != null) {
        _fetchExternalAirQuality(room.latitude, room.longitude);
      } else {
        setState(() {
          _externalAirQuality = null;
        });
      }
    });
  }

  void _onSensorSelected(String serial) {
    setState(() {
      _selectedSensorSerial = serial;
    });
  }

  Widget _buildAirQualityBarChart(
    Map<String, dynamic> indoor,
    Map<String, dynamic> outdoor,
  ) {
    final List<String> labels = ['PM2.5', 'PM10', 'CO2', 'TVOC'];
    final List<double> indoorValues = [
      (indoor['pm25Score'] ?? 0).toDouble(),
      (indoor['pm10Score'] ?? 0).toDouble(),
      (indoor['eco2Score'] ?? 0).toDouble(),
      (indoor['tvocScore'] ?? 0).toDouble(),
    ];
    final outdoorComp =
        (outdoor['list'] != null && outdoor['list'].isNotEmpty)
            ? outdoor['list'][0]['components'] ?? {}
            : {};
    final List<double> outdoorValues = [
      (outdoorComp['pm2_5'] ?? 0).toDouble(),
      (outdoorComp['pm10'] ?? 0).toDouble(),
      (outdoorComp['co'] ?? 0).toDouble(),
      (outdoorComp['o3'] ?? 0).toDouble(),
    ];
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY:
            [
                  ...indoorValues,
                  ...outdoorValues,
                ].reduce((a, b) => a > b ? a : b) *
                1.2 +
            1,
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 32),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= labels.length) return const SizedBox();
                return Text(
                  labels[idx],
                  style: const TextStyle(color: Colors.white),
                );
              },
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(show: true),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(labels.length, (i) {
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: indoorValues[i],
                color: Colors.blueAccent,
                width: 12,
                borderRadius: BorderRadius.circular(4),
              ),
              BarChartRodData(
                toY: outdoorValues[i],
                color: Colors.orangeAccent,
                width: 12,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
            showingTooltipIndicators: [0, 1],
          );
        }),
        groupsSpace: 24,
      ),
    );
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (_rooms.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '현재 방: \\${_findRoomById(_rooms, _selectedRoomId)?.name ?? '-'}',
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
                        int? dropdownValue = _selectedRoomId;
                        if (dropdownItems.isEmpty) {
                          dropdownValue = null;
                        } else if (dropdownValue == null ||
                            dropdownItems
                                    .where(
                                      (item) => item.value == dropdownValue,
                                    )
                                    .length !=
                                1) {
                          dropdownValue = dropdownItems.first.value;
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (_selectedRoomId != dropdownValue) {
                              setState(() {
                                _selectedRoomId = dropdownValue;
                              });
                            }
                          });
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
                      value:
                          sensors.isEmpty
                              ? null
                              : (sensors
                                          .where(
                                            (s) =>
                                                s.serialNumber ==
                                                _selectedSensorSerial,
                                          )
                                          .length ==
                                      1
                                  ? _selectedSensorSerial
                                  : sensors[0].serialNumber),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '실내/실외 공기질 비교',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(
                      height: 260,
                      child: _buildAirQualityBarChart(
                        _stats!,
                        _externalAirQuality ??
                            {
                              'list': [
                                {
                                  'components': {
                                    'pm2_5': 0,
                                    'pm10': 0,
                                    'co': 0,
                                    'o3': 0,
                                  },
                                },
                              ],
                            },
                      ),
                    ),
                    if (_externalAirQuality == null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          '실외(외부 API) 데이터가 없어 실외 값은 0으로 표시됩니다.',
                          style: TextStyle(
                            color: Colors.orangeAccent,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      '실내(센서) 데이터',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _stats.toString(),
                      style: TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '실외(외부 API) 데이터',
                      style: TextStyle(
                        color: Colors.lightBlueAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_externalLoading) const CircularProgressIndicator(),
                    if (_externalError != null)
                      Text(
                        _externalError!,
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    if (_externalAirQuality != null)
                      Text(
                        _externalAirQuality.toString(),
                        style: TextStyle(color: Colors.lightBlueAccent),
                      ),
                  ],
                ),
              ),
          ],
        ),
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
  print('[fetchSensorList] roomId: $roomId');
  final res = await authorizedRequest(
    'GET',
    Uri.parse(ApiConstants.roomSensors(roomId)),
  );
  print('[fetchSensorList] status: \'${res.statusCode}\', body: ${res.body}');
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
