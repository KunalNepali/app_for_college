import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/category.dart';
import '../models/question.dart';
import '../models/section.dart';
import 'local_database_service.dart';

class SeedImportService {
  SeedImportService(this._databaseService);

  static const _seedFlagKey = 'seed_imported_v2';

  final LocalDatabaseService _databaseService;

  Future<void> importIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final imported = prefs.getBool(_seedFlagKey) ?? false;
    if (imported) return;

    final categoriesJson = jsonDecode(
      await rootBundle.loadString('assets/seed/categories.json'),
    ) as List;
    final sectionsJson = jsonDecode(
      await rootBundle.loadString('assets/seed/sections.json'),
    ) as List;
    final manifestJson = jsonDecode(
      await rootBundle.loadString('assets/seed/questions_manifest.json'),
    ) as List;

    final categories = categoriesJson
        .cast<Map<String, dynamic>>()
        .map(Category.fromJson)
        .toList();
    final sections = sectionsJson
        .cast<Map<String, dynamic>>()
        .map(Section.fromJson)
        .toList();

    await _databaseService.upsertCategories(categories);
    await _databaseService.upsertSections(sections);

    for (final chunkPath in manifestJson.cast<String>()) {
      final chunkJson = jsonDecode(await rootBundle.loadString(chunkPath)) as List;
      final questions = chunkJson
          .cast<Map<String, dynamic>>()
          .map(Question.fromJson)
          .toList();
      await _databaseService.upsertQuestions(questions);
    }

    await prefs.setBool(_seedFlagKey, true);
  }
}
