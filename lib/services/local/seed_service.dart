import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:quiz_app_supabase/services/local/local_database_service.dart';

class SeedService {
  SeedService({
    required this.localDatabaseService,
    this.assetBundle = rootBundle,
  });

  static const String _seedVersionKey = 'seed_version';
  static const String currentSeedVersion = '1';

  final LocalDatabaseService localDatabaseService;
  final AssetBundle assetBundle;

  Future<void> importIfNeeded() async {
    final hasData = await localDatabaseService.hasSeedData();
    final existingVersion = await localDatabaseService.getMetadataValue(
      _seedVersionKey,
    );

    if (hasData && existingVersion == currentSeedVersion) {
      return;
    }

    final categories = await _readArrayFile('assets/seed/categories.json');
    final quizzes = await _readArrayFile('assets/seed/quizzes.json');
    final questionFiles = await _questionSeedFiles();

    final allQuestions = <Map<String, dynamic>>[];
    for (final questionFile in questionFiles) {
      final chunk = await _readArrayFile(questionFile);
      allQuestions.addAll(chunk);
    }

    await localDatabaseService.clearContent();
    await localDatabaseService.upsertCategories(categories);
    await localDatabaseService.upsertQuizzes(quizzes);
    await localDatabaseService.upsertQuestions(allQuestions);
    await localDatabaseService.setMetadataValue(
      _seedVersionKey,
      currentSeedVersion,
    );
  }

  Future<List<Map<String, dynamic>>> _readArrayFile(String assetPath) async {
    final raw = await assetBundle.loadString(assetPath);
    final decoded = jsonDecode(raw) as List<dynamic>;

    return decoded
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<List<String>> _questionSeedFiles() async {
    final raw = await assetBundle.loadString('assets/seed/questions/index.json');
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.map((path) => path as String).toList()..sort();
  }
}
