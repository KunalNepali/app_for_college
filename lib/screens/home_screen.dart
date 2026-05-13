import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/category.dart';
import '../providers/app_providers.dart';
import 'sections_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, this.syncWarningMessage});

  final String? syncWarningMessage;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _didShowSyncWarning = false;

  Future<void> _refresh(WidgetRef ref) async {
    try {
      await ref.read(syncServiceProvider).syncAll();
    } finally {
      ref.invalidate(categoriesProvider);
      await ref.read(categoriesProvider.future);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);

    if (!_didShowSyncWarning && widget.syncWarningMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final messenger = ScaffoldMessenger.maybeOf(context);
        if (messenger == null) return;
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(widget.syncWarningMessage!)),
          );
      });
      _didShowSyncWarning = true;
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
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Failed to load categories: $error',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.redAccent),
            ),
          ),
        ),
        data: (categories) {
          if (categories.isEmpty) {
            return Center(
              child: Text(
                'No categories found.',
                style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => _refresh(ref),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.9,
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
                          builder: (context) => SectionsScreen(category: category),
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
  const _CategoryCard({required this.category, required this.onTap});

  final Category category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
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
              if ((category.description ?? '').isNotEmpty) ...[
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
    );
  }
}
