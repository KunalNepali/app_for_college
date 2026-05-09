import 'package:quiz_app_supabase/models/category.dart';
import 'package:quiz_app_supabase/models/question.dart';
import 'package:quiz_app_supabase/models/section.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  static const int _pageSize = 1000;

  Future<List<Category>> getCategoriesPage({required int from}) async {
    try {
      final response = await _supabase
          .from('categories')
          .select()
          .order('created_at', ascending: true)
          .range(from, from + _pageSize - 1);

      return (response as List)
          .map((category) => Category.fromJson(category))
          .toList();
    } catch (e) {
      throw Exception('Failed to load categories from Supabase: $e');
    }
  }

  Future<List<Section>> getSectionsPage({required int from}) async {
    try {
      final response = await _supabase
          .from('sections')
          .select()
          .order('created_at', ascending: true)
          .range(from, from + _pageSize - 1);

      return (response as List)
          .map((section) => Section.fromJson(section))
          .toList();
    } catch (e) {
      throw Exception('Failed to load sections from Supabase: $e');
    }
  }

  Future<List<Question>> getQuestionsPage({required int from}) async {
    try {
      final response = await _supabase
          .from('questions')
          .select()
          .order('created_at', ascending: true)
          .range(from, from + _pageSize - 1);

      return (response as List)
          .map((question) => Question.fromJson(question))
          .toList();
    } catch (e) {
      throw Exception('Failed to load questions from Supabase: $e');
    }
  }
}
