class Notice {
  final String id;
  final String type; // 'exam' or 'vacancy'
  final String title;
  final String? description;
  final String? pdfUrl;
  final DateTime noticeDate;

  Notice({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.pdfUrl,
    required this.noticeDate,
  });

  factory Notice.fromJson(Map<String, dynamic> json) {
    return Notice(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      pdfUrl: json['pdf_url'] as String?,
      noticeDate: DateTime.parse(json['notice_date'] as String),
    );
  }
}
