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
import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:provider/provider.dart';
import 'air_quality_detail_page.dart';
import '../models/room.dart';

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
    Uri.parse('${ApiConstants.baseUrl}/thinq/devices/registered/$roomId'),
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
  for (final device in devices) {
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

Future<List<Map<String, dynamic>>> fetchNotifications() async {
  final res = await authorizedRequest(
    'GET',
    Uri.parse('${ApiConstants.baseUrl}/notifications'),
  );
  if (res?.statusCode == 200) {
    final List data = json.decode(res?.body ?? '[]');
    return data.cast<Map<String, dynamic>>();
  } else {
    throw Exception('알림 불러오기 실패');
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
  int? _scoreValue;
  String? _scoreStatus;
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
        fetchAndSetScore();
      }
    });
  }

  void fetchAndSetScore() async {
    if (selectedRoomId == null) return;
    try {
      final score = await fetchRoomScore(selectedRoomId!);
      setState(() {
        _scoreValue = score.value;
        _scoreStatus = score.status;
      });
    } catch (_) {
      setState(() {
        _scoreValue = null;
        _scoreStatus = null;
      });
    }
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
    fetchAndSetScore();
    // Provider로 기기 리스트 fetch
    final deviceProvider = Provider.of<DeviceProvider>(context, listen: false);
    deviceProvider.fetchDevices(selectedRoomId!);
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

  void _showNotificationsDialog() async {
    try {
      final notifications = await fetchNotifications();
      showDialog(
        context: context,
        builder:
            (context) => Dialog(
              backgroundColor: const Color(0xFF222B45),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                width: 340,
                constraints: BoxConstraints(maxHeight: 480),
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 18,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.notifications,
                          color: Colors.white,
                          size: 28,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '알림',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Spacer(),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.white54),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white24, height: 24),
                    if (notifications.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: Text(
                            '알림이 없습니다.',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: notifications.length,
                          separatorBuilder:
                              (_, __) => Divider(color: Colors.white12),
                          itemBuilder: (context, i) {
                            final n = notifications[i];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                n['title'] ?? '-',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                n['message'] ?? n['body'] ?? '',
                                style: TextStyle(color: Colors.white70),
                              ),
                              trailing: Text(
                                n['createdAt'] != null
                                    ? n['createdAt']
                                        .toString()
                                        .substring(0, 16)
                                        .replaceAll('T', ' ')
                                    : '',
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
      );
    } catch (e) {
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              backgroundColor: Colors.grey[900],
              title: Text('알림 오류', style: TextStyle(color: Colors.white)),
              content: Text(
                '알림을 불러올 수 없습니다.\n$e',
                style: TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('닫기', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      // appBar: AppBar(
      //   title: const Text('스마트에어', style: TextStyle(color: Colors.white)),
      //   backgroundColor: Colors.transparent,
      //   elevation: 0,
      //   iconTheme: const IconThemeData(color: Colors.white),
      // ),
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
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: controller0,
                    builder: (context, child) {
                      final color =
                          (_scoreValue != null)
                              ? scoreColor(_scoreValue!)
                              : Colors.white;
                      return CustomPaint(
                        size: MediaQuery.of(context).size,
                        painter: _CircleGradientPainterDark(
                          progress: controller0.value,
                          gradientColors: [color, color],
                        ),
                      );
                    },
                  ),
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(color: Colors.transparent),
                  ),
                ],
              ),
            ),
          // 공기 점수 (화면 정중앙)
          Center(
            child: GestureDetector(
              onTap: () async {
                if (selectedRoomId != null && rooms0.isNotEmpty) {
                  final roomMap = rooms0.firstWhere(
                    (r) => r['id'] == selectedRoomId,
                    orElse: () => null,
                  );
                  if (roomMap == null) return;
                  final room = Room.fromJson(roomMap);
                  List sensors = [];
                  if (roomMap.containsKey('sensors')) {
                    sensors = roomMap['sensors'] ?? [];
                  } else {
                    // API로 센서 목록 조회
                    try {
                      final res = await authorizedRequest(
                        'GET',
                        Uri.parse(
                          '${ApiConstants.baseUrl}/api/room/${room.id}/sensors',
                        ),
                      );
                      if (res?.statusCode == 200) {
                        final data = json.decode(res?.body ?? '[]');
                        if (data is List) sensors = data;
                      }
                    } catch (_) {}
                  }
                  if (sensors.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => AirQualityDetailPage(
                              room: room,
                              sensors: sensors,
                            ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '이 방에 등록된 센서가 없습니다.',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    );
                  }
                }
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '공기 점수',
                    style: TextStyle(fontSize: 14, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  if (_scoreValue == null)
                    const Text(
                      '점수 데이터 없음',
                      style: TextStyle(color: Colors.white70),
                    )
                  else
                    Column(
                      children: [
                        AnimatedFlipCounter(
                          duration: const Duration(milliseconds: 700),
                          value: _scoreValue ?? 0,
                          textStyle: TextStyle(
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
                                  _scoreValue ?? 0,
                                ).withOpacity(0.4),
                                blurRadius: 18,
                                offset: Offset(0, 0),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 10),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          transitionBuilder:
                              (child, animation) => FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                          child: Text(
                            _scoreStatus ?? '',
                            key: ValueKey(_scoreStatus),
                            style: TextStyle(
                              fontSize: 18,
                              color: statusColor(_scoreStatus ?? ''),
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
                                    _scoreValue ?? 0,
                                  ).withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: Offset(0, 0),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
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
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => NotificationListPage(),
                                ),
                              );
                            },
                            child: Icon(
                              Icons.notifications,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 16),
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
                Consumer<DeviceProvider>(
                  builder: (context, deviceProvider, _) {
                    if (deviceProvider.loading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final filteredDevices = deviceProvider.devices;
                    if (filteredDevices.isEmpty) {
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
                              child: SizedBox(
                                width: double.infinity,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
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
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children:
                              filteredDevices.map((device) {
                                final isOn = device.isActive == true;
                                String roomName =
                                    rooms0.firstWhere(
                                      (r) => r['id'] == selectedRoomId,
                                      orElse: () => {'name': '-'},
                                    )['name'] ??
                                    '-';
                                final deviceProvider =
                                    Provider.of<DeviceProvider>(context);
                                final isLoading =
                                    deviceProvider.deviceLoading[device.id] ==
                                    true;
                                return Stack(
                                  children: [
                                    GestureDetector(
                                      onTap:
                                          isLoading
                                              ? null
                                              : () async {
                                                await Provider.of<
                                                  DeviceProvider
                                                >(
                                                  context,
                                                  listen: false,
                                                ).toggleDevice(device.id);
                                              },
                                      child: AnimatedOpacity(
                                        duration: Duration(milliseconds: 200),
                                        opacity: 1.0,
                                        child: Container(
                                          width: 120,
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 8,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 18,
                                            horizontal: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                isOn
                                                    ? Color(0xFF3971FF)
                                                    : Colors.grey[900],
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color:
                                                    isOn
                                                        ? Color(
                                                          0xFF3971FF,
                                                        ).withOpacity(0.18)
                                                        : Colors.black
                                                            .withOpacity(0.12),
                                                blurRadius: 16,
                                                offset: Offset(0, 6),
                                              ),
                                            ],
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                width: 48,
                                                height: 48,
                                                decoration: BoxDecoration(
                                                  color:
                                                      isOn
                                                          ? Colors.white
                                                          : Colors.white12,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  Icons
                                                      .air, // 또는 Icons.power_settings_new
                                                  color:
                                                      isOn
                                                          ? Color(0xFF3971FF)
                                                          : Colors.white54,
                                                  size: 32,
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              Text(
                                                device.name,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                ),
                                                textAlign: TextAlign.center,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                isOn ? '켜짐' : '꺼짐',
                                                style: TextStyle(
                                                  color:
                                                      isOn
                                                          ? Colors.white
                                                          : Colors.white54,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (isLoading)
                                      Positioned.fill(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          child: BackdropFilter(
                                            filter: ImageFilter.blur(
                                              sigmaX: 8,
                                              sigmaY: 8,
                                            ),
                                            child: Container(
                                              color: Colors.black.withOpacity(
                                                0.18,
                                              ),
                                              child: const Center(
                                                child: CircularProgressIndicator(
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                        Color
                                                      >(Colors.white),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              }).toList(),
                        ),
                      ),
                    );
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

// 알림 전체화면 페이지
class NotificationListPage extends StatelessWidget {
  const NotificationListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('알림', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                '알림을 불러올 수 없습니다.',
                style: TextStyle(color: Colors.white70),
              ),
            );
          } else if (snapshot.hasData) {
            final notifications = snapshot.data!;
            if (notifications.isEmpty) {
              return Center(
                child: Text(
                  '알림이 없습니다.',
                  style: TextStyle(color: Colors.white70),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => Divider(color: Colors.white12),
              itemBuilder: (context, i) {
                final n = notifications[i];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 8,
                  ),
                  title: Text(
                    n['title'] ?? '-',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    n['message'] ?? n['body'] ?? '',
                    style: TextStyle(color: Colors.white70),
                  ),
                  trailing: Text(
                    n['createdAt'] != null
                        ? n['createdAt']
                            .toString()
                            .substring(0, 16)
                            .replaceAll('T', ' ')
                        : '',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                );
              },
            );
          } else {
            return Center(
              child: Text('알림 없음', style: TextStyle(color: Colors.white70)),
            );
          }
        },
      ),
    );
  }
}
