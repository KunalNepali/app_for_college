import 'package:quiz_app_supabase/models/category.dart';
import 'package:quiz_app_supabase/models/question.dart';
import 'package:quiz_app_supabase/models/quiz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Category>> getCategories() async {
    try {
      final response = await _supabase
          .from('categories')
          .select()
          .order('created_at', ascending: true);
      return (response as List)
          .map((category) => Category.fromJson(category))
          .toList();
    } catch (e) {
      throw Exception('Failed to load categories: $e');
    }
  }

  Future<List<Quiz>> getQuizzesByCategory(String categoryId) async {
    try {
      final response = await _supabase
          .from('quizzes')
          .select()
          .order('created_at', ascending: true);
      return (response as List).map((quiz) => Quiz.fromJson(quiz)).toList();
    } catch (e) {
      throw Exception('Failed to load quizzes: $e');
    }
  }

  Future<List<Question>> getQuestionByQuiz(String quizId) async {
    try {
      final response = await _supabase
          .from('questions')
          .select()
          .eq('quiz_id', quizId)
          .order('created_at', ascending: true);
      return (response as List)
          .map((question) => Question.fromJson(question))
          .toList();
    } catch (e) {
      throw Exception('Failed to load questions: $e');
    }
  }

  Future<Category> getCategoryById(String categoryId) async {
    try {
      final response = await _supabase
          .from('categories')
          .select()
          .eq('id', categoryId)
          .single();
      return Category.fromJson(response);
    } catch (e) {
      throw Exception('Failed to load category: $e');
    }
  }

  Future<Quiz> getQuizById(String quizId) async {
    try {
      final response = await _supabase
          .from('quizzes')
          .select()
          .eq('id', quizId)
          .single();
      return Quiz.fromJson(response);
    } catch (e) {
      throw Exception('Failed to load quiz: $e');
    }
  }
}
