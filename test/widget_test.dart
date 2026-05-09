import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app_supabase/models/question.dart';

void main() {
  test('Question.fromJson maps section and options correctly', () {
    final question = Question.fromJson({
      'id': 'q1',
      'section_id': 's1',
      'question_text': 'What is 2 + 2?',
      'option_a': '4',
      'option_b': '3',
      'option_c': '2',
      'option_d': '1',
      'correct_answer': 'A',
      'created_at': '2026-01-01T00:00:00Z',
    });

    expect(question.sectionId, 's1');
    expect(question.options, ['4', '3', '2', '1']);
    expect(question.correctAnswer, 'A');
  });
}
