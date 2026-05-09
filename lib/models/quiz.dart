class Quiz {
  final String id;
  final String categoryId;
  final String title;
  final String? description;
  final DateTime createdAt;

  Quiz({
    required this.id,
    required this.categoryId,
    required this.title,
    this.description,
    required this.createdAt,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['id'] as String,
      categoryId: json['category_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category_id': categoryId,
      'title': title,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
