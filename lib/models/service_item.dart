class ServiceItem {
  final String id;
  final String deptId;
  final String name;
  final String description;
  final String url;

  ServiceItem({
    required this.id,
    required this.deptId,
    required this.name,
    required this.description,
    required this.url,
  });

  factory ServiceItem.fromJson(Map<String, dynamic> json) {
    return ServiceItem(
      id: json['id'] ?? '',
      deptId: json['deptId'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      url: json['url'] ?? '',
    );
  }
}
