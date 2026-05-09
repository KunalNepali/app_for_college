import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:quiz_app_supabase/db/local_db.dart';

class SyncService {
  SyncService(this._localDb);

  static const _lastSyncKey = 'last_sync_at';

  final LocalDb _localDb;
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> syncFromSupabase({int pageSize = 500}) async {
    final prefs = await SharedPreferences.getInstance();
    final lastSyncAt = prefs.getString(_lastSyncKey);

    try {
      await _syncCategories(lastSyncAt: lastSyncAt, pageSize: pageSize);
      await _syncQuizzes(lastSyncAt: lastSyncAt, pageSize: pageSize);
      await _syncQuestions(lastSyncAt: lastSyncAt, pageSize: pageSize);
      await prefs.setString(_lastSyncKey, DateTime.now().toUtc().toIso8601String());
    } catch (_) {
      // Keep offline-first behavior: if sync fails (offline/network), keep local data.
    }
  }

  Future<void> _syncCategories({String? lastSyncAt, required int pageSize}) async {
    await _syncTable(
      table: 'categories',
      lastSyncAt: lastSyncAt,
      pageSize: pageSize,
      upsert: _localDb.upsertCategories,
    );
  }

  Future<void> _syncQuizzes({String? lastSyncAt, required int pageSize}) async {
    await _syncTable(
      table: 'quizzes',
      lastSyncAt: lastSyncAt,
      pageSize: pageSize,
      upsert: _localDb.upsertQuizzes,
    );
  }

  Future<void> _syncQuestions({String? lastSyncAt, required int pageSize}) async {
    await _syncTable(
      table: 'questions',
      lastSyncAt: lastSyncAt,
      pageSize: pageSize,
      upsert: _localDb.upsertQuestions,
    );
  }

  Future<void> _syncTable({
    required String table,
    required int pageSize,
    required Future<void> Function(List<Map<String, dynamic>>) upsert,
    String? lastSyncAt,
  }) async {
    int offset = 0;
    bool fallbackTried = false;

    while (true) {
      try {
        var query = _supabase.from(table).select();

        if (lastSyncAt != null) {
          query = query.gte('updated_at', lastSyncAt);
        }

        final response = await query
            .order('created_at', ascending: true)
            .range(offset, offset + pageSize - 1);

        final rows = (response as List<dynamic>)
            .map((row) => Map<String, dynamic>.from(row as Map))
            .toList();

        if (rows.isEmpty) {
          break;
        }

        await upsert(rows);

        if (rows.length < pageSize) {
          break;
        }

        offset += pageSize;
      } on PostgrestException catch (e) {
        if (lastSyncAt != null && !fallbackTried && e.message.contains('updated_at')) {
          fallbackTried = true;
          lastSyncAt = null;
          offset = 0;
          continue;
        }
        rethrow;
      }
    }
  }
}
