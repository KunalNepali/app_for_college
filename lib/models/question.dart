class Question {
  final String id;

  /// New schema uses section_id. Old schema used quiz_id.
  /// Keep both optional so the app can work with either backend.
  final String? sectionId;
  final String? quizId;

  final String questionText;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;
  final String correctAnswer;
  final DateTime createdAt;

  Question({
    required this.id,
    this.sectionId,
    this.quizId,
    required this.questionText,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
    required this.correctAnswer,
    required this.createdAt,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as String,
      sectionId: json['section_id'] as String?, // new
      quizId: json['quiz_id'] as String?, // old
      questionText: (json['question_text'] ?? '') as String,
      optionA: (json['option_a'] ?? '') as String,
      optionB: (json['option_b'] ?? '') as String,
      optionC: (json['option_c'] ?? '') as String,
      optionD: (json['option_d'] ?? '') as String,
      correctAnswer: (json['correct_answer'] ?? '') as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      // write both when present; Supabase will ignore unknown columns depending on your usage
      'section_id': sectionId,
      'quiz_id': quizId,
      'question_text': questionText,
      'option_a': optionA,
      'option_b': optionB,
      'option_c': optionC,
      'option_d': optionD,
      'correct_answer': correctAnswer,
      'created_at': createdAt.toIso8601String(),
    };
  }

  List<String> get options => [optionA, optionB, optionC, optionD];

  String getOptionLetter(int index) {
    switch (index) {
      case 0:
        return 'A';
      case 1:
        return 'B';
      case 2:
        return 'C';
      case 3:
        return 'D';
      default:
        return '';
    }
  }
}
