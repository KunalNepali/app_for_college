import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/quiz_progress.dart';
import '../storage/quiz_progress_storage.dart';

final quizProgressProvider =
    AsyncNotifierProviderFamily<QuizProgressNotifier, QuizProgress, String>(
      QuizProgressNotifier.new,
    );

class QuizProgressNotifier extends FamilyAsyncNotifier<QuizProgress, String> {
  final _storage = QuizProgressStorage();

  @override
  Future<QuizProgress> build(String quizId) async {
    final saved = await _storage.load(quizId);
    return saved ?? QuizProgress.initial(quizId);
  }

  String get _quizId =>
      arg; // 'arg' is the family parameter in FamilyAsyncNotifier

  Future<void> _persist(QuizProgress progress) async {
    state = AsyncData(progress);
    await _storage.save(progress);
  }

  Future<void> selectAnswer(String questionId, String answer) async {
    final current = state.value ?? QuizProgress.initial(_quizId);

    final updatedAnswers = Map<String, String>.from(
      current.selectedAnswersByQuestionId,
    )..[questionId] = answer;

    await _persist(
      current.copyWith(selectedAnswersByQuestionId: updatedAnswers),
    );
  }

  Future<void> next(int totalQuestions) async {
    final current = state.value ?? QuizProgress.initial(_quizId);
    if (current.currentIndex < totalQuestions - 1) {
      await _persist(current.copyWith(currentIndex: current.currentIndex + 1));
    }
  }

  Future<void> previous() async {
    final current = state.value ?? QuizProgress.initial(_quizId);
    if (current.currentIndex > 0) {
      await _persist(current.copyWith(currentIndex: current.currentIndex - 1));
    }
  }

  Future<void> jumpTo(int index) async {
    final current = state.value ?? QuizProgress.initial(_quizId);
    await _persist(current.copyWith(currentIndex: index));
  }

  Future<void> reset() async {
    await _storage.clear(_quizId);
    state = AsyncData(QuizProgress.initial(_quizId));
  }
}
