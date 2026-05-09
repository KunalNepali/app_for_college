import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/question.dart';
import '../models/section.dart';
import '../models/section_attempt.dart';
import '../providers/app_providers.dart';
import '../repositories/quiz_repository.dart';
import 'result_screen.dart';

class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key, required this.section});

  final Section section;

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  List<Question> _questions = [];
  SectionAttempt? _attempt;
  bool _isLoading = true;
  String? _error;

  QuizRepository get _repository => ref.read(quizRepositoryProvider);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final attempt = await _repository.startOrResumeAttempt(widget.section.id);
      final questions = await _repository.loadAttemptQuestions(widget.section.id);

      if (!mounted) return;
      setState(() {
        _attempt = attempt;
        _questions = questions;
        _isLoading = false;
      });
    } on NotEnoughQuestionsException catch (e) {
      if (!mounted) return;
      setState(() {
        _error =
            'Not enough questions available offline for this section (${e.availableCount}/50).';
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to start section: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _restartSection() async {
    await _repository.restartAttempt(widget.section.id);
    await _loadData();
  }

  Future<void> _select(String questionId, String answer) async {
    await _repository.selectAnswer(
      sectionId: widget.section.id,
      questionId: questionId,
      answer: answer,
    );
    final refreshed = await _repository.getAttempt(widget.section.id);
    if (mounted) {
      setState(() {
        _attempt = refreshed;
      });
    }
  }

  Future<void> _goTo(int index) async {
    await _repository.goToIndex(sectionId: widget.section.id, index: index);
    final refreshed = await _repository.getAttempt(widget.section.id);
    if (mounted) {
      setState(() {
        _attempt = refreshed;
      });
    }
  }

  Future<void> _submit() async {
    final attempt = _attempt;
    if (attempt == null) return;

    var correctAnswers = 0;
    for (final question in _questions) {
      if (attempt.answersByQuestionId[question.id] == question.correctAnswer) {
        correctAnswers++;
      }
    }

    final Map<int, String> answersByIndex = {};
    for (var i = 0; i < _questions.length; i++) {
      final question = _questions[i];
      final answer = attempt.answersByQuestionId[question.id];
      if (answer != null) answersByIndex[i] = answer;
    }

    await _repository.clearAttempt(widget.section.id);

    if (!mounted) return;
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          sectionName: widget.section.name,
          totalQuestions: _questions.length,
          correctAnswers: correctAnswers,
          questions: _questions,
          userAnswers: answersByIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final attempt = _attempt;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.section.name,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Restart section',
            onPressed: _isLoading
                ? null
                : () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Restart section'),
                        content: const Text(
                          'This will discard current progress and pick a new random 50 questions.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Restart'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await _restartSection();
                    }
                  },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(color: Colors.redAccent),
                ),
              ),
            )
          : attempt == null || _questions.isEmpty
          ? Center(
              child: Text(
                'No active section attempt found.',
                style: GoogleFonts.poppins(),
              ),
            )
          : _QuizBody(
              attempt: attempt,
              questions: _questions,
              onAnswer: _select,
              onNavigate: _goTo,
              onSubmit: _submit,
            ),
    );
  }
}

class _QuizBody extends StatelessWidget {
  const _QuizBody({
    required this.attempt,
    required this.questions,
    required this.onAnswer,
    required this.onNavigate,
    required this.onSubmit,
  });

  final SectionAttempt attempt;
  final List<Question> questions;
  final Future<void> Function(String questionId, String answer) onAnswer;
  final Future<void> Function(int index) onNavigate;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    final currentIndex = attempt.currentIndex.clamp(0, questions.length - 1);
    final question = questions[currentIndex];
    final selectedAnswer = attempt.answersByQuestionId[question.id];

    var correctSoFar = 0;
    for (final q in questions) {
      if (attempt.answersByQuestionId[q.id] == q.correctAnswer) {
        correctSoFar++;
      }
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.deepPurple.shade50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${currentIndex + 1} of ${questions.length}',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              Text(
                'Score: $correctSoFar/${questions.length}',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  question.questionText,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                ...List.generate(4, (index) {
                  final optionLetter = question.getOptionLetter(index);
                  final optionText = question.options[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _OptionTile(
                      optionLetter: optionLetter,
                      optionText: optionText,
                      isSelected: selectedAnswer == optionLetter,
                      onTap: () => onAnswer(question.id, optionLetter),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (currentIndex > 0)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => onNavigate(currentIndex - 1),
                    child: const Text('Previous'),
                  ),
                ),
              if (currentIndex > 0) const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: selectedAnswer == null
                      ? null
                      : () {
                          if (currentIndex == questions.length - 1) {
                            onSubmit();
                          } else {
                            onNavigate(currentIndex + 1);
                          }
                        },
                  child: Text(
                    currentIndex == questions.length - 1 ? 'Submit' : 'Next',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.optionLetter,
    required this.optionText,
    required this.isSelected,
    required this.onTap,
  });

  final String optionLetter;
  final String optionText;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.deepPurple : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          color: isSelected ? Colors.deepPurple.withOpacity(0.08) : null,
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: isSelected ? Colors.deepPurple : Colors.grey,
              child: Text(
                optionLetter,
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(optionText, style: GoogleFonts.poppins())),
          ],
        ),
      ),
    );
  }
}
