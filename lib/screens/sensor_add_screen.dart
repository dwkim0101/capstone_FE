import 'package:flutter/material.dart';
import '../utils/api_constants.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/api_client.dart';

class SensorAddScreen extends StatefulWidget {
  final String roomId;
  const SensorAddScreen({required this.roomId, super.key});
  @override
  State<SensorAddScreen> createState() => _SensorAddScreenState();
}

class _SensorAddScreenState extends State<SensorAddScreen> {
  final _serialController = TextEditingController();
  final _nameController = TextEditingController();
  bool _loading = false;

  bool get _canAdd =>
      _serialController.text.trim().isNotEmpty &&
      _nameController.text.trim().isNotEmpty;

  Future<void> _addSensor() async {
    setState(() => _loading = true);
    final body = {
      'serialNumber': _serialController.text.trim(),
      'name': _nameController.text.trim(),
      'roomId': widget.roomId,
    };
    await authorizedRequest(
      'POST',
      Uri.parse(ApiConstants.sensorCreate),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );
    setState(() => _loading = false);
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('센서 추가', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  child: Card(
                    color: Colors.grey[900],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                    elevation: 8,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 28,
                        horizontal: 22,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '센서 등록',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '방에 연결할 센서의 시리얼번호와 이름을 입력하세요.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 28),
                          TextField(
                            controller: _serialController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: '센서 시리얼번호',
                              labelStyle: TextStyle(color: Colors.white70),
                              hintText: '예: SN12345678',
                              hintStyle: TextStyle(color: Colors.white24),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white24),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Color(0xFF3971FF),
                                ),
                              ),
                            ),
                            cursorColor: Color(0xFF3971FF),
                          ),
                          const SizedBox(height: 22),
                          TextField(
                            controller: _nameController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: '센서 이름',
                              labelStyle: TextStyle(color: Colors.white70),
                              hintText: '예: 거실 센서',
                              hintStyle: TextStyle(color: Colors.white24),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white24),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Color(0xFF3971FF),
                                ),
                              ),
                            ),
                            cursorColor: Color(0xFF3971FF),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      bottomNavigationBar:
          _loading
              ? null
              : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _canAdd ? _addSensor : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _canAdd ? Color(0xFF3971FF) : Colors.grey[800],
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                      child: const Text(
                        '센서 추가',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
    );
  }
}
