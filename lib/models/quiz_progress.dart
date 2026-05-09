class QuizProgress {
  final String quizId;
  final int currentIndex;
  final Map<String, String> selectedAnswersByQuestionId;
  final DateTime updatedAt;

  QuizProgress({
    required this.quizId,
    required this.currentIndex,
    required this.selectedAnswersByQuestionId,
    required this.updatedAt,
  });

  factory QuizProgress.initial(String quizId) {
    return QuizProgress(
      quizId: quizId,
      currentIndex: 0,
      selectedAnswersByQuestionId: {},
      updatedAt: DateTime.now(),
    );
  }

  QuizProgress copyWith({
    int? currentIndex,
    Map<String, String>? selectedAnswersByQuestionId,
  }) {
    return QuizProgress(
      quizId: quizId,
      currentIndex: currentIndex ?? this.currentIndex,
      selectedAnswersByQuestionId:
          selectedAnswersByQuestionId ?? this.selectedAnswersByQuestionId,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'quizId': quizId,
      'currentIndex': currentIndex,
      'answers': selectedAnswersByQuestionId,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory QuizProgress.fromJson(Map<String, dynamic> json) {
    return QuizProgress(
      quizId: json['quizId'],
      currentIndex: json['currentIndex'],
      selectedAnswersByQuestionId: Map<String, String>.from(json['answers']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}
