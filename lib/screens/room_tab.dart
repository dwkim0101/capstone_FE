import 'package:flutter/material.dart';
import '../utils/api_constants.dart';
import 'dart:convert';
import 'room_detail_screen.dart';
import 'room_add_screen.dart';
import '../models/room.dart';
import '../utils/api_client.dart';
import 'login_screen.dart';
import 'dart:ui';
import '../models/sensor.dart';

Future<List<Room>?> fetchRoomList() async {
  print('[fetchRoomList] GET: \\${ApiConstants.roomList}');
  final res = await authorizedRequest('GET', Uri.parse(ApiConstants.roomList));
  print('[fetchRoomList] status: \'${res?.statusCode}\', body: \\${res?.body}');
  if (res?.statusCode == 200) {
    final List data = json.decode(res?.body ?? '[]');
    return data.map((e) => Room.fromJson(e)).toList();
  } else {
    return null;
  }
}

class RoomTab extends StatefulWidget {
  const RoomTab({super.key});
  @override
  State<RoomTab> createState() => _RoomTabState();
}

class _RoomTabState extends State<RoomTab> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchRooms();
  }

  Future<void> _fetchRooms() async {
    setState(() => _loading = true);
    try {
      final res = await authorizedRequest(
        'GET',
        Uri.parse(ApiConstants.roomList),
      );
      if (res?.statusCode == 200) {
        setState(() => _loading = false);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.15),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '방 관리',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
              child: _AddRoomButton(
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RoomAddScreen()),
                  );
                  if (result == true) _fetchRooms();
                },
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Room>?>(
                future: fetchRoomList(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return _StateMessage(
                      icon: Icons.error_outline,
                      text: '방 목록을 불러올 수 없습니다.',
                      subText: '네트워크 상태를 확인해주세요.',
                      color: Colors.redAccent,
                      onRetry: _fetchRooms,
                    );
                  } else if (snapshot.hasData && snapshot.data != null) {
                    final rooms = snapshot.data!;
                    if (rooms.isEmpty) {
                      return _StateMessage(
                        icon: Icons.meeting_room_outlined,
                        text: '등록된 방이 없습니다.',
                        subText: '상단의 "+ 방 추가" 버튼을 눌러 방을 등록해보세요.',
                        color: Colors.white70,
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 18,
                        childAspectRatio: 1.18,
                        children:
                            rooms
                                .map(
                                  (room) => _RoomCard(
                                    room: room,
                                    onTap: () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (_) =>
                                                  RoomDetailScreen(room: room),
                                        ),
                                      );
                                      if (result == true) _fetchRooms();
                                    },
                                  ),
                                )
                                .toList(),
                      ),
                    );
                  } else {
                    return _StateMessage(
                      icon: Icons.error_outline,
                      text: '알 수 없는 오류',
                      color: Colors.redAccent,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddRoomButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddRoomButton({required this.onTap, super.key});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF3971FF), Color(0xFF6A82FB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: Colors.white, size: 26),
            SizedBox(width: 8),
            Text(
              '방 추가',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  final Room room;
  final VoidCallback onTap;
  const _RoomCard({required this.room, required this.onTap, super.key});

  IconData get roomIcon {
    final name = room.name;
    if (name.contains('침실') || name.contains('방')) return Icons.bed;
    if (name.contains('거실')) return Icons.weekend;
    if (name.contains('주방')) return Icons.kitchen;
    if (name.contains('욕실') || name.contains('화장실')) return Icons.bathtub;
    if (name.contains('서재')) return Icons.menu_book;
    if (name.contains('정원')) return Icons.park;
    return Icons.meeting_room;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF3971FF), Color(0xFF6A82FB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(roomIcon, color: Color(0xFF3971FF), size: 28),
            ),
            const SizedBox(height: 13),
            Text(
              room.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 17,
                letterSpacing: 0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 7),
            FutureBuilder<List<Sensor>?>(
              future: fetchSensorList(room.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Text(
                    '센서 ...',
                    style: TextStyle(color: Colors.white38, fontSize: 13),
                  );
                } else if (snapshot.hasError) {
                  return const Text(
                    '센서 오류',
                    style: TextStyle(color: Colors.redAccent, fontSize: 13),
                  );
                } else if (snapshot.hasData) {
                  final sensors = snapshot.data ?? [];
                  return Text(
                    '센서 ${sensors.length}개',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                } else {
                  return const Text(
                    '센서 0개',
                    style: TextStyle(color: Colors.white38, fontSize: 13),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  final IconData icon;
  final String text;
  final String? subText;
  final Color color;
  final VoidCallback? onRetry;
  const _StateMessage({
    required this.icon,
    required this.text,
    this.subText,
    this.color = Colors.white70,
    this.onRetry,
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 48),
          const SizedBox(height: 16),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subText != null) ...[
            const SizedBox(height: 8),
            Text(
              subText!,
              style: TextStyle(color: Colors.white38, fontSize: 14),
            ),
          ],
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Color(0xFF3971FF),
              ),
              onPressed: onRetry,
              child: const Text('다시 시도'),
            ),
          ],
        ],
      ),
    );
  }
}
