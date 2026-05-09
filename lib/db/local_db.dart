import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'package:quiz_app_supabase/models/category.dart';
import 'package:quiz_app_supabase/models/question.dart';
import 'package:quiz_app_supabase/models/quiz.dart';

class LocalDb {
  LocalDb._();

  static final LocalDb instance = LocalDb._();

  static const _dbName = 'quiz_local.db';
  static const _dbVersion = 1;

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _open();
    return _database!;
  }

  Future<void> init() async {
    await database;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE categories (
            id TEXT PRIMARY KEY,
            name TEXT,
            description TEXT,
            icon TEXT,
            created_at TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE quizzes (
            id TEXT PRIMARY KEY,
            category_id TEXT,
            title TEXT,
            description TEXT,
            created_at TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE questions (
            id TEXT PRIMARY KEY,
            quiz_id TEXT,
            question_text TEXT,
            option_a TEXT,
            option_b TEXT,
            option_c TEXT,
            option_d TEXT,
            correct_answer TEXT,
            created_at TEXT
          )
        ''');

        await db.execute(
          'CREATE INDEX idx_quizzes_category_id ON quizzes(category_id)',
        );
        await db.execute('CREATE INDEX idx_questions_quiz_id ON questions(quiz_id)');
      },
    );
  }

  Future<int> countRows(String tableName) async {
    final db = await database;
    late final List<Map<String, Object?>> result;
    switch (tableName) {
      case 'categories':
        result = await db.rawQuery('SELECT COUNT(*) as count FROM categories');
        break;
      case 'quizzes':
        result = await db.rawQuery('SELECT COUNT(*) as count FROM quizzes');
        break;
      case 'questions':
        result = await db.rawQuery('SELECT COUNT(*) as count FROM questions');
        break;
      default:
        throw ArgumentError.value(tableName, 'tableName', 'Unsupported table');
    }
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> seedData({
    required List<Map<String, dynamic>> categories,
    required List<Map<String, dynamic>> quizzes,
    required List<Map<String, dynamic>> questions,
  }) async {
    final db = await database;

    await db.transaction((txn) async {
      final batch = txn.batch();

      for (final row in categories) {
        batch.insert('categories', row, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      for (final row in quizzes) {
        batch.insert('quizzes', row, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      for (final row in questions) {
        batch.insert('questions', row, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      await batch.commit(noResult: true);
    });
  }

  Future<void> upsertCategories(List<Map<String, dynamic>> categories) async {
    if (categories.isEmpty) return;
    final db = await database;
    final batch = db.batch();
    for (final row in categories) {
      batch.insert('categories', row, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> upsertQuizzes(List<Map<String, dynamic>> quizzes) async {
    if (quizzes.isEmpty) return;
    final db = await database;
    final batch = db.batch();
    for (final row in quizzes) {
      batch.insert('quizzes', row, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<void> upsertQuestions(List<Map<String, dynamic>> questions) async {
    if (questions.isEmpty) return;
    final db = await database;
    final batch = db.batch();
    for (final row in questions) {
      batch.insert('questions', row, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Category>> getCategories() async {
    final db = await database;
    final result = await db.query('categories', orderBy: 'created_at ASC');
    return result.map((row) => Category.fromJson(row)).toList();
  }

  Future<List<Quiz>> getQuizzesByCategory(String categoryId) async {
    final db = await database;
    final result = await db.query(
      'quizzes',
      where: 'category_id = ?',
      whereArgs: [categoryId],
      orderBy: 'created_at ASC',
    );
    return result.map((row) => Quiz.fromJson(row)).toList();
  }

  Future<List<Question>> getQuestionsByQuiz(String quizId) async {
    final db = await database;
    final result = await db.query(
      'questions',
      where: 'quiz_id = ?',
      whereArgs: [quizId],
      orderBy: 'created_at ASC',
    );
    return result.map((row) => Question.fromJson(row)).toList();
  }
}
