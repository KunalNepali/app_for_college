import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quiz_app_supabase/models/notice.dart';
import 'package:quiz_app_supabase/screens/remote_pdf_viewer_screen.dart';
import 'package:quiz_app_supabase/services/supabase_service.dart';

class RemoteNoticesScreen extends StatefulWidget {
  final String title;
  final String type; // 'exam' or 'vacancy'

  const RemoteNoticesScreen({
    super.key,
    required this.title,
    required this.type,
  });

  @override
  State<RemoteNoticesScreen> createState() => _RemoteNoticesScreenState();
}

class _RemoteNoticesScreenState extends State<RemoteNoticesScreen> {
  final SupabaseService _supabaseService = SupabaseService();

  List<Notice> _items = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _fmtDate(DateTime d) {
    // simple yyyy-mm-dd (no extra dependency)
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  Future<void> _load() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final list = await _supabaseService.getNoticesByType(widget.type);

      setState(() {
        _items = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load notices: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
          : _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_errorMessage!),
              ),
            )
          : _items.isEmpty
          ? const Center(child: Text('No notices available'))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final n = _items[index];

                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                        _fmtDate(n.noticeDate),
                        style: GoogleFonts.poppins(),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        final url = n.pdfUrl;

                        if (url == null || url.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('PDF link not available'),
                            ),
                          );
                          return;
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RemotePdfViewerScreen(
                              title: n.title,
                              pdfUrl: url,
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
