class Device {
  final int id;
  final String name;
  final bool? isActive; // 상태는 필요시만 사용

  Device({required this.id, required this.name, this.isActive});

  factory Device.fromJson(Map<String, dynamic> json) => Device(
    id:
        json['deviceId'] is int
            ? json['deviceId']
            : int.tryParse(json['deviceId'].toString()) ?? 0,
    name: json['alias'] ?? json['name'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'deviceId': id,
    'alias': name,
    if (isActive != null) 'isActive': isActive,
  };

  Device copyWith({int? id, String? name, bool? isActive}) => Device(
    id: id ?? this.id,
    name: name ?? this.name,
    isActive: isActive ?? this.isActive,
  );
}
