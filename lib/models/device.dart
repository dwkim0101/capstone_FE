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
  List<Device> _devices = [];
  bool _loading = false;
  String? _error;
  int? _roomId;
  final Map<int, bool> _deviceLoading = {}; // deviceId별 로딩 상태

  List<Device> get devices => _devices;
  bool get loading => _loading;
  String? get error => _error;
  int? get roomId => _roomId;
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

  Future<void> fetchDevices(int roomId) async {
    _loading = true;
    _error = null;
    _roomId = roomId;
    notifyListeners();
    try {
      final res = await authorizedRequest(
        'GET',
        Uri.parse(ApiConstants.thinqDeviceList(roomId)),
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
        _devices = await Future.wait(futures);
      } else {
        _error = '기기 목록 불러오기 실패';
      }
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> toggleDevice(int deviceId) async {
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
        final idx = _devices.indexWhere((d) => d.id == deviceId);
        if (idx != -1) {
          _devices[idx] = _devices[idx].copyWith(isActive: status == 'ON');
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
    _devices = [];
    _loading = false;
    _error = null;
    _roomId = null;
    notifyListeners();
  }
}
