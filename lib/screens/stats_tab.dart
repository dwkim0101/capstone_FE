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
import '../widgets/statistics_charts.dart';
import 'login_screen.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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
  Future<List<Sensor>?>? _sensorFuture;

  // 외부 공기질 상태
  Map<String, dynamic>? _externalAirQuality;
  bool _externalLoading = false;
  String? _externalError;

  final MapController _miniMapController = MapController();

  @override
  void initState() {
    super.initState();
    _fetchRooms();
  }

  @override
  bool get wantKeepAlive => true;

  Future<void> _fetchRooms() async {
    setState(() => _loading = true);
    try {
      final res = await authorizedRequest(
        'GET',
        Uri.parse(ApiConstants.roomList),
        onAuthFail: () {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        },
      );
      if (res != null && res.statusCode == 200) {
        final List data = json.decode(res.body);
        setState(() {
          _rooms = data.map((e) => Room.fromJson(e)).toList();
          if (_rooms.isNotEmpty) {
            final validIds = _rooms.map((r) => r.id).toSet();
            if (_selectedRoomId == null ||
                !validIds.contains(_selectedRoomId)) {
              _selectedRoomId = _rooms[0].id;
            }
            _sensorFuture = fetchSensorList(
              _selectedRoomId!,
              onAuthFail: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
            );
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
    } catch (e) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _fetchRoomLatestScore() async {
    if (_selectedRoomId == null) return;
    try {
      final res = await authorizedRequest(
        'GET',
        Uri.parse(ApiConstants.roomLatestScore(_selectedRoomId!)),
        onAuthFail: () {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        },
      );
      if (res != null && res.statusCode == 200) {
        setState(() {
          _stats = json.decode(res.body);
        });
      }
    } catch (e) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
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
      _selectedSensorSerial = null;
      _sensorFuture = fetchSensorList(
        roomId,
        onAuthFail: () {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        },
      );
      _fetchRoomLatestScore();
      final Room? room = _findRoomById(_rooms, roomId);
      if (room != null && room.latitude != null && room.longitude != null) {
        _fetchExternalAirQuality(room.latitude, room.longitude);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _miniMapController.move(
            LatLng(room.latitude!, room.longitude!),
            14.0,
          );
        });
      } else {
        _externalAirQuality = null;
      }
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
    return DefaultTabController(
      length: 8,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('통계', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: Colors.blueAccent,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(text: '종합'),
              Tab(text: '실내/실외'),
              Tab(text: '시간별'),
              Tab(text: '일별'),
              Tab(text: '주간'),
              Tab(text: '이상치'),
              Tab(text: '예측'),
              Tab(text: '만족도'),
            ],
          ),
        ),
        body:
            _loading
                ? const Center(
                  child: Text(
                    '조회중 ...',
                    style: TextStyle(color: Colors.white70),
                  ),
                )
                : _rooms.isEmpty
                ? Center(
                  child: Card(
                    color: Colors.grey[900],
                    margin: const EdgeInsets.all(32),
                    child: const Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        '방을 먼저 추가하세요.',
                        style: TextStyle(color: Colors.white70, fontSize: 18),
                      ),
                    ),
                  ),
                )
                : TabBarView(
                  children: [
                    // 1. 종합 탭: 방/센서 선택 + 모든 차트 세로 배치
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 방 선택 드롭다운
                          _buildRoomDropdown(),
                          const SizedBox(height: 8),
                          // 센서 선택 드롭다운
                          if (_sensorFuture != null)
                            FutureBuilder<List<Sensor>?>(
                              future: _sensorFuture,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: Text(
                                      '센서 조회중 ...',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                  );
                                } else if (snapshot.hasError) {
                                  return const Text(
                                    '센서 목록을 불러올 수 없습니다.',
                                    style: TextStyle(color: Colors.redAccent),
                                  );
                                } else if (snapshot.hasData &&
                                    snapshot.data!.isNotEmpty) {
                                  final sensors = snapshot.data!;
                                  return _buildSensorDropdown(sensors);
                                } else {
                                  return const Text(
                                    '센서 없음',
                                    style: TextStyle(color: Colors.white70),
                                  );
                                }
                              },
                            ),
                          const SizedBox(height: 16),
                          Text(
                            '방 위치',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // 지도 미니맵 (실내/실외 비교 위)
                          _buildRoomMiniMap(),
                          const SizedBox(height: 16),
                          // 실내/실외 비교
                          _buildChartCard(
                            title: '실내/실외 공기질 비교',
                            description:
                                '실내 센서 점수와 실외(OpenWeatherMap) 공기질(PM2.5, PM10, CO2, TVOC) 비교',
                            child: Column(
                              children: [
                                _buildIndoorOutdoorLegend(),
                                const SizedBox(height: 8),
                                Expanded(child: _buildIndoorOutdoorChart()),
                              ],
                            ),
                          ),
                          // 시간별 트렌드
                          _buildChartCard(
                            title: '시간별 트렌드',
                            description: '선택한 센서의 최근 24시간 점수 변화(2시간 단위)',
                            child: _buildHourlyChart(),
                          ),
                          // 일별 트렌드
                          _buildChartCard(
                            title: '일별 트렌드',
                            description: '선택한 센서의 최근 7일간 일평균 점수 변화',
                            child: _buildDailyChart(),
                          ),
                          // 주간 트렌드
                          _buildChartCard(
                            title: '주간 트렌드',
                            description: '선택한 센서의 최근 7주간 주평균 점수 변화',
                            child: _buildWeeklyChart(),
                          ),
                          // 이상치 감지
                          _buildChartCard(
                            title: '이상치 감지',
                            description: '최근 7일간 점수 중 급격한 변화(이상치) 구간을 강조 표시',
                            child: _buildOutlierChart(),
                          ),
                          // 예측
                          _buildChartCard(
                            title: '예측',
                            description:
                                'AI 기반 예측: 향후 5일간 점수 예측(실선: 실제, 점선: 예측)',
                            child: _buildPredictionChart(),
                          ),
                          // 만족도
                          _buildChartCard(
                            title: '만족도',
                            description: '사용자 만족도 설문 결과(만족/보통/불만 비율)',
                            child: _buildSatisfactionChart(),
                          ),
                        ],
                      ),
                    ),
                    // 2. 실내/실외 비교
                    _buildChartTab(_buildIndoorOutdoorChart(), '실내/실외 공기질 비교'),
                    // 3. 시간별
                    _buildChartTab(_buildHourlyChart(), '시간별 트렌드'),
                    // 4. 일별
                    _buildChartTab(_buildDailyChart(), '일별 트렌드'),
                    // 5. 주간
                    _buildChartTab(_buildWeeklyChart(), '주간 트렌드'),
                    // 6. 이상치
                    _buildChartTab(_buildOutlierChart(), '이상치 감지'),
                    // 7. 예측
                    _buildChartTab(_buildPredictionChart(), '예측'),
                    // 8. 만족도
                    _buildChartTab(_buildSatisfactionChart(), '만족도'),
                  ],
                ),
      ),
    );
  }

  // --- UI 빌더 함수들 ---

  Widget _buildRoomDropdown() {
    return DropdownButton<int>(
      value: _selectedRoomId,
      isExpanded: true,
      dropdownColor: Colors.black,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      items:
          _rooms
              .map(
                (room) => DropdownMenuItem<int>(
                  value: room.id,
                  child: Text(room.name),
                ),
              )
              .toList(),
      onChanged: (v) {
        if (v != null) _onRoomSelected(v);
      },
      hint: const Text('방 선택', style: TextStyle(color: Colors.white70)),
    );
  }

  Widget _buildSensorDropdown(List<Sensor> sensors) {
    String? value = _selectedSensorSerial;
    if (value == null || !sensors.any((s) => s.serialNumber == value)) {
      value = sensors.isNotEmpty ? sensors.first.serialNumber : null;
      if (value != _selectedSensorSerial) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _selectedSensorSerial = value);
        });
      }
    }
    return DropdownButton<String>(
      value: value,
      isExpanded: true,
      dropdownColor: Colors.black,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      items:
          sensors
              .map(
                (sensor) => DropdownMenuItem<String>(
                  value: sensor.serialNumber,
                  child: Text(sensor.name),
                ),
              )
              .toList(),
      onChanged: (serial) {
        if (serial != null) _onSensorSelected(serial);
      },
      hint: const Text('센서 선택', style: TextStyle(color: Colors.white70)),
    );
  }

  Widget _buildChartCard({
    required String title,
    required String description,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Card(
        color: Colors.grey[900],
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                description,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 16),
              SizedBox(height: 260, child: child),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChartTab(Widget chart, String title) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        color: Colors.grey[900],
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(height: 260, child: chart),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoomMiniMap() {
    final room = _findRoomById(_rooms, _selectedRoomId);
    if (room == null || room.latitude == null || room.longitude == null) {
      return const SizedBox();
    }
    final latLng = LatLng(room.latitude!, room.longitude!);
    return Card(
      color: Colors.grey[900],
      child: SizedBox(
        height: 180,
        child: FlutterMap(
          mapController: _miniMapController,
          options: MapOptions(
            center: latLng,
            zoom: 14.0,
            interactiveFlags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c'],
            ),
            MarkerLayer(
              markers: [
                Marker(
                  width: 40,
                  height: 40,
                  point: latLng,
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
    );
  }

  // --- 차트 데이터 연동 함수들 (실제 데이터 연동) ---

  Widget _buildIndoorOutdoorChart() {
    if (_stats == null) {
      return const Center(
        child: Text('실내 데이터 없음', style: TextStyle(color: Colors.white70)),
      );
    }
    final indoor = _stats!;
    final outdoor =
        _externalAirQuality ??
        {
          'list': [
            {
              'components': {'pm2_5': 0, 'pm10': 0, 'co': 0, 'o3': 0},
            },
          ],
        };
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
    return IndoorOutdoorBarChart(
      indoorScores: indoorValues,
      outdoorScores: outdoorValues,
      labels: labels,
    );
  }

  Widget _buildHourlyChart() {
    if (_selectedSensorSerial == null) {
      return const Center(
        child: Text('센서를 선택하세요', style: TextStyle(color: Colors.white70)),
      );
    }
    final now = DateTime.now();
    final startTime = now.subtract(const Duration(hours: 24)).toIso8601String();
    final endTime = now.toIso8601String();
    return FutureBuilder<List<dynamic>?>(
      future: fetchHourlySnapshots(_selectedSensorSerial!, startTime, endTime),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingCard();
        }
        if (snapshot.hasError) {
          return _buildErrorCard();
        }
        final data = snapshot.data;
        if (data == null || data.isEmpty) {
          return _buildNoDataCard();
        }
        final hourlyScores =
            data
                .map<double>((e) => (e['overallScore'] ?? 0).toDouble())
                .toList();
        final hourLabels =
            data
                .map<String>((e) => e['snapshotHour']?.substring(11, 13) ?? '')
                .toList();
        return HourlyLineChart(
          hourlyScores: hourlyScores,
          hourLabels: hourLabels,
        );
      },
    );
  }

  Widget _buildDailyChart() {
    if (_selectedSensorSerial == null) {
      return const Center(
        child: Text('센서를 선택하세요', style: TextStyle(color: Colors.white70)),
      );
    }
    final now = DateTime.now();
    final startDate = now
        .subtract(const Duration(days: 6))
        .toIso8601String()
        .substring(0, 10);
    final endDate = now.toIso8601String().substring(0, 10);
    return FutureBuilder<List<dynamic>?>(
      future: fetchDailyReports(_selectedSensorSerial!, startDate, endDate),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingCard();
        }
        if (snapshot.hasError) {
          return _buildErrorCard();
        }
        final data = snapshot.data;
        if (data == null || data.isEmpty) {
          return _buildNoDataCard();
        }
        final dailyScores =
            data
                .map<double>((e) => (e['dailyOverallScore'] ?? 0).toDouble())
                .toList();
        final dayLabels =
            data
                .map<String>((e) => e['reportDate']?.substring(5) ?? '')
                .toList();
        return DailyBarChart(dailyScores: dailyScores, dayLabels: dayLabels);
      },
    );
  }

  Widget _buildWeeklyChart() {
    if (_selectedSensorSerial == null) {
      return const Center(
        child: Text('센서를 선택하세요', style: TextStyle(color: Colors.white70)),
      );
    }
    final now = DateTime.now();
    final startDate = now
        .subtract(const Duration(days: 48))
        .toIso8601String()
        .substring(0, 10); // 7주 전
    final endDate = now.toIso8601String().substring(0, 10);
    return FutureBuilder<List<dynamic>?>(
      future: fetchWeeklyReports(_selectedSensorSerial!, startDate, endDate),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingCard();
        }
        if (snapshot.hasError) {
          return _buildErrorCard();
        }
        final data = snapshot.data;
        if (data == null || data.isEmpty) {
          return _buildNoDataCard();
        }
        final weeklyScores =
            data
                .map<double>((e) => (e['weeklyOverallScore'] ?? 0).toDouble())
                .toList();
        final weekLabels =
            data.map<String>((e) => '${e['weekOfYear']}주').toList();
        return WeeklyAreaChart(
          weeklyScores: weeklyScores,
          weekLabels: weekLabels,
        );
      },
    );
  }

  Widget _buildOutlierChart() {
    if (_selectedSensorSerial == null) {
      return const Center(
        child: Text('센서를 선택하세요', style: TextStyle(color: Colors.white70)),
      );
    }
    final now = DateTime.now();
    final startDate = now
        .subtract(const Duration(days: 6))
        .toIso8601String()
        .substring(0, 10);
    final endDate = now.toIso8601String().substring(0, 10);
    return FutureBuilder<List<dynamic>?>(
      future: fetchAnomalyReports(_selectedSensorSerial!, startDate, endDate),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingCard();
        }
        if (snapshot.hasError) {
          return _buildErrorCard();
        }
        final data = snapshot.data;
        if (data == null || data.isEmpty) {
          return _buildNoDataCard();
        }
        final scores =
            data
                .map<double>((e) => (e['pollutantValue'] ?? 0).toDouble())
                .toList();
        final outlierIndices = List<int>.generate(
          scores.length,
          (i) => i,
        ); // 실제 이상치 인덱스 추출 필요
        final labels =
            data
                .map<String>(
                  (e) => e['anomalyTimestamp']?.substring(5, 10) ?? '',
                )
                .toList();
        return OutlierLineChart(
          scores: scores,
          outlierIndices: outlierIndices,
          labels: labels,
        );
      },
    );
  }

  Widget _buildPredictionChart() {
    if (_selectedSensorSerial == null) {
      return const Center(
        child: Text('센서를 선택하세요', style: TextStyle(color: Colors.white70)),
      );
    }
    return FutureBuilder<dynamic>(
      future: fetchPredictedAirQuality(_selectedSensorSerial!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingCard();
        }
        if (snapshot.hasError) {
          return _buildErrorCard();
        }
        final data = snapshot.data;
        if (data == null) {
          return _buildNoDataCard();
        }
        final actualScores =
            (data['actual'] as List?)
                ?.map<double>((e) => (e ?? 0).toDouble())
                .toList() ??
            [];
        final predictedScores =
            (data['predicted'] as List?)
                ?.map<double>((e) => (e ?? 0).toDouble())
                .toList() ??
            [];
        final labels =
            (data['labels'] as List?)
                ?.map<String>((e) => e.toString())
                .toList() ??
            [];
        return PredictionLineChart(
          actualScores: actualScores,
          predictedScores: predictedScores,
          labels: labels,
        );
      },
    );
  }

  Widget _buildSatisfactionChart() {
    if (_selectedRoomId == null) {
      return const Center(
        child: Text('방을 선택하세요', style: TextStyle(color: Colors.white70)),
      );
    }
    return FutureBuilder<dynamic>(
      future: fetchUserSatisfaction(_selectedRoomId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingCard();
        }
        if (snapshot.hasError) {
          return _buildErrorCard();
        }
        final data = snapshot.data;
        if (data == null) {
          return _buildNoDataCard();
        }
        final satisfied = (data['satisfied'] ?? 0).toDouble();
        final neutral = (data['neutral'] ?? 0).toDouble();
        final dissatisfied = (data['dissatisfied'] ?? 0).toDouble();
        return SatisfactionPieChart(
          satisfied: satisfied,
          neutral: neutral,
          dissatisfied: dissatisfied,
        );
      },
    );
  }

  Widget _buildIndoorOutdoorLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Row(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              '실내',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(width: 16),
        Row(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              '실외',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoadingCard() {
    return const Center(
      child: Text('데이터 로딩중...', style: TextStyle(color: Colors.white70)),
    );
  }

  Widget _buildErrorCard() {
    return const Center(
      child: Text(
        '데이터 로딩 중 오류가 발생했습니다.',
        style: TextStyle(color: Colors.redAccent),
      ),
    );
  }

  Widget _buildNoDataCard() {
    return const Center(
      child: Text('데이터가 없습니다.', style: TextStyle(color: Colors.white70)),
    );
  }
}

Future<List<Room>?> fetchRoomList({void Function()? onAuthFail}) async {
  final res = await authorizedRequest(
    'GET',
    Uri.parse(ApiConstants.roomList),
    onAuthFail: onAuthFail,
  );
  if (res?.statusCode == 200) {
    final List data = json.decode(res?.body ?? '[]');
    return data.map((e) => Room.fromJson(e)).toList();
  } else {
    return null;
  }
}

Future<List<Sensor>?> fetchSensorList(
  int roomId, {
  void Function()? onAuthFail,
}) async {
  print('[fetchSensorList] roomId: $roomId');
  final res = await authorizedRequest(
    'GET',
    Uri.parse(ApiConstants.roomSensors(roomId)),
    onAuthFail: onAuthFail,
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

Future<Map<String, dynamic>?> fetchRoomScore(
  int roomId, {
  void Function()? onAuthFail,
}) async {
  final res = await authorizedRequest(
    'GET',
    Uri.parse(ApiConstants.roomScore(roomId)),
    onAuthFail: onAuthFail,
  );
  if (res?.statusCode == 200) {
    return json.decode(res?.body ?? '{}');
  } else {
    return null;
  }
}

Future<Map<String, dynamic>?> fetchSensorScore(
  String serial, {
  void Function()? onAuthFail,
}) async {
  final res = await authorizedRequest(
    'GET',
    Uri.parse(ApiConstants.sensorScore(serial)),
    onAuthFail: onAuthFail,
  );
  if (res?.statusCode == 200) {
    return json.decode(res?.body ?? '{}');
  } else {
    return null;
  }
}
