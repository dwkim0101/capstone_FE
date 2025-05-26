import 'package:flutter/material.dart';
import '../utils/api_constants.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/api_client.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class RoomAddScreen extends StatefulWidget {
  const RoomAddScreen({super.key});
  @override
  State<RoomAddScreen> createState() => _RoomAddScreenState();
}

class _RoomAddScreenState extends State<RoomAddScreen> {
  final _nameController = TextEditingController();
  bool _loading = false;

  LatLng? _selectedLatLng;
  final MapController _mapController = MapController();

  // 기본 지도 위치 (서울 시청)
  static const LatLng _defaultLatLng = LatLng(37.5665, 126.9780);

  Future<void> _goToCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('위치 서비스가 비활성화되어 있습니다.')));
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('위치 권한이 필요합니다.')));
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('위치 권한이 영구적으로 거부되었습니다. 설정에서 허용해주세요.')),
      );
      return;
    }

    final position = await Geolocator.getCurrentPosition();
    final latLng = LatLng(position.latitude, position.longitude);
    setState(() {
      _selectedLatLng = latLng;
    });
    _mapController.move(latLng, 16.0);
  }

  Future<void> _addRoom() async {
    print('[_addRoom] POST: ${ApiConstants.roomCreate}');
    if (_selectedLatLng == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('지도를 클릭하여 위치를 선택하세요.')));
      return;
    }
    final body = {
      'name': _nameController.text,
      'latitude': _selectedLatLng!.latitude,
      'longitude': _selectedLatLng!.longitude,
      // 필요시 password, deviceControlEnabled 등 추가
    };
    print('[_addRoom] body: ${json.encode(body)}');
    setState(() => _loading = true);
    final res = await authorizedRequest(
      'POST',
      Uri.parse(ApiConstants.roomCreate),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );
    print('[_addRoom] status: \'${res?.statusCode}\', body: \\${res?.body}');
    setState(() => _loading = false);
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('방 추가', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: '방 이름',
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                      ),
                      cursorColor: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    // 지도 위젯
                    SizedBox(
                      height: 240,
                      child: FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          center: _selectedLatLng ?? _defaultLatLng,
                          zoom: 13.0,
                          onTap: (tapPosition, latlng) {
                            setState(() {
                              _selectedLatLng = latlng;
                            });
                            _mapController.move(latlng, 16.0);
                          },
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                            subdomains: const ['a', 'b', 'c'],
                          ),
                          if (_selectedLatLng != null)
                            MarkerLayer(
                              markers: [
                                Marker(
                                  width: 40,
                                  height: 40,
                                  point: _selectedLatLng!,
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
                    const SizedBox(height: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _selectedLatLng == null
                            ? const Text(
                              '위치를 선택하세요',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            )
                            : Text(
                              '위도: ${_selectedLatLng!.latitude.toStringAsFixed(5)}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                        _selectedLatLng == null
                            ? const SizedBox.shrink()
                            : Text(
                              '경도: ${_selectedLatLng!.longitude.toStringAsFixed(5)}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            icon: const Icon(
                              Icons.my_location,
                              color: Colors.white70,
                            ),
                            tooltip: '현재 위치로 이동',
                            onPressed: _goToCurrentLocation,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Color(0xFF3971FF),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                        minimumSize: const Size.fromHeight(48),
                      ),
                      onPressed: _addRoom,
                      child: const Text(
                        '추가',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
