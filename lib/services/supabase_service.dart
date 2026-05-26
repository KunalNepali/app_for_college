import 'dart:convert';

import 'package:quiz_app_supabase/models/category.dart';
import 'package:quiz_app_supabase/models/notice.dart';
import 'package:quiz_app_supabase/models/question.dart';
import 'package:quiz_app_supabase/models/section.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  static const _categoriesCacheKey = 'categories_cache_v1';
  static const _sectionsCachePrefix = 'sections_cache_v1_'; // + categoryId
  static const _questionsCachePrefix = 'questions_cache_v1_'; // + sectionId

  /// Returns:
  /// - categories: list of categories
  /// - fromCache: true if loaded from local cache (offline fallback)
  Future<({List<Category> categories, bool fromCache})> getCategories() async {
    final prefs = await SharedPreferences.getInstance();

    try {
      final response = await _supabase
          .from('categories')
          .select()
          .order('created_at', ascending: true);

      // Cache the raw rows (best for forward compatibility)
      final rawRows = (response as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      await prefs.setString(_categoriesCacheKey, jsonEncode(rawRows));

      final categories = rawRows.map((row) => Category.fromJson(row)).toList();
      return (categories: categories, fromCache: false);
    } catch (e) {
      // fallback to cache
      final cached = prefs.getString(_categoriesCacheKey);
      if (cached != null) {
        final decoded = jsonDecode(cached) as List;
        final rows = decoded
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();

        final categories = rows.map((row) => Category.fromJson(row)).toList();
        return (categories: categories, fromCache: true);
      }

      throw Exception('Failed to load categories: $e');
    }
  }

  Future<({List<Section> sections, bool fromCache})> getSectionsByCategory(
    String categoryId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = '$_sectionsCachePrefix$categoryId';

    try {
      final response = await _supabase
          .from('sections')
          .select()
          .eq('category_id', categoryId)
          .order('sort_order', ascending: true)
          .order('created_at', ascending: true);

      final rawRows = (response as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      await prefs.setString(cacheKey, jsonEncode(rawRows));

      final sections = rawRows.map((row) => Section.fromJson(row)).toList();
      return (sections: sections, fromCache: false);
    } catch (e) {
      final cached = prefs.getString(cacheKey);
      if (cached != null) {
        final decoded = jsonDecode(cached) as List;
        final rows = decoded
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();

        final sections = rows.map((row) => Section.fromJson(row)).toList();
        return (sections: sections, fromCache: true);
      }
      throw Exception('Failed to load sections: $e');
    }
  }

  Future<({List<Question> questions, bool fromCache})> getQuestionsBySection(
    String sectionId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = '$_questionsCachePrefix$sectionId';

    try {
      final response = await _supabase
          .from('questions')
          .select()
          .eq('section_id', sectionId)
          .order('created_at', ascending: true);

      final rawRows = (response as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      await prefs.setString(cacheKey, jsonEncode(rawRows));

      final questions = rawRows.map((row) => Question.fromJson(row)).toList();
      return (questions: questions, fromCache: false);
    } catch (e) {
      final cached = prefs.getString(cacheKey);
      if (cached != null) {
        final decoded = jsonDecode(cached) as List;
        final rows = decoded
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();

        final questions = rows.map((row) => Question.fromJson(row)).toList();
        return (questions: questions, fromCache: true);
      }
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

  Future<int> getQuestionCountBySection(String sectionId) async {
    try {
      final res = await _supabase
          .from('questions')
          .select('id')
          .eq('section_id', sectionId);

      return (res as List).length;
    } catch (e) {
      throw Exception('Failed to count questions: $e');
    }
  }

  Future<List<Question>> getQuestionsBySectionBatch({
    required String sectionId,
    required int offset,
    required int limit,
  }) async {
    try {
      final res = await _supabase
          .from('questions')
          .select()
          .eq('section_id', sectionId)
          .order('created_at', ascending: true)
          .order('id', ascending: true)
          .range(offset, offset + limit - 1);

      return (res as List).map((q) => Question.fromJson(q)).toList();
    } catch (e) {
      throw Exception('Failed to load questions batch: $e');
    }
  }
}
