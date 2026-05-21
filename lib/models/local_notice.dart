class LocalNotice {
  final String title;
  final String date; // keep as string (BS date or any format)
  final String? description;
  final String assetPath;

  LocalNotice({
    required this.title,
    required this.date,
    required this.assetPath,
    this.description,
  });

  factory LocalNotice.fromJson(Map<String, dynamic> json) {
    return LocalNotice(
      title: (json['title'] ?? '') as String,
      date: (json['date'] ?? '') as String,
      assetPath: (json['assetPath'] ?? '') as String,
      description: json['description'] as String?,
    );
  }
}
