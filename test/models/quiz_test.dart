import 'package:flutter_test/flutter_test.dart';
import 'package:quiz_app_supabase/models/quiz.dart';

void main() {
  test('Quiz.fromJson maps title from title key', () {
    final quiz = Quiz.fromJson({
      'id': 'quiz_1',
      'category_id': 'cat_1',
      'title': 'Expected Title',
      'description': 'Some description',
      'created_at': '2024-01-01T00:00:00.000Z',
    });

    expect(quiz.title, 'Expected Title');
    expect(quiz.description, 'Some description');
  });
}
