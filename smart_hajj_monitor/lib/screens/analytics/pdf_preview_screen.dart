import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/assessment_history.dart';
import '../../services/export_service.dart';
import '../../utils/constants.dart';

class PdfPreviewScreen extends StatelessWidget {
  final List<AssessmentHistory> histories;

  const PdfPreviewScreen({super.key, required this.histories});

  @override
  Widget build(BuildContext context) {
    final String dateStr = '${DateTime.now().day.toString().padLeft(2, '0')}_${DateTime.now().month.toString().padLeft(2, '0')}_${DateTime.now().year}';
    final String fileName = 'Laporan_Kesehatan_Jemaah_$dateStr.pdf';

    return Scaffold(
      backgroundColor: AppConstants.petugasBackground,
      appBar: AppBar(
        title: Text('Pratinjau Dokumen', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
        backgroundColor: AppConstants.petugasPrimary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          PdfPreview(
            build: (format) => ExportService.generatePdfData(histories, format),
            pdfFileName: fileName,
            initialPageFormat: PdfPageFormat.a4,
            canChangeOrientation: false,
            canChangePageFormat: false,
            canDebug: false,
            useActions: false, // Turn off the ugly default action bar!
            scrollViewDecoration: BoxDecoration(color: AppConstants.petugasBackground),
            pdfPreviewPageDecoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))],
            ),
          ),
          
          // Modern Floating Action Bar
          Positioned(
            bottom: 30,
            left: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: AppConstants.petugasPrimary,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(color: AppConstants.petugasPrimary.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))
                ]
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    icon: Icons.print_rounded, 
                    label: 'Cetak', 
                    onTap: () async {
                      await Printing.layoutPdf(
                        onLayout: (format) => ExportService.generatePdfData(histories, format),
                        name: fileName
                      );
                    }
                  ),
                  Container(width: 1, height: 24, color: Colors.white24),
                  _buildActionButton(
                    icon: Icons.share_rounded, 
                    label: 'Bagikan', 
                    onTap: () async {
                      await Printing.sharePdf(
                        bytes: await ExportService.generatePdfData(histories, PdfPageFormat.a4),
                        filename: fileName
                      );
                    }
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(label, style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
