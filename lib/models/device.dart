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

  Device copyWith({
    int? id,
    String? name,
    bool? isActive,
    bool? isRegistered,
  }) => Device(
    id: id ?? this.id,
    name: name ?? this.name,
    isActive: isActive ?? this.isActive,
    isRegistered: isRegistered ?? this.isRegistered,
  );
}
