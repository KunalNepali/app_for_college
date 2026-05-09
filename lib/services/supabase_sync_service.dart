import 'package:quiz_app_supabase/services/local/local_database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SyncResult {
  const SyncResult({required this.success, required this.message});

  final bool success;
  final String message;
}

class SupabaseSyncService {
  SupabaseSyncService({
    required this.localDatabaseService,
    SupabaseClient? supabaseClient,
  }) : _supabase = supabaseClient ?? Supabase.instance.client;

  static const String _lastSyncKey = 'last_sync_at';

  final LocalDatabaseService localDatabaseService;
  final SupabaseClient _supabase;

  Future<SyncResult> sync() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final lastSyncAt = preferences.getString(_lastSyncKey);

      try {
        await _incrementalSync(lastSyncAt);
      } on PostgrestException catch (_) {
        await _fullSync();
      }

      await preferences.setString(
        _lastSyncKey,
        DateTime.now().toUtc().toIso8601String(),
      );

      return const SyncResult(success: true, message: 'Data synced');
    } catch (error) {
      return SyncResult(
        success: false,
        message: 'Using offline data. Sync failed: $error',
      );
    }
  }

  Future<void> _incrementalSync(String? lastSyncAt) async {
    if (lastSyncAt == null) {
      await _fullSync();
      return;
    }

    final categories = await _fetchIncremental('categories', lastSyncAt);
    final quizzes = await _fetchIncremental('quizzes', lastSyncAt);
    final questions = await _fetchIncremental('questions', lastSyncAt);

    await localDatabaseService.upsertCategories(categories);
    await localDatabaseService.upsertQuizzes(quizzes);
    await localDatabaseService.upsertQuestions(questions);
  }

  Future<void> _fullSync() async {
    final categories = await _fetchAll('categories');
    final quizzes = await _fetchAll('quizzes');
    final questions = await _fetchAll('questions');

    await localDatabaseService.upsertCategories(categories);
    await localDatabaseService.upsertQuizzes(quizzes);
    await localDatabaseService.upsertQuestions(questions);
  }

  Future<List<Map<String, dynamic>>> _fetchIncremental(
    String table,
    String lastSyncAt,
  ) async {
    final response = await _supabase
        .from(table)
        .select()
        .gte('updated_at', lastSyncAt)
        .order('updated_at', ascending: true);

    return _asRows(response);
  }

  Future<List<Map<String, dynamic>>> _fetchAll(String table) async {
    const pageSize = 1000;
    var offset = 0;
    final rows = <Map<String, dynamic>>[];

    while (true) {
      final response = await _supabase
          .from(table)
          .select()
          .order('created_at', ascending: true)
          .range(offset, offset + pageSize - 1);

      final page = _asRows(response);
      if (page.isEmpty) {
        break;
      }

      rows.addAll(page);

      if (page.length < pageSize) {
        break;
      }

      offset += pageSize;
    }

    return rows;
  }

  List<Map<String, dynamic>> _asRows(dynamic response) {
    return (response as List<dynamic>)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }
}
