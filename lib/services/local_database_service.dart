import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/category.dart';
import '../models/question.dart';
import '../models/section.dart';
import '../models/section_attempt.dart';

class LocalDatabaseService {
  LocalDatabaseService._();

  static final LocalDatabaseService instance = LocalDatabaseService._();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _openDatabase();
    return _database!;
  }

  Future<Database> _openDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final dbPath = p.join(directory.path, 'quiz_app.db');

    return openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE categories (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            description TEXT,
            icon TEXT,
            created_at TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE sections (
            id TEXT PRIMARY KEY,
            category_id TEXT NOT NULL,
            name TEXT NOT NULL,
            sort_order INTEGER,
            created_at TEXT
          )
        ''');

        await db.execute(
          'CREATE INDEX idx_sections_category_id ON sections(category_id)',
        );

        await db.execute('''
          CREATE TABLE questions (
            id TEXT PRIMARY KEY,
            section_id TEXT NOT NULL,
            question_text TEXT NOT NULL,
            option_a TEXT NOT NULL,
            option_b TEXT NOT NULL,
            option_c TEXT NOT NULL,
            option_d TEXT NOT NULL,
            correct_answer TEXT NOT NULL,
            created_at TEXT
          )
        ''');

        await db.execute(
          'CREATE INDEX idx_questions_section_id ON questions(section_id)',
        );

        await db.execute('''
          CREATE TABLE section_attempts (
            section_id TEXT PRIMARY KEY,
            question_ids_json TEXT NOT NULL,
            current_index INTEGER NOT NULL DEFAULT 0,
            answers_json TEXT NOT NULL DEFAULT '{}',
            started_at TEXT,
            updated_at TEXT
          )
        ''');
      },
    );
  }

  Future<void> upsertCategories(List<Category> categories) async {
    if (categories.isEmpty) return;
    final db = await database;
    final batch = db.batch();

    for (final category in categories) {
      batch.insert(
        'categories',
        category.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  Future<void> upsertSections(List<Section> sections) async {
    if (sections.isEmpty) return;
    final db = await database;
    final batch = db.batch();

    for (final section in sections) {
      batch.insert(
        'sections',
        section.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  Future<void> upsertQuestions(List<Question> questions) async {
    if (questions.isEmpty) return;
    final db = await database;
    final batch = db.batch();

    for (final question in questions) {
      batch.insert(
        'questions',
        question.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  Future<List<Category>> getCategories() async {
    final db = await database;
    final rows = await db.query('categories', orderBy: 'created_at ASC');
    return rows.map(Category.fromJson).toList();
  }

  Future<List<Section>> getSectionsByCategory(String categoryId) async {
    final db = await database;
    final rows = await db.query(
      'sections',
      where: 'category_id = ?',
      whereArgs: [categoryId],
      orderBy: 'sort_order ASC, name ASC',
    );

    return rows.map(Section.fromJson).toList();
  }

  Future<int> getQuestionCountBySection(String sectionId) async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM questions WHERE section_id = ?',
      [sectionId],
    );
    return (rows.first['c'] as int?) ?? 0;
  }

  Future<List<String>> getQuestionIdsBySection(String sectionId) async {
    final db = await database;
    final rows = await db.query(
      'questions',
      columns: ['id'],
      where: 'section_id = ?',
      whereArgs: [sectionId],
      orderBy: 'created_at ASC, id ASC',
    );

    return rows.map((row) => row['id'] as String).toList();
  }

  Future<List<Question>> getQuestionsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];

    final db = await database;
    final placeholders = List.filled(ids.length, '?').join(',');
    final rows = await db.rawQuery(
      'SELECT * FROM questions WHERE id IN ($placeholders)',
      ids,
    );

    final mapped = {for (final row in rows) row['id'] as String: Question.fromJson(row)};
    return ids.map((id) => mapped[id]).whereType<Question>().toList();
  }

  Future<SectionAttempt?> getSectionAttempt(String sectionId) async {
    final db = await database;
    final rows = await db.query(
      'section_attempts',
      where: 'section_id = ?',
      whereArgs: [sectionId],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    final row = rows.first;

    return SectionAttempt(
      sectionId: row['section_id'] as String,
      questionIds: List<String>.from(jsonDecode(row['question_ids_json'] as String)),
      currentIndex: (row['current_index'] as int?) ?? 0,
      answersByQuestionId: Map<String, String>.from(
        jsonDecode((row['answers_json'] as String?) ?? '{}') as Map,
      ),
      startedAt: DateTime.tryParse((row['started_at'] ?? '') as String) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.tryParse((row['updated_at'] ?? '') as String) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Future<void> saveSectionAttempt(SectionAttempt attempt) async {
    final db = await database;

    await db.insert('section_attempts', {
      'section_id': attempt.sectionId,
      'question_ids_json': jsonEncode(attempt.questionIds),
      'current_index': attempt.currentIndex,
      'answers_json': jsonEncode(attempt.answersByQuestionId),
      'started_at': attempt.startedAt.toIso8601String(),
      'updated_at': attempt.updatedAt.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteSectionAttempt(String sectionId) async {
    final db = await database;
    await db.delete(
      'section_attempts',
      where: 'section_id = ?',
      whereArgs: [sectionId],
    );
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('categories');
    await db.delete('sections');
    await db.delete('questions');
    await db.delete('section_attempts');
  }
}
