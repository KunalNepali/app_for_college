import 'package:supabase_flutter/supabase_flutter.dart';

class ProgressService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<void> saveSectionAttempt({
    required String sectionId,
    required int score,
    required int total,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      // Progress is for logged-in users only
      return;
    }

    final existing = await _client
        .from('user_section_progress')
        .select('attempt_count, best_score, best_total')
        .eq('user_id', user.id)
        .eq('section_id', sectionId)
        .maybeSingle();

    final prevAttemptCount = (existing?['attempt_count'] ?? 0) as int;
    final prevBestScore = (existing?['best_score'] ?? 0) as int;
    final prevBestTotal = (existing?['best_total'] ?? 0) as int;

    final isNewBest =
        (score > prevBestScore) ||
        (score == prevBestScore && total > prevBestTotal);

    await _client.from('user_section_progress').upsert({
      'user_id': user.id,
      'section_id': sectionId,
      'attempt_count': prevAttemptCount + 1,
      'last_score': score,
      'last_total': total,
      'best_score': isNewBest ? score : prevBestScore,
      'best_total': isNewBest ? total : prevBestTotal,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
}
