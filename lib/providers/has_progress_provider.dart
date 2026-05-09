import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quiz_app_supabase/storage/quiz_progress_storage.dart';

final quizProgressStorageProvider = Provider<QuizProgressStorage>((ref) {
  return QuizProgressStorage();
});

final hasProgressProvider = FutureProvider.family<bool, String>((ref, quizId) {
  final storage = ref.read(quizProgressStorageProvider);
  return storage.hasProgress(quizId);
});
