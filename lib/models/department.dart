class Department {
  final String id;
  final String name;
  final String icon;
  final int serviceCount;

  Department({
    required this.id,
    required this.name,
    required this.icon,
    required this.serviceCount,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      icon: json['icon'] ?? '🏢',
      serviceCount: (json['serviceCount'] ?? 0) is int
          ? json['serviceCount']
          : int.tryParse(json['serviceCount'].toString()) ?? 0,
    );
  }
}
