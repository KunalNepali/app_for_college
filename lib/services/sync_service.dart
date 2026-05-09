import '../services/local_database_service.dart';
import '../services/supabase_service.dart';

class SyncService {
  SyncService({
    required this.localDatabaseService,
    required this.supabaseService,
  });

  final LocalDatabaseService localDatabaseService;
  final SupabaseService supabaseService;

  Future<void> syncAll() async {
    await _syncCategories();
    await _syncSections();
    await _syncQuestions();
  }

  Future<void> _syncCategories() async {
    var from = 0;
    while (true) {
      final categories = await supabaseService.getCategoriesPage(from: from);
      if (categories.isEmpty) break;
      await localDatabaseService.upsertCategories(categories);
      if (categories.length < 1000) break;
      from += 1000;
    }
  }

  Future<void> _syncSections() async {
    var from = 0;
    while (true) {
      final sections = await supabaseService.getSectionsPage(from: from);
      if (sections.isEmpty) break;
      await localDatabaseService.upsertSections(sections);
      if (sections.length < 1000) break;
      from += 1000;
    }
  }

  Future<void> _syncQuestions() async {
    var from = 0;
    while (true) {
      final questions = await supabaseService.getQuestionsPage(from: from);
      if (questions.isEmpty) break;
      await localDatabaseService.upsertQuestions(questions);
      if (questions.length < 1000) break;
      from += 1000;
    }
  }
}
