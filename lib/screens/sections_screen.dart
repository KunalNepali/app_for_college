import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/category.dart';
import '../models/section.dart';
import '../providers/app_providers.dart';
import '../repositories/quiz_repository.dart';
import 'quiz_screen.dart';

class SectionsScreen extends ConsumerWidget {
  const SectionsScreen({super.key, required this.category});

  final Category category;

  Future<void> _openSection(
    BuildContext context,
    WidgetRef ref,
    Section section,
  ) async {
    final repository = ref.read(quizRepositoryProvider);

    try {
      await repository.startOrResumeAttempt(section.id);
      if (!context.mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => QuizScreen(section: section),
        ),
      );
      ref.invalidate(hasSectionAttemptProvider(section.id));
    } on NotEnoughQuestionsException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Not enough questions available offline for "${section.name}" (${e.availableCount}/50). Please sync and try again.',
          ),
        ),
      );
    }
  }

  Future<void> _restartSection(
    BuildContext context,
    WidgetRef ref,
    Section section,
  ) async {
    final repository = ref.read(quizRepositoryProvider);

    try {
      await repository.restartAttempt(section.id);
      ref.invalidate(hasSectionAttemptProvider(section.id));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Restarted "${section.name}" with a new random set of 50 questions.',
          ),
        ),
      );
    } on NotEnoughQuestionsException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Not enough questions available offline for "${section.name}" (${e.availableCount}/50).',
          ),
        ),
      );
    }
  }

  Future<void> _refresh(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(syncServiceProvider).syncAll();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sync skipped: $e')),
      );
    } finally {
      ref.invalidate(sectionsByCategoryProvider(category.id));
      await ref.read(sectionsByCategoryProvider(category.id).future);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sectionsAsync = ref.watch(sectionsByCategoryProvider(category.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          category.name,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: sectionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Failed to load sections: $error',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.redAccent),
            ),
          ),
        ),
        data: (sections) {
          if (sections.isEmpty) {
            return Center(
              child: Text(
                'No sections found.',
                style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => _refresh(context, ref),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sections.length,
              itemBuilder: (context, index) {
                final section = sections[index];
                final hasAttemptAsync = ref.watch(
                  hasSectionAttemptProvider(section.id),
                );
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: Colors.deepPurple,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      section.name,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'Tap to start or resume 50-question session',
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                    trailing: hasAttemptAsync.when(
                      data: (hasAttempt) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (hasAttempt)
                            IconButton(
                              tooltip: 'Restart section',
                              onPressed: () => _restartSection(
                                context,
                                ref,
                                section,
                              ),
                              icon: const Icon(Icons.refresh),
                            ),
                          Icon(
                            hasAttempt
                                ? Icons.play_circle_fill
                                : Icons.arrow_forward_ios,
                            size: 18,
                          ),
                        ],
                      ),
                      loading: () => const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      error: (_, __) => const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                      ),
                    ),
                    onTap: () => _openSection(context, ref, section),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
