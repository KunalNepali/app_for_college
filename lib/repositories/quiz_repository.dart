import 'package:quiz_app_supabase/db/local_db.dart';
import 'package:quiz_app_supabase/models/category.dart';
import 'package:quiz_app_supabase/models/question.dart';
import 'package:quiz_app_supabase/models/quiz.dart';

class QuizRepository {
  QuizRepository(this._localDb);

  final LocalDb _localDb;

  Future<List<Category>> getCategories() {
    return _localDb.getCategories();
  }

  Future<List<Quiz>> getQuizzesByCategory(String categoryId) {
    return _localDb.getQuizzesByCategory(categoryId);
  }

  Future<List<Question>> getQuestionsByQuiz(String quizId) {
    return _localDb.getQuestionsByQuiz(quizId);
  }
}
