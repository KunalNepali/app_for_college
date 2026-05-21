import 'package:quiz_app_supabase/models/category.dart';
import 'package:quiz_app_supabase/models/question.dart';
import 'package:quiz_app_supabase/models/section.dart';
import 'package:quiz_app_supabase/models/notice.dart';
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

  Future<List<Section>> getSectionsByCategory(String categoryId) async {
    try {
      final response = await _supabase
          .from('sections')
          .select()
          .eq('category_id', categoryId)
          .order('sort_order', ascending: true)
          .order('created_at', ascending: true);

      return (response as List)
          .map((row) => Section.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to load sections: $e');
    }
  }

  Future<List<Question>> getQuestionsBySection(String sectionId) async {
    try {
      final response = await _supabase
          .from('questions')
          .select()
          .eq('section_id', sectionId)
          .order('created_at', ascending: true);

      return (response as List)
          .map((row) => Question.fromJson(row as Map<String, dynamic>))
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

  Future<List<Notice>> getNoticesByType(String type) async {
    final data = await _supabase
        .from('notices')
        .select()
        .eq('type', type)
        .order('notice_date', ascending: false);

    return (data as List)
        .map((e) => Notice.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
