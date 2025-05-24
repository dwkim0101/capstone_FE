class Sensor {
  final String serialNumber;
  final String name;
  final String? sensorType;
  final String? lastUpdatedAt;
  final String? ownerUsername;
  final bool? runningStatus;
  final bool? registered;

  Sensor({
    required this.serialNumber,
    required this.name,
    this.sensorType,
    this.lastUpdatedAt,
    this.ownerUsername,
    this.runningStatus,
    this.registered,
  });

  factory Sensor.fromJson(Map<String, dynamic> json) => Sensor(
    serialNumber: json['serialNumber'] ?? '',
    name: json['name'] ?? '',
    sensorType: json['sensorType'],
    lastUpdatedAt: json['lastUpdatedAt'],
    ownerUsername: json['ownerUsername'],
    runningStatus: json['runningStatus'],
    registered: json['registered'],
  );
}
