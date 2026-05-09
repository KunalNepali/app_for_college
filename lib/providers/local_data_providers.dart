import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:quiz_app_supabase/db/local_db.dart';
import 'package:quiz_app_supabase/models/category.dart';
import 'package:quiz_app_supabase/models/question.dart';
import 'package:quiz_app_supabase/models/quiz.dart';
import 'package:quiz_app_supabase/repositories/quiz_repository.dart';
import 'package:quiz_app_supabase/services/seed_service.dart';
import 'package:quiz_app_supabase/services/sync_service.dart';

final localDbProvider = Provider<LocalDb>((ref) => LocalDb.instance);

final seedServiceProvider = Provider<SeedService>(
  (ref) => SeedService(ref.read(localDbProvider)),
);

final syncServiceProvider = Provider<SyncService>(
  (ref) => SyncService(ref.read(localDbProvider)),
);

final quizRepositoryProvider = Provider<QuizRepository>(
  (ref) => QuizRepository(ref.read(localDbProvider)),
);

final appInitializationProvider = FutureProvider<void>((ref) async {
  final localDb = ref.read(localDbProvider);
  await localDb.init();

  final seedService = ref.read(seedServiceProvider);
  await seedService.seedIfNeeded();

  unawaited(
    ref
        .read(syncServiceProvider)
        .syncFromSupabase()
        .catchError((Object error, StackTrace stackTrace) {
          debugPrint('Background sync failed on startup: $error');
          debugPrintStack(stackTrace: stackTrace);
        }),
  );
});

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  await ref.watch(appInitializationProvider.future);
  return ref.read(quizRepositoryProvider).getCategories();
});

final quizzesByCategoryProvider = FutureProvider.family<List<Quiz>, String>(
  (ref, categoryId) async {
    await ref.watch(appInitializationProvider.future);
    return ref.read(quizRepositoryProvider).getQuizzesByCategory(categoryId);
  },
);

final questionsByQuizProvider = FutureProvider.family<List<Question>, String>(
  (ref, quizId) async {
    await ref.watch(appInitializationProvider.future);
    return ref.read(quizRepositoryProvider).getQuestionsByQuiz(quizId);
  },
);
