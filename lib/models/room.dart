class Room {
  final int id;
  final String name;
  final String? owner;
  final String? password;
  final bool? deviceControlEnabled;
  final List<dynamic>? participants;
  final double? latitude;
  final double? longitude;

  Room({
    required this.id,
    required this.name,
    this.owner,
    this.password,
    this.deviceControlEnabled,
    this.participants,
    this.latitude,
    this.longitude,
  });

  factory Room.fromJson(Map<String, dynamic> json) => Room(
    id:
        json['id'] is int
            ? json['id']
            : int.tryParse(json['id'].toString()) ?? 0,
    name: json['name'] ?? '',
    owner: json['ownerUsername'] ?? json['owner'],
    password: json['password'],
    deviceControlEnabled: json['deviceControlEnabled'],
    participants: json['participants'],
    latitude:
        (json['latitude'] is double)
            ? json['latitude']
            : (json['latitude'] != null
                ? double.tryParse(json['latitude'].toString())
                : null),
    longitude:
        (json['longitude'] is double)
            ? json['longitude']
            : (json['longitude'] != null
                ? double.tryParse(json['longitude'].toString())
                : null),
  );
}
