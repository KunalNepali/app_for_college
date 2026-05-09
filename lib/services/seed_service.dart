import 'dart:convert';

import 'package:flutter/services.dart';

import 'package:quiz_app_supabase/db/local_db.dart';

class SeedService {
  SeedService(this._localDb);

  final LocalDb _localDb;

  Future<void> seedIfNeeded() async {
    final categoriesCount = await _localDb.countRows('categories');
    final quizzesCount = await _localDb.countRows('quizzes');
    final questionsCount = await _localDb.countRows('questions');

    if (categoriesCount > 0 || quizzesCount > 0 || questionsCount > 0) {
      return;
    }

    final categories = await _readListAsset('assets/seed/categories.json');
    final quizzes = await _readListAsset('assets/seed/quizzes.json');
    final questionFilePaths = await _readQuestionChunkPaths();

    final questions = <Map<String, dynamic>>[];
    for (final path in questionFilePaths) {
      final chunk = await _readListAsset(path);
      questions.addAll(chunk);
    }

    await _localDb.seedData(
      categories: categories,
      quizzes: quizzes,
      questions: questions,
    );
  }

  Future<List<String>> _readQuestionChunkPaths() async {
    try {
      final indexRaw = await rootBundle.loadString('assets/seed/questions_index.json');
      final decoded = jsonDecode(indexRaw) as Map<String, dynamic>;
      final files = (decoded['files'] as List<dynamic>)
          .map((e) => e as String)
          .toList();

      if (files.isNotEmpty) {
        return files;
      }
    } catch (_) {
      // Fallback to single-file seed.
    }

    return ['assets/seed/questions.json'];
  }

  Future<List<Map<String, dynamic>>> _readListAsset(String path) async {
    final raw = await rootBundle.loadString(path);
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }
}
