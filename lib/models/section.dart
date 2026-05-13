class Section {
  final String id;
  final String categoryId;
  final String name;
  final int? sortOrder;

  Section({
    required this.id,
    required this.categoryId,
    required this.name,
    this.sortOrder,
  });

  factory Section.fromJson(Map<String, dynamic> json) {
    return Section(
      id: json['id'] as String,
      categoryId: json['category_id'] as String,
      name: (json['name'] ?? '') as String,
      sortOrder: json['sort_order'] as int?,
    );
  }
}
