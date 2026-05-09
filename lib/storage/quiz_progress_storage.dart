import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/quiz_progress.dart';

class QuizProgressStorage {
  static String _key(String quizId) => 'quiz_progress_$quizId';

  Future<void> save(QuizProgress progress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(progress.quizId), jsonEncode(progress.toJson()));
  }

  Future<QuizProgress?> load(String quizId) async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key(quizId));
    if (data == null) return null;
    return QuizProgress.fromJson(jsonDecode(data));
  }

  Future<void> clear(String quizId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(quizId));
  }

  Future<bool> hasProgress(String quizId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_key(quizId));
  }
}
