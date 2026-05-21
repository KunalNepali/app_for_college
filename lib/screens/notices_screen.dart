import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:quiz_app_supabase/models/notice.dart';
import 'package:quiz_app_supabase/screens/pdf_network_viewer_screen.dart';
import 'package:quiz_app_supabase/services/supabase_service.dart';

class NoticesScreen extends StatefulWidget {
  final String noticeType; // 'exam' or 'vacancy'
  final String title;

  const NoticesScreen({
    super.key,
    required this.noticeType,
    required this.title,
  });

  @override
  State<NoticesScreen> createState() => _NoticesScreenState();
}

class _NoticesScreenState extends State<NoticesScreen> {
  final SupabaseService _supabaseService = SupabaseService();

  List<Notice> _notices = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final items = await _supabaseService.getNoticesByType(widget.noticeType);

      setState(() {
        _notices = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('yyyy-MM-dd');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text('Failed to load: $_error'))
          : _notices.isEmpty
          ? const Center(child: Text('No notices available'))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _notices.length,
                itemBuilder: (context, index) {
                  final n = _notices[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const Icon(
                        Icons.picture_as_pdf,
                        color: Colors.redAccent,
                      ),
                      title: Text(
                        n.title,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        df.format(n.noticeDate),
                        style: GoogleFonts.poppins(),
                      ),
                      onTap: () {
                        if (n.pdfUrl == null || n.pdfUrl!.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No PDF available')),
                          );
                          return;
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PdfNetworkViewerScreen(
                              title: n.title,
                              url: n.pdfUrl!,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
    );
  }
}
