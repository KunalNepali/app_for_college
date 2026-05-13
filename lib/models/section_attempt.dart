class SectionAttempt {
  final String sectionId;
  final List<String> questionIds;
  final int currentIndex;
  final Map<String, String> answersByQuestionId;
  final DateTime startedAt;
  final DateTime updatedAt;

  SectionAttempt({
    required this.sectionId,
    required this.questionIds,
    required this.currentIndex,
    required this.answersByQuestionId,
    required this.startedAt,
    required this.updatedAt,
  });

  SectionAttempt copyWith({
    List<String>? questionIds,
    int? currentIndex,
    Map<String, String>? answersByQuestionId,
    DateTime? updatedAt,
  }) {
    return SectionAttempt(
      sectionId: sectionId,
      questionIds: questionIds ?? this.questionIds,
      currentIndex: currentIndex ?? this.currentIndex,
      answersByQuestionId: answersByQuestionId ?? this.answersByQuestionId,
      startedAt: startedAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
