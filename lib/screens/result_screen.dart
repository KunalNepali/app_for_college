import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/question.dart';
import 'home_screen.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({
    super.key,
    required this.sectionName,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.questions,
    required this.userAnswers,
  });

  final String sectionName;
  final int totalQuestions;
  final int correctAnswers;
  final List<Question> questions;
  final Map<int, String> userAnswers;

  double get percentage => (correctAnswers / totalQuestions) * 100;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Quiz Result'),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                sectionName,
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                '${percentage.toStringAsFixed(1)}% ($correctAnswers/$totalQuestions)',
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ...List.generate(questions.length, (index) {
                final question = questions[index];
                final userAnswer = userAnswers[index] ?? '';
                final isCorrect = userAnswer == question.correctAnswer;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(question.questionText),
                    subtitle: Text(
                      'Your answer: ${userAnswer.isEmpty ? '-' : userAnswer} | Correct: ${question.correctAnswer}',
                    ),
                    trailing: Icon(
                      isCorrect ? Icons.check_circle : Icons.cancel,
                      color: isCorrect ? Colors.green : Colors.red,
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                    (route) => false,
                  );
                },
                child: const Text('Back to categories'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
