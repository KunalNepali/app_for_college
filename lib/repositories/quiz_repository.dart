import 'dart:math';

import '../models/category.dart';
import '../models/question.dart';
import '../models/section.dart';
import '../models/section_attempt.dart';
import '../services/local_database_service.dart';

class NotEnoughQuestionsException implements Exception {
  NotEnoughQuestionsException({required this.availableCount});

  final int availableCount;

  @override
  String toString() {
    return 'Only $availableCount questions are available locally for this section. At least 50 are required to start.';
  }
}

class QuizRepository {
  QuizRepository(this._localDatabaseService);

  final LocalDatabaseService _localDatabaseService;

  Future<List<Category>> getCategories() {
    return _localDatabaseService.getCategories();
  }

  Future<List<Section>> getSectionsByCategory(String categoryId) {
    return _localDatabaseService.getSectionsByCategory(categoryId);
  }

  Future<bool> hasAttempt(String sectionId) async {
    final attempt = await _localDatabaseService.getSectionAttempt(sectionId);
    return attempt != null;
  }

  Future<SectionAttempt> startOrResumeAttempt(String sectionId) async {
    final existing = await _localDatabaseService.getSectionAttempt(sectionId);
    if (existing != null) {
      return existing;
    }

    final questionIds = await _localDatabaseService.getQuestionIdsBySection(sectionId);
    if (questionIds.length < 50) {
      throw NotEnoughQuestionsException(availableCount: questionIds.length);
    }

    final shuffled = List<String>.from(questionIds)..shuffle(Random());
    final selected = shuffled.take(50).toList(growable: false);
    final now = DateTime.now();

    final attempt = SectionAttempt(
      sectionId: sectionId,
      questionIds: selected,
      currentIndex: 0,
      answersByQuestionId: {},
      startedAt: now,
      updatedAt: now,
    );

    await _localDatabaseService.saveSectionAttempt(attempt);
    return attempt;
  }

  Future<SectionAttempt> restartAttempt(String sectionId) async {
    await _localDatabaseService.deleteSectionAttempt(sectionId);
    return startOrResumeAttempt(sectionId);
  }

  Future<List<Question>> loadAttemptQuestions(String sectionId) async {
    final attempt = await _localDatabaseService.getSectionAttempt(sectionId);
    if (attempt == null) {
      return [];
    }
    return _localDatabaseService.getQuestionsByIds(attempt.questionIds);
  }

  Future<SectionAttempt?> getAttempt(String sectionId) {
    return _localDatabaseService.getSectionAttempt(sectionId);
  }

  Future<void> selectAnswer({
    required String sectionId,
    required String questionId,
    required String answer,
  }) async {
    final attempt = await _localDatabaseService.getSectionAttempt(sectionId);
    if (attempt == null) return;

    final nextAnswers = Map<String, String>.from(attempt.answersByQuestionId)
      ..[questionId] = answer;

    await _localDatabaseService.saveSectionAttempt(
      attempt.copyWith(
        answersByQuestionId: nextAnswers,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> goToIndex({
    required String sectionId,
    required int index,
  }) async {
    final attempt = await _localDatabaseService.getSectionAttempt(sectionId);
    if (attempt == null) return;

    final safeIndex = index.clamp(0, attempt.questionIds.length - 1);

    await _localDatabaseService.saveSectionAttempt(
      attempt.copyWith(
        currentIndex: safeIndex,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> clearAttempt(String sectionId) {
    return _localDatabaseService.deleteSectionAttempt(sectionId);
  }
}
