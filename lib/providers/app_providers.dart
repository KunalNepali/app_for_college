import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/category.dart';
import '../models/section.dart';
import '../repositories/quiz_repository.dart';
import '../services/local_database_service.dart';
import '../services/seed_import_service.dart';
import '../services/supabase_service.dart';
import '../services/sync_service.dart';

final localDatabaseServiceProvider = Provider<LocalDatabaseService>((ref) {
  return LocalDatabaseService.instance;
});

final seedImportServiceProvider = Provider<SeedImportService>((ref) {
  return SeedImportService(ref.read(localDatabaseServiceProvider));
});

final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService();
});

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
    localDatabaseService: ref.read(localDatabaseServiceProvider),
    supabaseService: ref.read(supabaseServiceProvider),
  );
});

final quizRepositoryProvider = Provider<QuizRepository>((ref) {
  return QuizRepository(ref.read(localDatabaseServiceProvider));
});

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  return ref.read(quizRepositoryProvider).getCategories();
});

final sectionsByCategoryProvider = FutureProvider.family<List<Section>, String>(
  (ref, categoryId) async {
    return ref.read(quizRepositoryProvider).getSectionsByCategory(categoryId);
  },
);

final hasSectionAttemptProvider = FutureProvider.family<bool, String>((
  ref,
  sectionId,
) async {
  return ref.read(quizRepositoryProvider).hasAttempt(sectionId);
});
