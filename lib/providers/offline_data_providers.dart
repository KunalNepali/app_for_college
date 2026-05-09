import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quiz_app_supabase/models/category.dart';
import 'package:quiz_app_supabase/models/question.dart';
import 'package:quiz_app_supabase/models/quiz.dart';
import 'package:quiz_app_supabase/repositories/quiz_repository.dart';
import 'package:quiz_app_supabase/services/local/local_database_service.dart';
import 'package:quiz_app_supabase/services/local/seed_service.dart';
import 'package:quiz_app_supabase/services/supabase_sync_service.dart';

final localDatabaseServiceProvider = Provider<LocalDatabaseService>((ref) {
  return LocalDatabaseService.instance;
});

final seedServiceProvider = Provider<SeedService>((ref) {
  return SeedService(
    localDatabaseService: ref.watch(localDatabaseServiceProvider),
  );
});

final supabaseSyncServiceProvider = Provider<SupabaseSyncService>((ref) {
  return SupabaseSyncService(
    localDatabaseService: ref.watch(localDatabaseServiceProvider),
  );
});

final quizRepositoryProvider = Provider<QuizRepository>((ref) {
  return QuizRepository(
    localDatabaseService: ref.watch(localDatabaseServiceProvider),
    seedService: ref.watch(seedServiceProvider),
    supabaseSyncService: ref.watch(supabaseSyncServiceProvider),
  );
});

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  return ref.watch(quizRepositoryProvider).getCategories();
});

final quizzesByCategoryProvider =
    FutureProvider.family<List<Quiz>, String>((ref, categoryId) async {
      return ref.watch(quizRepositoryProvider).getQuizzesByCategory(categoryId);
    });

final questionsByQuizProvider =
    FutureProvider.family<List<Question>, String>((ref, quizId) async {
      return ref.watch(quizRepositoryProvider).getQuestionsByQuiz(quizId);
    });

final backgroundSyncProvider = FutureProvider<SyncResult>((ref) async {
  return ref.watch(quizRepositoryProvider).syncNow();
});

final syncStatusProvider =
    AsyncNotifierProvider<SyncStatusNotifier, SyncResult?>(
      SyncStatusNotifier.new,
    );

class SyncStatusNotifier extends AsyncNotifier<SyncResult?> {
  @override
  Future<SyncResult?> build() async {
    return null;
  }

  Future<SyncResult> syncNow() async {
    state = const AsyncLoading();
    final result = await ref.read(quizRepositoryProvider).syncNow();
    state = AsyncData(result);
    return result;
  }
}
