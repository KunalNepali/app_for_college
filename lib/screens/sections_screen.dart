import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quiz_app_supabase/models/category.dart';
import 'package:quiz_app_supabase/models/section.dart';
import 'package:quiz_app_supabase/screens/pdf_viewer_screen.dart';
import 'package:quiz_app_supabase/screens/quiz_screen.dart';
import 'package:quiz_app_supabase/screens/quiz_sets_screen.dart';
import 'package:quiz_app_supabase/services/supabase_service.dart';
import 'package:quiz_app_supabase/screens/local_notices_screen.dart';
import 'package:quiz_app_supabase/services/supabase_service.dart';

class SectionsScreen extends StatefulWidget {
  final Category category;

  const SectionsScreen({super.key, required this.category});

  @override
  State<SectionsScreen> createState() => _SectionsScreenState();
}

const Map<String, String> _syllabusPdfBySectionName = {
  'Constable': 'assets/pdf/constable_syllabus.pdf',
  'ASI': 'assets/pdf/asi_syllabus.pdf',
  'Inspector': 'assets/pdf/inspector_syllabus.pdf',
  'Technical Constable': 'assets/pdf/technical-constable-syllabus.pdf',
  'Technical ASI': 'assets/pdf/technical-asi-syllabus.pdf',
  'Technical Inspector': 'assets/pdf/technical-inspector-syllabus.pdf',
  'Technical SI': 'assets/pdf/technical-si-syllabus.pdf',
};
const Map<String, String> _setQuestionsPdfBySectionName = {
  '2080 - Technical ASI Past Questions': 'assets/pdf/2080_tech_asi.pdf',
  '2081 - Technical ASI Past Questions': 'assets/pdf/2081_tech_asi.pdf',
  '2080 - Past Questions': 'assets/pdf/asi_2080.pdf',
};

class _SectionsScreenState extends State<SectionsScreen> {
  final SupabaseService _supabaseService = SupabaseService();

  List<Section> _sections = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSections();
  }

  Future<void> _loadSections() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final sections = await _supabaseService.getSectionsByCategory(
        widget.category.id,
      );

      setState(() {
        _sections = sections;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load sections: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.category.name,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
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
                      "Failed to load Sections",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        color: Colors.redAccent,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _loadSections,
                      icon: const Icon(Icons.refresh),
                      label: const Text("Retry"),
                    ),
                  ],
                ),
              ),
            )
          : _sections.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.view_list_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No sections available",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadSections,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _sections.length,
                itemBuilder: (context, index) {
                  final section = _sections[index];

                  final isSyllabus = widget.category.name == 'Syllabus';
                  final hasPdf =
                      isSyllabus &&
                      _syllabusPdfBySectionName.containsKey(section.name);

                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: Container(
                        height: 48,
                        width: 48,
                        decoration: BoxDecoration(
                          color: Colors.deepPurple,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.list_alt, color: Colors.white),
                      ),
                      title: Text(
                        section.name,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: hasPdf
                          ? const Icon(
                              Icons.picture_as_pdf,
                              color: Colors.redAccent,
                            )
                          : Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.grey[400],
                            ),
                      onTap: () async {
                        // 1) Syllabus -> open asset PDF
                        if (widget.category.name == 'Syllabus') {
                          final assetPath =
                              _syllabusPdfBySectionName[section.name];

                          if (assetPath == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'No PDF mapped for: ${section.name}',
                                ),
                              ),
                            );
                            return;
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PdfViewerScreen(
                                title: section.name,
                                assetPath: assetPath,
                              ),
                            ),
                          );
                          return;
                        }

                        // 2) Notice -> open list from JSON
                        if (widget.category.name == 'Notice') {
                          String? jsonPath;

                          if (section.name == 'Exam Notices') {
                            jsonPath = 'assets/data/notices_exam.json';
                          } else if (section.name == 'Vacancy Notices') {
                            jsonPath = 'assets/data/notices_vacancy.json';
                          }

                          if (jsonPath == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Unknown Notice section: ${section.name}',
                                ),
                              ),
                            );
                            return;
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LocalNoticesScreen(
                                title: section.name,
                                jsonAssetPath:
                                    jsonPath!, // safe because we checked jsonPath == null above
                              ),
                            ),
                          );
                          return;
                        }

                        // 3) Set Questions -> some sections open as PDFs
                        if (widget.category.name == 'Set Questions') {
                          final assetPath =
                              _setQuestionsPdfBySectionName[section.name];
                          if (assetPath != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PdfViewerScreen(
                                  title: section.name,
                                  assetPath: assetPath,
                                ),
                              ),
                            );
                            return;
                          }
                          // If not mapped to PDF, fall through to quiz batching logic below.
                        }

                        // 4) Default -> Quiz (batched if > 50 questions)
                        try {
                          final supabaseService = SupabaseService();
                          final count = await supabaseService
                              .getQuestionCountBySection(section.id);

                          if (!context.mounted) return;

                          if (count > 50) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => QuizSetsScreen(
                                  section: section,
                                  batchSize: 50,
                                ),
                              ),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => QuizScreen(section: section),
                              ),
                            );
                          }
                        } catch (e) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to open quiz: $e')),
                          );
                        }
                      },
                    ),
                  );
                },
              ),
            ),
    );
  }
}
