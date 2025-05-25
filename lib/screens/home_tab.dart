import 'package:flutter/material.dart';
import 'dart:ui';
import '../widgets/smart_air_bottom_nav_bar.dart';
import '../utils/api_constants.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/api_client.dart';
import '../theme/smartair_theme.dart';
import '../models/device.dart';
import 'device_detail_screen.dart';
import 'dart:async';

class Score {
  final int value;
  final String status;
  Score({required this.value, required this.status});
  factory Score.fromJson(Map<String, dynamic> json) =>
      Score(value: json['score'] ?? 0, status: json['status'] ?? '');
}

Future<Score> fetchRoomScore(int roomId) async {
  final uri = Uri.parse(ApiConstants.roomLatestScore(roomId));
  final res = await authorizedRequest('GET', uri);
  if (res?.statusCode == 200) {
    final data = json.decode(res?.body ?? '{}');
    if (data is Map && data['overallScore'] != null) {
      final scoreValue = (data['overallScore'] as num?)?.toInt() ?? 0;
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
    Uri.parse(ApiConstants.thinqDeviceList(roomId)),
  );
  if (res?.statusCode == 200) {
    final List data = json.decode(res?.body ?? '[]');
    return data.map((e) => Device.fromJson(e)).toList();
  } else if (res?.statusCode == 403) {
    throw Exception('403');
  } else {
    throw Exception('기기 목록 불러오기 실패');
  }
}

Future<String> fetchDevicePowerStatus(int deviceId) async {
  final res = await authorizedRequest(
    'GET',
    Uri.parse('${ApiConstants.baseUrl}/thinq/status/$deviceId'),
  );
  if (res?.statusCode == 200) {
    final data = json.decode(res?.body ?? '{}');
    final op = data['response']?['operation']?['airFanOperationMode'];
    if (op == 'POWER_ON') return 'ON';
    if (op == 'POWER_OFF') return 'OFF';
    return 'UNKNOWN';
  } else {
    return 'UNKNOWN';
  }
}

Future<List<Map<String, dynamic>>> fetchDeviceListWithStatus(int roomId) async {
  final devices = await fetchDeviceList(roomId);
  final List<Map<String, dynamic>> result = [];
  // isRegistered==true인 기기만 상태조회
  final registeredDevices =
      devices.where((d) => d.isRegistered == true).toList();
  for (final device in registeredDevices) {
    final status = await fetchDevicePowerStatus(device.id);
    result.add({'device': device, 'status': status});
  }
  return result;
}

Future<void> toggleDevice(int deviceId) async {
  try {
    final res = await authorizedRequest(
      'POST',
      Uri.parse('${ApiConstants.baseUrl}/thinq/power/$deviceId'),
    );
    if (res?.statusCode != 200) {
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
  List<dynamic> rooms0 = [];
  int? selectedRoomId;
  Map<String, dynamic>? user;
  late AnimationController controller0;
  Future<Score>? scoreFuture;
  Future<List<Map<String, dynamic>>>? deviceFutureWithStatus;
  late Timer scoreUpdateTimer;

  @override
  void initState() {
    super.initState();
    controller0 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    fetchRoomsAndInit();
    fetchUser();
    // 점수 실시간 갱신 타이머
    scoreUpdateTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (selectedRoomId != null) {
        setState(() {
          scoreFuture = fetchRoomScore(selectedRoomId!);
        });
      }
    });
  }

  Future<void> fetchRoomsAndInit() async {
    final res = await authorizedRequest(
      'GET',
      Uri.parse(ApiConstants.roomList),
    );
    if (res?.statusCode == 200) {
      final rooms = json.decode(res?.body ?? '[]');
      setState(() {
        rooms0 = rooms;
        if (rooms0.isNotEmpty) {
          final validIds =
              rooms0
                  .where((r) => r['id'] is int)
                  .map<int>((r) => r['id'] as int)
                  .toSet();
          if (selectedRoomId == null || !validIds.contains(selectedRoomId)) {
            selectedRoomId = rooms0[0]['id'];
          }
          refreshRoomData();
        }
      });
    }
  }

  void onRoomSelected(int? roomId) {
    if (roomId == null) return;
    setState(() {
      selectedRoomId = roomId;
      refreshRoomData();
    });
  }

  void refreshRoomData() {
    if (selectedRoomId == null) return;
    scoreFuture = fetchRoomScore(selectedRoomId!);
    deviceFutureWithStatus = fetchDeviceListWithStatus(selectedRoomId!);
  }

  Future<void> fetchUser() async {
    try {
      final res = await authorizedRequest(
        'GET',
        Uri.parse(ApiConstants.userInfo),
      );
      if (res?.statusCode == 200) {
        setState(() {
          user = json.decode(res?.body ?? '{}');
        });
      }
    } catch (e) {
      // ignore
    }
  }

  @override
  void dispose() {
    if (controller0.isAnimating) {
      controller0.stop();
    }
    controller0.dispose();
    scoreUpdateTimer.cancel();
    super.dispose();
  }

  Color scoreColor(int value) {
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

  Color statusColor(String status) {
    switch (status) {
      case '매우 좋음':
        return Colors.white;
      case '좋음':
        return Colors.white;
      case '보통':
        return Colors.white;
      case '나쁨':
        return Colors.white;
      case '매우 나쁨':
        return Colors.white;
      default:
        return Colors.white;
    }
  }

  Future<void> showAddDeviceDialog() async {
    if (selectedRoomId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('방을 먼저 추가하세요.')));
      return;
    }
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text('기기 추가', style: TextStyle(color: Colors.white)),
            content: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: '기기명 입력',
                hintStyle: TextStyle(color: Colors.white54),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
              ),
              cursorColor: Colors.white,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  '취소',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, controller.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF3971FF),
                  foregroundColor: Colors.white,
                ),
                child: const Text('추가', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
    );
    if (result != null && result.trim().isNotEmpty) {
      final res = await authorizedRequest(
        'POST',
        Uri.parse('${ApiConstants.apiBase}/device/add'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'name': result.trim(), 'roomId': selectedRoomId}),
      );
      if (res?.statusCode != 200) {
        String msg = '기기 추가 실패';
        try {
          final data = json.decode(res?.body ?? '{}');
          if (data is Map && data['message'] != null) {
            msg = data['message'].toString();
          }
        } catch (_) {}
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(msg)));
      } else {
        setState(() {
          refreshRoomData();
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('기기 추가 완료')));
      }
    }
  }

  Future<void> showPatRegisterDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text('PAT 등록', style: TextStyle(color: Colors.white)),
            content: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'PAT 값을 입력하세요',
                hintStyle: TextStyle(color: Colors.white54),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
              ),
              cursorColor: Colors.white,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  '취소',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, controller.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF3971FF),
                  foregroundColor: Colors.white,
                ),
                child: const Text('등록', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
    );
    if (result != null && result.trim().isNotEmpty) {
      await registerPat(result.trim());
    }
  }

  Future<void> registerPat(String pat) async {
    final res = await authorizedRequest(
      'POST',
      Uri.parse('${ApiConstants.apiBase}/pat'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'pat': pat}),
    );
    if (res?.statusCode == 200) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('PAT 등록 완료!')));
      refreshRoomData();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('PAT 등록 실패')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Container(color: Colors.black),
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
          // Container(color: Colors.black),
          // 공기 점수 뒤 애니메이션 원
          if (controller0.isAnimating)
            FutureBuilder<Score>(
              future: scoreFuture,
              builder: (context, snapshot) {
                final color =
                    (snapshot.hasData)
                        ? scoreColor(snapshot.data!.value)
                        : Colors.white;
                return Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Container(color: Colors.black),
                      AnimatedBuilder(
                        animation: controller0,
                        builder: (context, child) {
                          return CustomPaint(
                            size: MediaQuery.of(context).size,
                            painter: _CircleGradientPainterDark(
                              progress: controller0.value,
                              gradientColors: [color, color],
                            ),
                          );
                        },
                      ),
                      // Container(color: Colors.black),
                      BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
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
                if (scoreFuture != null)
                  FutureBuilder<Score>(
                    future: scoreFuture,
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
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 600),
                              transitionBuilder:
                                  (child, animation) => ScaleTransition(
                                    scale: animation,
                                    child: child,
                                  ),
                              child: Text(
                                score.value.toString(),
                                key: ValueKey(score.value),
                                style: TextStyle(
                                  fontSize: 54,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 1.5,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.5),
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                    Shadow(
                                      color: scoreColor(
                                        score.value,
                                      ).withOpacity(0.4),
                                      blurRadius: 18,
                                      offset: Offset(0, 0),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              score.status,
                              style: TextStyle(
                                fontSize: 18,
                                color: statusColor(score.status),
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.2,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.4),
                                    blurRadius: 6,
                                    offset: Offset(0, 1),
                                  ),
                                  Shadow(
                                    color: scoreColor(
                                      score.value,
                                    ).withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: Offset(0, 0),
                                  ),
                                ],
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
            // bottom: false,
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
                if (rooms0.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Builder(
                      builder: (context) {
                        final validRoomIds =
                            rooms0
                                .where((r) => r['id'] is int)
                                .map<int>((r) => r['id'] as int)
                                .toSet();
                        final dropdownItems =
                            validRoomIds.map((id) {
                              final room = rooms0.firstWhere(
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
                        int? dropdownValue = selectedRoomId;
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
                            if (selectedRoomId != dropdownValue) {
                              setState(() {
                                selectedRoomId = dropdownValue;
                                refreshRoomData();
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
                            if (v != null) onRoomSelected(v);
                          },
                          hint: const Text(
                            '방 선택',
                            style: TextStyle(color: Colors.white70),
                          ),
                        );
                      },
                    ),
                  ),
                SizedBox(height: 12),
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
                          text: user?['username'] ?? '유저님',
                          style: const TextStyle(color: Color(0xFF3971FF)),
                        ),
                        const TextSpan(text: ' 님. \n현재 대기점수를 확인하세요.'),
                      ],
                    ),
                  ),
                ),
                Spacer(),
                // 기기 카드
                if (deviceFutureWithStatus != null)
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: deviceFutureWithStatus,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Text(
                            '조회중 ...',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        );
                      } else if (snapshot.hasError) {
                        final error = snapshot.error.toString();
                        if (error.contains('403')) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '이 방의 기기 목록을 볼 권한이 없습니다.\n(PAT 등록 필요)',
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 16,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: showPatRegisterDialog,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF3971FF),
                                    foregroundColor: Colors.white,
                                    textStyle: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  child: const Text(
                                    'PAT 등록하기',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return Text('기기 오류: $error');
                      } else if (snapshot.hasData) {
                        final devices = snapshot.data!;
                        final filteredDevices =
                            devices
                                .where(
                                  (item) =>
                                      (item['device'] as Device).isRegistered ==
                                      true,
                                )
                                .toList();
                        if (devices.isEmpty || filteredDevices.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                  sigmaX: 12,
                                  sigmaY: 12,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.12),
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 20,
                                    horizontal: 12,
                                  ),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const SizedBox(height: 8),
                                        Icon(
                                          Icons.devices_other,
                                          color: Colors.white38,
                                          size: 40,
                                        ),
                                        const SizedBox(height: 12),
                                        const Text(
                                          '기기를 추가해주세요.',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        if (rooms0.isEmpty)
                                          const Padding(
                                            padding: EdgeInsets.only(top: 8.0),
                                            child: Text(
                                              '방을 먼저 추가하세요.',
                                              style: TextStyle(
                                                color: Colors.white54,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.12),
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 20,
                                  horizontal: 12,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children:
                                      filteredDevices.map((item) {
                                        final device = item['device'] as Device;
                                        final status = item['status'] as String;
                                        final isOn = status == 'ON';
                                        return Column(
                                          children: [
                                            Container(
                                              decoration: BoxDecoration(
                                                color:
                                                    isOn
                                                        ? Color(0xFF3971FF)
                                                        : Colors.white
                                                            .withOpacity(0.10),
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              child: ListTile(
                                                leading: Container(
                                                  width: 48,
                                                  height: 48,
                                                  decoration: BoxDecoration(
                                                    color:
                                                        isOn
                                                            ? Color(0xFF3971FF)
                                                            : Colors.white
                                                                .withOpacity(
                                                                  0.18,
                                                                ),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Icon(
                                                    Icons.air,
                                                    color:
                                                        isOn
                                                            ? Colors.white
                                                            : Color(0xFF3971FF),
                                                    size: 28,
                                                  ),
                                                ),
                                                title: Text(
                                                  device.name,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                enabled: true,
                                                onTap: () async {
                                                  final result = await Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder:
                                                          (
                                                            _,
                                                          ) => DeviceDetailScreen(
                                                            device: Device(
                                                              id: device.id,
                                                              name: device.name,
                                                              isActive: isOn,
                                                              isRegistered:
                                                                  device
                                                                      .isRegistered,
                                                            ),
                                                          ),
                                                    ),
                                                  );
                                                  if (result == true)
                                                    refreshRoomData();
                                                },
                                                trailing: Switch(
                                                  value: isOn,
                                                  onChanged: (_) async {
                                                    await toggleDevice(
                                                      device.id,
                                                    );
                                                    refreshRoomData();
                                                  },
                                                  activeColor: Color(
                                                    0xFF3971FF,
                                                  ),
                                                  inactiveThumbColor:
                                                      Colors.white54,
                                                  inactiveTrackColor:
                                                      Colors.white24,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                          ],
                                        );
                                      }).toList(),
                                ),
                              ),
                            ),
                          ),
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
    drawLayer(canvas, center, size.width * 0.3 + (15 * progress), [
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
    drawLayer(canvas, center, size.width * 0.4 + (20 * progress), [
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
    drawLayer(canvas, center, size.width * 0.5 + (25 * progress), [
      Color.lerp(
        gradientColors[1],
        gradientColors[0],
        progress,
      )!.withOpacity(0.3),
      Colors.transparent,
    ]);
  }

  void drawLayer(
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
  bool shouldRepaint(_CircleGradientPainterDark oldDelegate) {
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
