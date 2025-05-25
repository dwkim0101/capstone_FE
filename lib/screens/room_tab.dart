import 'package:flutter/material.dart';
import '../utils/api_constants.dart';
import 'dart:convert';
import 'room_detail_screen.dart';
import 'room_add_screen.dart';
import '../models/room.dart';
import '../utils/api_client.dart';

Future<List<Room>> fetchRoomList() async {
  print('[fetchRoomList] GET: ${ApiConstants.roomList}');
  final res = await authorizedRequest('GET', Uri.parse(ApiConstants.roomList));
  print('[fetchRoomList] status: \'${res.statusCode}\', body: ${res.body}');
  if (res.statusCode == 200) {
    final List data = json.decode(res.body);
    return data.map((e) => Room.fromJson(e)).toList();
  } else {
    throw Exception('방 목록 불러오기 실패');
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
    final res = await authorizedRequest(
      'GET',
      Uri.parse(ApiConstants.roomList),
    );
    if (res.statusCode == 200) {
      setState(() => _loading = false);
    } else {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('방 관리', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'room_fab',
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RoomAddScreen()),
          );
          if (result == true) _fetchRooms();
        },
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<Room>>(
        future: fetchRoomList(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    '방 목록을 불러올 수 없습니다.',
                    style: TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Color(0xFF3971FF),
                    ),
                    onPressed: _fetchRooms,
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            );
          } else if (snapshot.hasData) {
            final rooms = snapshot.data!;
            if (rooms.isEmpty) {
              return const Center(
                child: Text(
                  '등록된 방이 없습니다.',
                  style: TextStyle(color: Colors.white70),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: rooms.length,
              itemBuilder: (context, i) {
                final room = rooms[i];
                return Card(
                  color: Color(0xFF3971FF),
                  child: ListTile(
                    leading: const Icon(
                      Icons.meeting_room,
                      color: Colors.white,
                    ),
                    title: Text(
                      room.name,
                      style: const TextStyle(color: Colors.white),
                    ),
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RoomDetailScreen(room: room),
                        ),
                      );
                      if (result == true) _fetchRooms();
                    },
                  ),
                );
              },
            );
          } else {
            return const Center(
              child: Text('알 수 없는 오류', style: TextStyle(color: Colors.white)),
            );
          }
        },
      ),
    );
  }
}
