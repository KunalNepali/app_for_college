import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quiz_app_supabase/screens/home_screen.dart';
import '../services/profile_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  int _totalAttempts() {
    var total = 0;
    for (final row in _sectionProgress) {
      total += (row['attempt_count'] ?? 0) as int;
    }
    return total;
  }

  double _bestOverallPct() {
    double best = 0.0;
    for (final row in _sectionProgress) {
      final bestScore = (row['best_score'] ?? 0) as int;
      final bestTotal = (row['best_total'] ?? 0) as int;
      if (bestTotal > 0) {
        final pct = bestScore / bestTotal;
        if (pct > best) best = pct;
      }
    }
    return best;
  }

  final SupabaseClient _client = Supabase.instance.client;
  final ProfileService _profileService = ProfileService();

  late final TabController _tabController;

  final _nameController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String? _error;

  String? _avatarUrl;

  List<Map<String, dynamic>> _sectionProgress = [];
  List<Map<String, dynamic>> _setProgress = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final user = _client.auth.currentUser;
      if (user == null) {
        setState(() {
          _loading = false;
        });
        return;
      }

      // Load profile
      final profile = await _profileService.fetchMyProfile();
      _nameController.text = (profile?['full_name'] ?? '').toString();
      _avatarUrl = profile?['avatar_url']?.toString();

      // Load progress
      final sectionRows = await _client
          .from('user_section_progress')
          .select(
            'section_id, attempt_count, last_score, last_total, best_score, best_total, updated_at, sections(name)',
          )
          .eq('user_id', user.id)
          .order('updated_at', ascending: false);

      final setRows = await _client
          .from('user_set_progress')
          .select(
            'section_id, batch_offset, batch_limit, attempt_count, last_score, last_total, best_score, best_total, updated_at, sections(name)',
          )
          .eq('user_id', user.id)
          .order('updated_at', ascending: false);

      setState(() {
        _sectionProgress = List<Map<String, dynamic>>.from(sectionRows as List);
        _setProgress = List<Map<String, dynamic>>.from(setRows as List);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  String _sectionName(Map<String, dynamic> row) {
    final s = row['sections'];
    if (s is Map && s['name'] != null) return s['name'].toString();
    return row['section_id'].toString();
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;

    if (!mounted) return;
    setState(() => _saving = true);

    try {
      final signedUrl = await _profileService.uploadAvatarAndGetSignedUrl(
        file: File(picked.path),
      );
      await _profileService.updateMyProfile(
        fullName: _nameController.text,
        avatarUrl: signedUrl,
      );

      setState(() {
        _avatarUrl = signedUrl;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Avatar updated')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update avatar: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    try {
      await _profileService.updateMyProfile(
        fullName: _nameController.text,
        // avatarUrl not passed => keep existing
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile saved')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _headerCard() {
    final user = _client.auth.currentUser;

    final sectionsAttempted = _sectionProgress.length;
    final totalAttempts = _totalAttempts();
    final bestPct = _bestOverallPct(); // 0..1

    Widget stat(String label, String value) {
      return Expanded(
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.white.withOpacity(0.85),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF5B2EFF), Color(0xFF7C4DFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: _saving ? null : _pickAvatar,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 34,
                        backgroundColor: Colors.white.withOpacity(0.25),
                        backgroundImage:
                            (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                            ? NetworkImage(_avatarUrl!)
                            : null,
                        child: (_avatarUrl == null || _avatarUrl!.isEmpty)
                            ? const Icon(
                                Icons.person,
                                size: 34,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.edit,
                          size: 14,
                          color: Colors.deepPurple.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _nameController.text.trim().isEmpty
                            ? 'Your Profile'
                            : _nameController.text.trim(),
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? '',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _saving ? null : _saveProfile,
                  icon: const Icon(Icons.save, color: Colors.white),
                  tooltip: 'Save',
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Name editor (white chip)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: TextField(
                controller: _nameController,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Enter your full name',
                  icon: Icon(Icons.badge_outlined),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Stats row
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  stat('Sections', '$sectionsAttempted'),
                  Container(width: 1, height: 30, color: Colors.white24),
                  stat('Attempts', '$totalAttempts'),
                  Container(width: 1, height: 30, color: Colors.white24),
                  stat('Best', '${(bestPct * 100).toStringAsFixed(0)}%'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionProgressList() {
    if (_sectionProgress.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'No progress yet. Complete a quiz set to see progress.',
          style: GoogleFonts.poppins(color: Colors.grey[700]),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _sectionProgress.length,
      itemBuilder: (context, i) {
        final row = _sectionProgress[i];
        final name = _sectionName(row);

        final bestScore = (row['best_score'] ?? 0) as int;
        final bestTotal = (row['best_total'] ?? 0) as int;
        final lastScore = (row['last_score'] ?? 0) as int;
        final lastTotal = (row['last_total'] ?? 0) as int;
        final attempts = (row['attempt_count'] ?? 0) as int;

        final bestPct = bestTotal == 0 ? 0.0 : bestScore / bestTotal;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: bestPct,
                    minHeight: 10,
                    backgroundColor: Colors.grey[200],
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Best: $bestScore/$bestTotal  •  Last: $lastScore/$lastTotal  •  Attempts: $attempts',
                  style: GoogleFonts.poppins(fontSize: 13),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _setProgressList() {
    if (_setProgress.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'No set progress yet.',
          style: GoogleFonts.poppins(color: Colors.grey[700]),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _setProgress.length,
      itemBuilder: (context, i) {
        final row = _setProgress[i];
        final name = _sectionName(row);

        final offset = (row['batch_offset'] ?? 0) as int;
        final limit = (row['batch_limit'] ?? 50) as int;

        final bestScore = (row['best_score'] ?? 0) as int;
        final bestTotal = (row['best_total'] ?? 0) as int;
        final attempts = (row['attempt_count'] ?? 0) as int;

        final setNumber = (offset ~/ limit) + 1;
        final bestPct = bestTotal == 0 ? 0.0 : bestScore / bestTotal;

        return Card(
          child: ListTile(
            title: Text(
              '$name — Set $setNumber (Q${offset + 1}-${offset + limit})',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: bestPct,
                      minHeight: 10,
                      backgroundColor: Colors.grey[200],
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Best: $bestScore/$bestTotal  •  Attempts: $attempts',
                    style: GoogleFonts.poppins(fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.home),
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
            );
          },
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAll),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _client.auth.signOut();
              if (!context.mounted) return;

              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: user == null
          ? Center(
              child: Text(
                'Not logged in',
                style: GoogleFonts.poppins(fontSize: 16),
              ),
            )
          : _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Failed to load profile: $_error'),
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: _headerCard(),
                ),
                Container(
                  color: Colors.deepPurple,
                  child: TabBar(
                    controller: _tabController,
                    labelStyle: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                    indicatorColor: Colors.white,
                    tabs: const [
                      Tab(text: 'Overview'),
                      Tab(text: 'Sets'),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [_sectionProgressList(), _setProgressList()],
                  ),
                ),
              ],
            ),
    );
  }
}
