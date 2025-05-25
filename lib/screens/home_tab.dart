import 'package:flutter/material.dart';
import 'dart:ui';
import '../widgets/smart_air_bottom_nav_bar.dart';
import '../utils/api_constants.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/api_client.dart';

class Device {
  final int deviceId;
  final String alias;
  Device({required this.deviceId, required this.alias});
  factory Device.fromJson(Map<String, dynamic> json) => Device(
    deviceId:
        json['deviceId'] is int
            ? json['deviceId']
            : int.tryParse(json['deviceId'].toString()) ?? 0,
    alias: json['alias'] ?? '',
  );
}

class Score {
  final int value;
  final String status;
  Score({required this.value, required this.status});
  factory Score.fromJson(Map<String, dynamic> json) =>
      Score(value: json['score'] ?? 0, status: json['status'] ?? '');
}

Future<Score> fetchRoomScore(int roomId) async {
  final uri = Uri.parse(
    ApiConstants.roomScore(roomId),
  ).replace(queryParameters: {'page': '0', 'size': '10', 'sort': 'id,desc'});
  final res = await authorizedRequest('GET', uri);
  if (res.statusCode == 200) {
    final data = json.decode(res.body);
    if (data is Map && data['content'] is List && data['content'].isNotEmpty) {
      final latest = data['content'].last;
      final scoreValue = (latest['overallScore'] as num?)?.toInt() ?? 0;
      // 점수 구간별 상태 한글 가공
      String status;
      if (scoreValue >= 90) {
        status = '매우 좋음';
      } else if (scoreValue >= 70) {
        status = '좋음';
      } else if (scoreValue >= 50) {
        status = '보통';
      } else if (scoreValue >= 30) {
        status = '나쁨';
      } else {
        status = '매우 나쁨';
      }
      return Score(value: scoreValue, status: status);
    } else {
      // 점수 데이터 없음: null 반환
      return Future.error('NO_SCORE_DATA');
    }
  } else {
    throw Exception('점수 불러오기 실패');
  }
}

Future<List<Device>> fetchDeviceList(int roomId) async {
  final res = await authorizedRequest(
    'GET',
    Uri.parse(ApiConstants.deviceList(roomId)),
  );
  if (res.statusCode == 200) {
    final List data = json.decode(res.body);
    return data.map((e) => Device.fromJson(e)).toList();
  } else {
    throw Exception('기기 목록 불러오기 실패');
  }
}

