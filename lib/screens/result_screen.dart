import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quiz_app_supabase/models/question.dart';
import 'package:quiz_app_supabase/models/quiz.dart';
import 'package:quiz_app_supabase/screens/home_screen.dart';

class ResultScreen extends StatelessWidget {
  final Quiz quiz;
  final int totalQuestions;
  final int correctAnswers;
  final List<Question> questions;
  final Map<int, String> userAnswers;

  const ResultScreen({
    super.key,
    required this.quiz,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.questions,
    required this.userAnswers,
  });

  double get percentage => (correctAnswers / totalQuestions) * 100;

  String get grade {
    if (percentage >= 90) return 'Excellent';
    if (percentage >= 70) return 'Good Job!';
    if (percentage >= 50) return 'Not Bad!';
    return 'Keep Trying!!';
  }

  Color get gradeColor {
    if (percentage >= 90) return Colors.green;
    if (percentage >= 70) return Colors.blue;
    if (percentage >= 50) return Colors.orange;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => HomeScreen()),
          (route) => false,
        );
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            "Quiz Result",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          leading: IconButton(
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => HomeScreen()),
                (route) => false,
              );
            },
            icon: Icon(Icons.home),
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.deepPurple,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(35),
                    bottomRight: Radius.circular(35),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(Icons.emoji_events, size: 80, color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      grade,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      quiz.title,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 24),
                    Container(
                      padding: EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${percentage.toStringAsFixed(1)}%',
                            style: GoogleFonts.poppins(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: gradeColor,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '$correctAnswers out of $totalQuestions correct',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.check_circle,
                        iconColor: Colors.green,
                        title: "Correct",
                        value: correctAnswers.toString(),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.cancel,
                        iconColor: Colors.redAccent,
                        title: "Wrong",
                        value: (totalQuestions - correctAnswers).toString(),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.quiz,
                        iconColor: Colors.blueAccent,
                        title: "Total",
                        value: totalQuestions.toString(),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Answer Review",
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 16),
                    ...List.generate(questions.length, (index) {
                      final question = questions[index];
                      final userAnswer = userAnswers[index] ?? '';
                      final isCorrect = userAnswer == question.correctAnswer;
                      return _AnswerReviewCard(
                        questionNumber: index + 1,
                        question: question,
                        userAnswer: userAnswer,
                        isCorrect: isCorrect,
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;

  const _StatCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 32),
          SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

class _AnswerReviewCard extends StatelessWidget {
  final int questionNumber;
  final Question question;
  final String userAnswer;
  final bool isCorrect;

  const _AnswerReviewCard({
    super.key,
    required this.questionNumber,
    required this.question,
    required this.userAnswer,
    required this.isCorrect,
  });

  String _getOptionText(String optionLetter) {
    switch (optionLetter) {
      case 'A':
        return question.optionA;
      case 'B':
        return question.optionB;
      case 'C':
        return question.optionC;
      case 'D':
        return question.optionD;
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isCorrect ? Colors.green : Colors.redAccent,
          width: 2,
        ),
      ),

      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  decoration: BoxDecoration(
                    color: isCorrect ? Colors.green : Colors.redAccent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Q$questionNumber',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Icon(
                  isCorrect ? Icons.check_circle : Icons.cancel,
                  color: isCorrect ? Colors.green : Colors.redAccent,
                ),
                SizedBox(width: 8),
                Text(
                  isCorrect ? 'Correct' : 'Wrong',
                  style: GoogleFonts.poppins(
                    color: isCorrect ? Colors.green : Colors.redAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              question.questionText,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 12),
            if (!isCorrect) ...[
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.close, color: Colors.redAccent, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your Answer: $userAnswer - ${_getOptionText(userAnswer)}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.redAccent[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8),
            ],
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check, color: Colors.green, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Correct Answer: ${question.correctAnswer} - ${_getOptionText(question.correctAnswer)}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.green[900],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
