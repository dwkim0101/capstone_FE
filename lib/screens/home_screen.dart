import 'package:flutter/material.dart';
import 'dart:ui';
import '../widgets/smart_air_bottom_nav_bar.dart';

class SmartAirHome extends StatefulWidget {
  const SmartAirHome({super.key});

  @override
  State<SmartAirHome> createState() => _SmartAirHomeState();
}

class _SmartAirHomeState extends State<SmartAirHome>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _selectedIndex = 0;
  int _selectedHomeIndex = 0;
  late List<bool> _deviceActive;

  final List<Map<String, dynamic>> _homesData = [
    {
      'name': '김도완의 집',
      'score': 92,
      'devices': ['방 공기청정기', '거실 공기청정기', '주방 공기청정기'],
      'gradientColors': [Color(0xFF141417), Color(0xFF05052D)],
    },
    {
      'name': '부모님 댁',
      'score': 75,
      'devices': ['거실 공기청정기', '안방 공기청정기'],
      'gradientColors': [Color(0xFF1A237E), Color(0xFF283593)],
    },
    {
      'name': '사무실',
      'score': 60,
      'devices': ['사무실 공기청정기'],
      'gradientColors': [Color(0xFF263238), Color(0xFF607D8B)],
    },
    {
      'name': '세컨드 하우스',
      'score': 40,
      'devices': ['세컨드룸 공기청정기'],
      'gradientColors': [Color(0xFF4A148C), Color(0xFF880E4F)],
    },
  ];

  Map<String, dynamic> _getScoreStatus(int score) {
    if (score >= 90) {
      return {
        'text': '매우좋음',
        'color': const Color(0xFF3971FF),
        'animationColors': [const Color(0xFF2241C6), const Color(0xFF3971FF)],
      };
    } else if (score >= 70) {
      return {
        'text': '좋음',
        'color': const Color(0xFF4FC3F7),
        'animationColors': [const Color(0xFF1A237E), const Color(0xFF4FC3F7)],
      };
    } else if (score >= 50) {
      return {
        'text': '보통',
        'color': const Color(0xFFFFC107),
        'animationColors': [const Color(0xFF607D8B), const Color(0xFFFFC107)],
      };
    } else {
      return {
        'text': '나쁨',
        'color': const Color(0xFFFF5252),
        'animationColors': [const Color(0xFF880E4F), const Color(0xFFFF5252)],
      };
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    // 기기 활성화 상태 초기화
    _deviceActive = List.generate(
      _homesData[_selectedHomeIndex]['devices'].length,
      (_) => true,
    );

    // 디버깅 메시지 추가
    _controller.addListener(() {
      // debugPrint('Animation progress: ${_controller.value}');
    });
  }

  @override
  void didUpdateWidget(covariant SmartAirHome oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 집이 바뀌면 기기 활성화 상태도 새로 초기화
    _deviceActive = List.generate(
      _homesData[_selectedHomeIndex]['devices'].length,
      (_) => true,
    );
  }

  @override
  void dispose() {
    if (_controller.isAnimating) {
      _controller.stop(); // 애니메이션 중지
    }
    _controller.dispose(); // 컨트롤러 정리
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final home = _homesData[_selectedHomeIndex];
    final score = home['score'] as int;
    final status = _getScoreStatus(score);
    final devices = home['devices'] as List<String>;
    final List<Color> gradientColors = home['gradientColors'] as List<Color>;

    return Scaffold(
      backgroundColor: gradientColors.last,
      body: Stack(
        children: [
          // 배경 그라데이션
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: gradientColors,
              ),
            ),
          ),
          // 공기 점수 뒤 애니메이션 원
          if (_controller.isAnimating)
            Center(
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
                          gradientColors: status['animationColors'],
                        ),
                      );
                    },
                  ),
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      color: Colors.transparent,
                    ), // Ensure no unintended background color
                  ),
                ],
              ),
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
                Text(
                  score.toString(),
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  status['text'],
                  style: TextStyle(
                    fontSize: 15,
                    color: status['color'],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // UI
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 상단 영역
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Image.asset(
                            'assets/logo.png', // 기존 SvgPicture.asset을 Image.asset으로 변경
                            width: 24,
                            height: 24,
                          ),
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
                Padding(
                  padding: const EdgeInsets.only(left: 12.0),
                  child: GestureDetector(
                    onTap: () async {
                      final selected = await showModalBottomSheet<int>(
                        context: context,
                        backgroundColor: Colors.black.withOpacity(0.9),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        builder: (context) {
                          return ListView(
                            shrinkWrap: true,
                            children:
                                _homesData.asMap().entries.map((entry) {
                                  final idx = entry.key;
                                  final home = entry.value;
                                  return ListTile(
                                    title: Text(
                                      home['name'],
                                      style: TextStyle(
                                        color:
                                            idx == _selectedHomeIndex
                                                ? const Color(0xFF3971FF)
                                                : Colors.white,
                                        fontWeight:
                                            idx == _selectedHomeIndex
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                      ),
                                    ),
                                    trailing:
                                        idx == _selectedHomeIndex
                                            ? const Icon(
                                              Icons.check,
                                              color: Color(0xFF3971FF),
                                            )
                                            : null,
                                    onTap: () => Navigator.pop(context, idx),
                                  );
                                }).toList(),
                          );
                        },
                      );
                      if (selected != null && selected != _selectedHomeIndex) {
                        setState(() {
                          _selectedHomeIndex = selected;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              _homesData[_selectedHomeIndex]['name'],
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 12,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // 인사말
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: RichText(
                    text: const TextSpan(
                      text: '안녕하세요. ',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      children: [
                        TextSpan(
                          text: '김도완님',
                          style: TextStyle(color: Color(0xFF3971FF)),
                        ),
                        TextSpan(text: '\n오늘의 점수는 좋음입니다.'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 기기 카드
          Positioned(
            left: 0,
            right: 0,
            bottom: 80, // 하단바 바로 위에 위치
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  devices.length,
                  (i) => GestureDetector(
                    onTap: () {
                      setState(() {
                        _deviceActive[i] = !_deviceActive[i];
                      });
                    },
                    child: _DeviceCard(
                      room: home['name'],
                      device: devices[i],
                      active: _deviceActive[i],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SmartAirBottomNavBar(
        selectedIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
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

    // 첫 번째 레이어
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

    // 두 번째 레이어
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

    // 세 번째 레이어
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
