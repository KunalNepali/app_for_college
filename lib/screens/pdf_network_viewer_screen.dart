import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfNetworkViewerScreen extends StatelessWidget {
  final String title;
  final String url;

  const PdfNetworkViewerScreen({
    super.key,
    required this.title,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SfPdfViewer.network(url),
    );
  }
}
