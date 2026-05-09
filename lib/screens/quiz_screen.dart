import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quiz_app_supabase/models/question.dart';
import 'package:quiz_app_supabase/models/quiz.dart';
import 'package:quiz_app_supabase/providers/offline_data_providers.dart';
import 'package:quiz_app_supabase/providers/quiz_progress_provider.dart';
import 'package:quiz_app_supabase/screens/result_screen.dart';

class QuizScreen extends ConsumerWidget {
  final Quiz quiz;

  const QuizScreen({super.key, required this.quiz});

  Future<void> _refresh(WidgetRef ref, BuildContext context) async {
    final result = await ref.read(syncStatusProvider.notifier).syncNow();
    ref.invalidate(questionsByQuizProvider(quiz.id));

    if (!result.success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message), behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<void> _submitQuiz({
    required BuildContext context,
    required WidgetRef ref,
    required List<Question> questions,
    required Map<String, String> selectedAnswersByQuestionId,
  }) async {
    var correctAnswers = 0;
    for (final q in questions) {
      final userAnswer = selectedAnswersByQuestionId[q.id];
      if (userAnswer != null && userAnswer == q.correctAnswer) {
        correctAnswers++;
      }
    }

    await ref.read(quizProgressProvider(quiz.id).notifier).reset();

    final answersByIndex = <int, String>{};
    for (var i = 0; i < questions.length; i++) {
      final answer = selectedAnswersByQuestionId[questions[i].id];
      if (answer != null) {
        answersByIndex[i] = answer;
      }
    }

    if (!context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultScreen(
          quiz: quiz,
          totalQuestions: questions.length,
          correctAnswers: correctAnswers,
          questions: questions,
          userAnswers: answersByIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionsAsync = ref.watch(questionsByQuizProvider(quiz.id));
    final progressAsync = ref.watch(quizProgressProvider(quiz.id));

    return WillPopScope(
      onWillPop: () async {
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Exit Quiz'),
              content: const Text(
                'Are you sure you want to exit the quiz? Your progress will be saved and you can resume later.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Exit'),
                ),
              ],
            );
          },
        );
        return shouldPop ?? false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            quiz.title,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              onPressed: () => _refresh(ref, context),
              icon: const Icon(Icons.refresh),
              tooltip: 'Sync now',
            ),
          ],
        ),
        body: questionsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _ErrorState(
            errorMessage: '$error',
            onRetry: () async => ref.invalidate(questionsByQuizProvider(quiz.id)),
          ),
          data: (questions) {
            if (questions.isEmpty) {
              return const _EmptyQuestionsState();
            }

            return progressAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) =>
                  Center(child: Text('Failed to load progress: $error')),
              data: (progress) {
                final maxIndex = questions.length - 1;
                final currentIndex = progress.currentIndex.clamp(0, maxIndex);

                final question = questions[currentIndex];
                final selectedAnswer =
                    progress.selectedAnswersByQuestionId[question.id];

                var correctSoFar = 0;
                for (final q in questions) {
                  final answer = progress.selectedAnswersByQuestionId[q.id];
                  if (answer != null && answer == q.correctAnswer) {
                    correctSoFar++;
                  }
                }

                return RefreshIndicator(
                  onRefresh: () => _refresh(ref, context),
                  child: ListView(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        color: Colors.deepPurple.shade50,
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Question ${currentIndex + 1} of ${questions.length}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'Score: $correctSoFar / ${questions.length}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: (currentIndex + 1) / questions.length,
                              backgroundColor: Colors.grey[300],
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.deepPurple,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Theme.of(context).colorScheme.surface,
                                border: Border.all(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.outline.withOpacity(0.2),
                                ),
                              ),
                              child: Text(
                                question.questionText,
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  height: 1.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            ...List.generate(4, (index) {
                              final optionLetter = question.getOptionLetter(index);
                              final optionText = question.options[index];
                              final isSelected = selectedAnswer == optionLetter;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _OptionButton(
                                  optionLetter: optionLetter,
                                  optionText: optionText,
                                  isSelected: isSelected,
                                  onTap: () async {
                                    await ref
                                        .read(
                                          quizProgressProvider(quiz.id).notifier,
                                        )
                                        .selectAnswer(question.id, optionLetter);
                                  },
                                ),
                              );
                            }),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                if (currentIndex > 0)
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () async {
                                        await ref
                                            .read(
                                              quizProgressProvider(
                                                quiz.id,
                                              ).notifier,
                                            )
                                            .previous();
                                      },
                                      label: const Text('Previous'),
                                      icon: const Icon(Icons.arrow_back),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                if (currentIndex > 0) const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: ElevatedButton(
                                    onPressed: selectedAnswer == null
                                        ? null
                                        : () async {
                                            if (currentIndex ==
                                                questions.length - 1) {
                                              await _submitQuiz(
                                                context: context,
                                                ref: ref,
                                                questions: questions,
                                                selectedAnswersByQuestionId:
                                                    progress
                                                        .selectedAnswersByQuestionId,
                                              );
                                            } else {
                                              await ref
                                                  .read(
                                                    quizProgressProvider(
                                                      quiz.id,
                                                    ).notifier,
                                                  )
                                                  .next(questions.length);
                                            }
                                          },
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      backgroundColor: Colors.deepPurple,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: Text(
                                      currentIndex == questions.length - 1
                                          ? 'Submit Quiz'
                                          : 'Next',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  final String optionLetter;
  final String optionText;
  final bool isSelected;
  final VoidCallback onTap;

  const _OptionButton({
    super.key,
    required this.optionLetter,
    required this.optionText,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepPurple.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.deepPurple : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected ? Colors.deepPurple : Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  optionLetter,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                optionText,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyQuestionsState extends StatelessWidget {
  const _EmptyQuestionsState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.question_answer_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'No questions available right now.',
            style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String errorMessage;
  final Future<void> Function() onRetry;

  const _ErrorState({required this.errorMessage, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
          const SizedBox(height: 16),
          Text(
            'Failed to load questions.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 18, color: Colors.redAccent),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
