import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quiz_app_supabase/models/category.dart';
import 'package:quiz_app_supabase/screens/login_screen.dart';
import 'package:quiz_app_supabase/screens/profile_screen.dart';
import 'package:quiz_app_supabase/screens/sections_screen.dart';
import 'package:quiz_app_supabase/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  late final StreamSubscription<AuthState> _authSub;
  bool _showingCached = false;
  List<Category> _categories = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCategories();

    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      // When login/logout happens, refresh categories
      _loadCategories();
    });
  }

  @override
  void dispose() {
    _authSub.cancel();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _showingCached = false;
      });

      final res = await _supabaseService.getCategories();

      setState(() {
        _categories = res.categories;
        _showingCached = res.fromCache;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString(); // already includes "Failed to load..."
        _isLoading = false;
        _showingCached = false;
      });
    }
  }

  void _openProfile(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;

    if (session == null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Police Prep App',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => _openProfile(context),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Failed to load categories",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: Colors.redAccent,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _loadCategories,
                    icon: const Icon(Icons.refresh),
                    label: const Text("Retry"),
                  ),
                ],
              ),
            )
          : _categories.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.category_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No categories found",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                if (_showingCached)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'Offline mode: showing saved categories',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: Colors.orange,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadCategories,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.8,
                            ),
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final category = _categories[index];
                          return _CategoryCard(
                            category: category,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      SectionsScreen(category: category),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _CategoryVisual {
  final IconData icon;
  final Color color;
  final Color bg;

  const _CategoryVisual({
    required this.icon,
    required this.color,
    required this.bg,
  });
}

_CategoryVisual _visualForCategory(String name) {
  switch (name.trim()) {
    case 'General Knowledge':
      return _CategoryVisual(
        icon: Icons.public,
        color: Colors.deepPurple,
        bg: const Color(0xFFF1EAFE),
      );

    case 'English Language':
      return _CategoryVisual(
        icon: Icons.translate,
        color: Colors.indigo,
        bg: const Color(0xFFEEF0FF),
      );

    case 'Nepali Language':
      return _CategoryVisual(
        icon: Icons.language,
        color: Colors.redAccent,
        bg: const Color(0xFFFFEDEE),
      );

    case 'Reasoning':
      return _CategoryVisual(
        icon: Icons.psychology,
        color: Colors.green,
        bg: const Color(0xFFE9FBEA),
      );

    case 'Professional Knowledge':
      return _CategoryVisual(
        icon: Icons.school,
        color: Colors.blue,
        bg: const Color(0xFFE8F1FF),
      );

    case 'Professional Behavioral Test':
      return _CategoryVisual(
        icon: Icons.fact_check,
        color: Colors.teal,
        bg: const Color(0xFFE6FFFA),
      );

    case 'Gorkhapatra':
      return _CategoryVisual(
        icon: Icons.newspaper,
        color: Colors.brown,
        bg: const Color(0xFFF7EFE7),
      );

    case 'Notice':
      return _CategoryVisual(
        icon: Icons.campaign,
        color: Colors.orange,
        bg: const Color(0xFFFFF4E5),
      );

    case 'Set Questions':
      return _CategoryVisual(
        icon: Icons.assignment,
        color: Colors.blueGrey,
        bg: const Color(0xFFEEF2F6),
      );

    case 'Syllabus':
      return _CategoryVisual(
        icon: Icons.menu_book,
        color: Colors.deepPurple,
        bg: const Color(0xFFF1EAFE),
      );

    default:
      return _CategoryVisual(
        icon: Icons.category,
        color: Colors.grey,
        bg: const Color(0xFFF3F4F6),
      );
  }
}

class _CategoryCard extends StatelessWidget {
  final Category category;
  final VoidCallback onTap;

  const _CategoryCard({super.key, required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final v = _visualForCategory(category.name);

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
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: v.bg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(v.icon, size: 36, color: v.color),
                ),
                const SizedBox(height: 16),
                Text(
                  category.name,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: v.color,
                  ),
                ),
                if (category.description != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    category.description!,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
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
