import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/local_notice.dart';
import 'pdf_viewer_screen.dart';

class LocalNoticesScreen extends StatefulWidget {
  final String title;
  final String jsonAssetPath;

  const LocalNoticesScreen({
    super.key,
    required this.title,
    required this.jsonAssetPath,
  });

  @override
  State<LocalNoticesScreen> createState() => _LocalNoticesScreenState();
}

class _LocalNoticesScreenState extends State<LocalNoticesScreen> {
  List<LocalNotice> _items = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final raw = await rootBundle.loadString(widget.jsonAssetPath);
      final decoded = jsonDecode(raw);

      final list = (decoded as List)
          .map((e) => LocalNotice.fromJson(e as Map<String, dynamic>))
          .where((n) => n.title.isNotEmpty && n.assetPath.isNotEmpty)
          .toList();

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
                      subtitle: Text(n.date, style: GoogleFonts.poppins()),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PdfViewerScreen(
                              title: n.title,
                              assetPath: n.assetPath,
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
