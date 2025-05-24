export '../models/sensor.dart';

class Sensor {
  final String id;
  final String name;
  Sensor({required this.id, required this.name});
  factory Sensor.fromJson(Map<String, dynamic> json) =>
      Sensor(id: json['id'].toString(), name: json['name']);
}
