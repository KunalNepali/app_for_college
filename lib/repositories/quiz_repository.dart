import 'package:quiz_app_supabase/models/category.dart';
import 'package:quiz_app_supabase/models/question.dart';
import 'package:quiz_app_supabase/models/quiz.dart';
import 'package:quiz_app_supabase/services/local/local_database_service.dart';
import 'package:quiz_app_supabase/services/local/seed_service.dart';
import 'package:quiz_app_supabase/services/supabase_sync_service.dart';

class QuizRepository {
  QuizRepository({
    required this.localDatabaseService,
    required this.seedService,
    required this.supabaseSyncService,
  });

  final LocalDatabaseService localDatabaseService;
  final SeedService seedService;
  final SupabaseSyncService supabaseSyncService;

  Future<void>? _initialization;

  Future<void> _ensureInitialized() {
    return _initialization ??= _initialize();
  }

  Future<void> _initialize() async {
    await localDatabaseService.database;
    await seedService.importIfNeeded();
  }

  Future<List<Category>> getCategories() async {
    await _ensureInitialized();
    return localDatabaseService.getCategories();
  }

  Future<List<Quiz>> getQuizzesByCategory(String categoryId) async {
    await _ensureInitialized();
    return localDatabaseService.getQuizzesByCategory(categoryId);
  }

  Future<List<Question>> getQuestionsByQuiz(String quizId) async {
    await _ensureInitialized();
    return localDatabaseService.getQuestionsByQuiz(quizId);
  }

  Future<SyncResult> syncNow() async {
    await _ensureInitialized();
    return supabaseSyncService.sync();
  }
}
