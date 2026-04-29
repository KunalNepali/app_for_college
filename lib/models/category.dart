class Category {
  final String id;
  final String name;
  final String? description;
  final String? icon;
  final DateTime createdAt;

  Category({
    required this.id,
    required this.name,
    this.description,
    required this.icon,
    required this.createdAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      icon: json['icon'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
