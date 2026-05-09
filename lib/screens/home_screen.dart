import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quiz_app_supabase/models/category.dart';
import 'package:quiz_app_supabase/providers/local_data_providers.dart';
import 'package:quiz_app_supabase/screens/quizzes_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    Future<void> refresh() async {
      await ref.read(syncServiceProvider).syncFromSupabase();
      ref.invalidate(categoriesProvider);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Police Prep App',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
              const SizedBox(height: 16),
              Text(
                'Failed to load categories',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 18, color: Colors.redAccent),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  '$e',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(categoriesProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (categories) {
          if (categories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.category_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'No categories found',
                    style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: refresh,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.8,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return _CategoryCard(
                    category: category,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => QuizzesScreen(category: category),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final Category category;
  final VoidCallback onTap;

  const _CategoryCard({super.key, required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.category, size: 48, color: Colors.deepPurple),
                const SizedBox(height: 16),
                Text(
                  category.name,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.deepPurple,
                  ),
                ),
                if (category.description != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    category.description!,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
