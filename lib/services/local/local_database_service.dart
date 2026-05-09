import 'package:path/path.dart' as p;
import 'package:quiz_app_supabase/models/category.dart';
import 'package:quiz_app_supabase/models/question.dart';
import 'package:quiz_app_supabase/models/quiz.dart';
import 'package:sqflite/sqflite.dart';

class LocalDatabaseService {
  LocalDatabaseService._();

  static final LocalDatabaseService instance = LocalDatabaseService._();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'quiz_app.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async => _createSchema(db),
      onOpen: (db) async => _createSchema(db),
    );

    return _database!;
  }

  Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        icon TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS quizzes(
        id TEXT PRIMARY KEY,
        category_id TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS questions(
        id TEXT PRIMARY KEY,
        quiz_id TEXT NOT NULL,
        question_text TEXT NOT NULL,
        option_a TEXT NOT NULL,
        option_b TEXT NOT NULL,
        option_c TEXT NOT NULL,
        option_d TEXT NOT NULL,
        correct_answer TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS metadata(
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_quizzes_category_id ON quizzes(category_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_questions_quiz_id ON questions(quiz_id)',
    );
  }

  Future<bool> hasSeedData() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) AS count FROM categories');
    final count = Sqflite.firstIntValue(result) ?? 0;
    return count > 0;
  }

  Future<String?> getMetadataValue(String key) async {
    final db = await database;
    final result = await db.query(
      'metadata',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return result.first['value'] as String;
  }

  Future<void> setMetadataValue(String key, String value) async {
    final db = await database;
    await db.insert('metadata', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> clearContent() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('questions');
      await txn.delete('quizzes');
      await txn.delete('categories');
    });
  }

  Future<void> upsertCategories(List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) return;

    final db = await database;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final row in rows) {
        batch.insert(
          'categories',
          _normalizeRow(
            row,
            allowedKeys: const [
              'id',
              'name',
              'description',
              'icon',
              'created_at',
              'updated_at',
            ],
            requiredKeys: const ['id', 'name', 'created_at'],
          ),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  Future<void> upsertQuizzes(List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) return;

    final db = await database;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final row in rows) {
        batch.insert(
          'quizzes',
          _normalizeRow(
            row,
            allowedKeys: const [
              'id',
              'category_id',
              'title',
              'description',
              'created_at',
              'updated_at',
            ],
            requiredKeys: const ['id', 'category_id', 'title', 'created_at'],
          ),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  Future<void> upsertQuestions(List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) return;

    final db = await database;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final row in rows) {
        batch.insert(
          'questions',
          _normalizeRow(
            row,
            allowedKeys: const [
              'id',
              'quiz_id',
              'question_text',
              'option_a',
              'option_b',
              'option_c',
              'option_d',
              'correct_answer',
              'created_at',
              'updated_at',
            ],
            requiredKeys: const [
              'id',
              'quiz_id',
              'question_text',
              'option_a',
              'option_b',
              'option_c',
              'option_d',
              'correct_answer',
              'created_at',
            ],
          ),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  Future<List<Category>> getCategories() async {
    final db = await database;
    final rows = await db.query('categories', orderBy: 'created_at ASC');
    return rows.map((row) => Category.fromJson(Map<String, dynamic>.from(row))).toList();
  }

  Future<List<Quiz>> getQuizzesByCategory(String categoryId) async {
    final db = await database;
    final rows = await db.query(
      'quizzes',
      where: 'category_id = ?',
      whereArgs: [categoryId],
      orderBy: 'created_at ASC',
    );
    return rows.map((row) => Quiz.fromJson(Map<String, dynamic>.from(row))).toList();
  }

  Future<List<Question>> getQuestionsByQuiz(String quizId) async {
    final db = await database;
    final rows = await db.query(
      'questions',
      where: 'quiz_id = ?',
      whereArgs: [quizId],
      orderBy: 'created_at ASC',
    );
    return rows.map((row) => Question.fromJson(Map<String, dynamic>.from(row))).toList();
  }

  Map<String, dynamic> _normalizeRow(
    Map<String, dynamic> row, {
    required List<String> allowedKeys,
    required List<String> requiredKeys,
  }) {
    final normalized = <String, dynamic>{};

    for (final entry in row.entries) {
      if (!allowedKeys.contains(entry.key)) continue;
      final value = entry.value;
      if (value is DateTime) {
        normalized[entry.key] = value.toIso8601String();
      } else {
        normalized[entry.key] = value;
      }
    }

    for (final key in requiredKeys) {
      if (normalized[key] == null) {
        if (key == 'created_at') {
          normalized[key] = DateTime.now().toIso8601String();
        } else {
          normalized[key] = '';
        }
      }
    }

    return normalized;
  }
}
