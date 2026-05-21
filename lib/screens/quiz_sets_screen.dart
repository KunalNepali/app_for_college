import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quiz_app_supabase/models/section.dart';
import 'package:quiz_app_supabase/screens/quiz_screen.dart';
import 'package:quiz_app_supabase/services/supabase_service.dart';

class QuizSetsScreen extends StatefulWidget {
  final Section section;
  final int batchSize;

  const QuizSetsScreen({super.key, required this.section, this.batchSize = 50});

  @override
  State<QuizSetsScreen> createState() => _QuizSetsScreenState();
}

class _QuizSetsScreenState extends State<QuizSetsScreen> {
  final SupabaseService _service = SupabaseService();

  bool _loading = true;
  String? _error;
  int _count = 0;

  @override
  void initState() {
    super.initState();
    _loadCount();
  }

  Future<void> _loadCount() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final c = await _service.getQuestionCountBySection(widget.section.id);

      setState(() {
        _count = c;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final batchSize = widget.batchSize;
    final totalSets = (_count / batchSize).ceil();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.section.name,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Failed to load sets',
                    style: GoogleFonts.poppins(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(_error!, textAlign: TextAlign.center),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loadCount,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: totalSets,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final setNumber = index + 1;
                final start = index * batchSize + 1;
                final end = ((index + 1) * batchSize).clamp(1, _count);

                return Card(
                  child: ListTile(
                    title: Text(
                      'Set $setNumber',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'Questions $start - $end',
                      style: GoogleFonts.poppins(),
                    ),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QuizScreen(
                            section: widget.section,
                            batchOffset: index * batchSize,
                            batchLimit: batchSize,
                          ),
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
