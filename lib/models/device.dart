import 'package:flutter/foundation.dart';
import '../utils/api_constants.dart';
import '../utils/api_client.dart';
import 'dart:convert';

class Device {
  final int id;
  final String name;
  final bool? isActive; // 상태는 필요시만 사용
  final bool? isRegistered;

  Device({
    required this.id,
    required this.name,
    this.isActive,
    this.isRegistered,
  });

  factory Device.fromJson(Map<String, dynamic> json) => Device(
    id:
        json['deviceId'] is int
            ? json['deviceId']
            : int.tryParse(json['deviceId'].toString()) ?? 0,
    name: json['alias'] ?? json['name'] ?? '',
    isRegistered: json['isRegistered'],
  );

  Map<String, dynamic> toJson() => {
    'deviceId': id,
    'alias': name,
    if (isActive != null) 'isActive': isActive,
    if (isRegistered != null) 'isRegistered': isRegistered,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Device &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          isActive == other.isActive &&
          isRegistered == other.isRegistered;

  @override
  int get hashCode =>
      id.hashCode ^ name.hashCode ^ isActive.hashCode ^ isRegistered.hashCode;

  Device copyWith({int? id, String? name, bool? isActive, bool? isRegistered}) {
    return Device(
      id: id ?? this.id,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
      isRegistered: isRegistered ?? this.isRegistered,
    );
  }

  static List<Device> fromList(List<dynamic> data) {
    return data.map((e) => Device.fromJson(e)).toList();
  }
}

class DeviceProvider extends ChangeNotifier {
  final Map<int, List<Device>> _roomDevices = {};
  bool _loading = false;
  String? _error;
  final Map<int, bool> _deviceLoading = {}; // deviceId별 로딩 상태

  List<Device> getDevices(int roomId) => _roomDevices[roomId] ?? [];
  bool get loading => _loading;
  String? get error => _error;
  Map<int, bool> get deviceLoading => _deviceLoading;

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

  Future<void> fetchDevices(int roomId, {bool showLoading = true}) async {
    if (showLoading) _loading = true;
    _error = null;
    if (showLoading) notifyListeners();
    try {
      final res = await authorizedRequest(
        'GET',
        Uri.parse(ApiConstants.thinqDeviceRegisteredList(roomId)),
      );
      if (res?.statusCode == 200) {
        final List data = json.decode(res?.body ?? '[]');
        List<Device> devices = Device.fromList(data);
        // 각 기기 상태 병렬로 fetch
        final futures =
            devices.map((d) async {
              final status = await fetchDevicePowerStatus(d.id);
              return d.copyWith(isActive: status == 'ON');
            }).toList();
        _roomDevices[roomId] = await Future.wait(futures);
      } else {
        _error = '기기 목록 불러오기 실패';
        _roomDevices[roomId] = [];
      }
    } catch (e) {
      _error = e.toString();
      _roomDevices[roomId] = [];
    }
    if (showLoading) _loading = false;
    notifyListeners();
  }

  Future<void> toggleDevice(int deviceId, int roomId) async {
    _deviceLoading[deviceId] = true;
    notifyListeners();
    try {
      final res = await authorizedRequest(
        'POST',
        Uri.parse('${ApiConstants.baseUrl}/thinq/power/$deviceId'),
      );
      if (res?.statusCode == 200) {
        // 상태만 다시 조회해서 해당 기기만 갱신
        final status = await fetchDevicePowerStatus(deviceId);
        if (_roomDevices[roomId] != null) {
          final idx = _roomDevices[roomId]!.indexWhere((d) => d.id == deviceId);
          if (idx != -1) {
            _roomDevices[roomId]![idx] = _roomDevices[roomId]![idx].copyWith(
              isActive: status == 'ON',
            );
          }
        }
      } else {
        _error = '기기 제어 실패';
      }
    } catch (e) {
      _error = e.toString();
    }
    _deviceLoading[deviceId] = false;
    notifyListeners();
  }

  void clear() {
    _roomDevices.clear();
    _loading = false;
    _error = null;
    notifyListeners();
  }
}