Future<void> toggleDevice(int deviceId) async {
  try {
    final res = await authorizedRequest(
      'POST',
      Uri.parse('${ApiConstants.baseUrl}/thinq/power/$deviceId'),
    );
    if (res.statusCode != 200) {
      throw Exception('기기 제어 실패');
    }
  } catch (e) {
    rethrow;
  }
}

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> with SingleTickerProviderStateMixin {
  List<dynamic> _rooms = [];
  int? _selectedRoomId;
  Map<String, dynamic>? _user;
  late AnimationController _controller;
  Future<Score>? _scoreFuture;
  Future<List<Device>>? _deviceFuture;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _fetchRoomsAndInit();
    _fetchUser();
  }

  Future<void> _fetchRoomsAndInit() async {
    final res = await authorizedRequest(
      'GET',
      Uri.parse(ApiConstants.roomList),
    );
    if (res.statusCode == 200) {
      final rooms = json.decode(res.body);
      setState(() {
        _rooms = rooms;
        if (_rooms.isNotEmpty) {
          final validIds =
              _rooms
                  .where((r) => r['id'] is int)
                  .map<int>((r) => r['id'] as int)
                  .toSet();
          if (_selectedRoomId == null || !validIds.contains(_selectedRoomId)) {
            _selectedRoomId = _rooms[0]['id'];
          }
          _refreshRoomData();
        }
      });
    }
  }

  void _onRoomSelected(int? roomId) {
    if (roomId == null) return;
    setState(() {
      _selectedRoomId = roomId;
      _refreshRoomData();
    });
  }

  void _refreshRoomData() {
    if (_selectedRoomId == null) return;
    _scoreFuture = fetchRoomScore(_selectedRoomId!);
    _deviceFuture = fetchDeviceList(_selectedRoomId!);
  }

  Future<void> _fetchUser() async {
    try {
      final res = await authorizedRequest(
        'GET',
        Uri.parse(ApiConstants.userInfo),
      );
      if (res.statusCode == 200) {
        setState(() {
          _user = json.decode(res.body);
        });
      }
    } catch (e) {
      // ignore
    }
  }

  @override
  void dispose() {
    if (_controller.isAnimating) {
      _controller.stop();
    }
    _controller.dispose();
    super.dispose();
  }

  Color _scoreColor(int value) {
    if (value >= 90) {
      return const Color(0xFF3971FF); // 매우 좋음: 파랑
    } else if (value >= 70) {
      return Colors.green; // 좋음
    } else if (value >= 50) {
      return Colors.yellow; // 보통
    } else if (value >= 30) {
      return Colors.orange; // 나쁨
    } else {
      return Colors.red; // 매우 나쁨
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 배경 그라데이션
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black, Colors.transparent],
              ),
            ),
          ),
          // 공기 점수 뒤 애니메이션 원
          if (_controller.isAnimating)
            FutureBuilder<Score>(
              future: _scoreFuture,
              builder: (context, snapshot) {
                final color =
                    (snapshot.hasData)
                        ? _scoreColor(snapshot.data!.value)
                        : Colors.white;
                return Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          return CustomPaint(
                            size: MediaQuery.of(context).size,
                            painter: _CircleGradientPainterDark(
                              progress: _controller.value,
                              gradientColors: [color, color],
                            ),
                          );
                        },
                      ),
                      BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(color: Colors.transparent),
                      ),
                    ],
                  ),
                );
              },
            ),
          // 공기 점수 (화면 정중앙)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '공기 점수',
                  style: TextStyle(fontSize: 14, color: Colors.white),
                ),
                const SizedBox(height: 8),
                if (_scoreFuture != null)
                  FutureBuilder<Score>(
                    future: _scoreFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      } else if (snapshot.hasError) {
                        if (snapshot.error == 'NO_SCORE_DATA') {
                          return const Text(
                            '점수 데이터 없음',
                            style: TextStyle(color: Colors.white70),
                          );
                        }
                        return Text('점수 오류: \\${snapshot.error}');
                      } else if (snapshot.hasData) {
                        final score = snapshot.data!;
                        return Column(
                          children: [
                            Text(
                              score.value.toString(),
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: _scoreColor(score.value),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              score.status,
                              style: TextStyle(
                                fontSize: 15,
                                color: _scoreColor(score.value),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        );
                      } else {
                        return const SizedBox();
                      }
                    },
                  ),
              ],
            ),
          ),
          // UI
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 상단 영역 (임시)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Image.asset('assets/logo.png', width: 24, height: 24),
                          const SizedBox(width: 8),
                        ],
                      ),
                      Row(
                        children: const [
                          Icon(Icons.notifications, color: Colors.white),
                          SizedBox(width: 16),
                          Icon(Icons.person, color: Colors.white),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // 방 선택 드롭다운
                if (_rooms.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Builder(
                      builder: (context) {
                        final validRoomIds =
                            _rooms
                                .where((r) => r['id'] is int)
                                .map<int>((r) => r['id'] as int)
                                .toSet();
                        final dropdownItems =
                            validRoomIds.map((id) {
                              final room = _rooms.firstWhere(
                                (r) => r['id'] == id,
                              );
                              return DropdownMenuItem<int>(
                                value: id,
                                child: Text(
                                  room['name'],
                                  style: const TextStyle(color: Colors.white),
                                ),
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
                                _refreshRoomData();
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
                  ),
                // 인사말
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: RichText(
                    text: TextSpan(
                      text: '안녕하세요. ',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      children: [
                        TextSpan(
                          text: _user?['username'] ?? '유저님',
                          style: const TextStyle(color: Color(0xFF3971FF)),
                        ),
                        const TextSpan(text: '\n오늘의 점수를 확인하세요.'),
                      ],
                    ),
                  ),
                ),
                // const SizedBox(height: 24),
                Spacer(),
                // 기기 카드
                if (_deviceFuture != null)
                  FutureBuilder<List<Device>>(
                    future: _deviceFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Text('기기 오류: \\${snapshot.error}');
                      } else if (snapshot.hasData) {
                        final devices = snapshot.data!;
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children:
                              devices.map((device) {
                                return GestureDetector(
                                  onTap: () async {
                                    try {
                                      await toggleDevice(device.deviceId);
                                      _refreshRoomData();
                                    } catch (e) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(content: Text('기기 제어 실패: $e')),
                                      );
                                    }
                                  },
                                  child: Card(
                                    color: Colors.black.withOpacity(0.2),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        children: [
                                          Icon(Icons.air, color: Colors.white),
                                          Text(
                                            device.alias,
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                        );
                      } else {
                        return const SizedBox();
                      }
                    },
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleGradientPainterDark extends CustomPainter {
  final double progress;
  final List<Color> gradientColors;
  _CircleGradientPainterDark({
    required this.progress,
    required this.gradientColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    _drawLayer(canvas, center, size.width * 0.3 + (15 * progress), [
      Color.lerp(
        gradientColors[0],
        gradientColors[1],
        progress,
      )!.withOpacity(0.7),
      Color.lerp(
        gradientColors[1],
        gradientColors[0],
        progress,
      )!.withOpacity(0.4),
      Colors.transparent,
    ]);
    _drawLayer(canvas, center, size.width * 0.4 + (20 * progress), [
      Color.lerp(
        gradientColors[1],
        gradientColors[0],
        progress,
      )!.withOpacity(0.5),
      Color.lerp(
        gradientColors[0],
        gradientColors[1],
        progress,
      )!.withOpacity(0.3),
      Colors.transparent,
    ]);
    _drawLayer(canvas, center, size.width * 0.5 + (25 * progress), [
      Color.lerp(
        gradientColors[1],
        gradientColors[0],
        progress,
      )!.withOpacity(0.3),
      Colors.transparent,
    ]);
  }

  void _drawLayer(
    Canvas canvas,
    Offset center,
    double radius,
    List<Color> colors,
  ) {
    final Rect rect = Rect.fromCircle(center: center, radius: radius);
    final Gradient gradient = RadialGradient(
      center: Alignment.center,
      radius: 1.0,
      colors: colors,
      stops: List.generate(
        colors.length,
        (index) => index / (colors.length - 1),
      ),
    );
    final Paint paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _CircleGradientPainterDark oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _DeviceCard extends StatelessWidget {
  final String room;
  final String device;
  final bool active;
  const _DeviceCard({
    required this.room,
    required this.device,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF3971FF) : Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (active)
            BoxShadow(
              color: const Color(0xFF3971FF).withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.power_settings_new, color: Colors.white, size: 32),
          const SizedBox(height: 8),
          Text(
            device,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            room,
            style: const TextStyle(fontSize: 11, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
