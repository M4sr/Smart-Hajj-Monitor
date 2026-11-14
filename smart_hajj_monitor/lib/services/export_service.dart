import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/assessment_history.dart';

class ExportService {
  static Future<Uint8List> generatePdfData(List<AssessmentHistory> histories, PdfPageFormat format) async {
    try {
      final font = await PdfGoogleFonts.openSansRegular();
      final fontBold = await PdfGoogleFonts.openSansBold();

      final pdf = pw.Document(
        theme: pw.ThemeData.withFont(
          base: font,
          bold: fontBold,
        ),
      );

      final dateStr = DateFormat('dd MMM yyyy HH:mm').format(DateTime.now());

      int tinggi = 0, sedang = 0, rendah = 0;
      double totalSuhu = 0;
      for (var h in histories) {
        if (h.tingkatRisiko == 'Tinggi') tinggi++;
        else if (h.tingkatRisiko == 'Sedang') sedang++;
        else rendah++;
        totalSuhu += h.suhuTubuh;
      }
      String avgSuhu = histories.isEmpty ? '0.0' : (totalSuhu / histories.length).toStringAsFixed(1);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: format,
          margin: const pw.EdgeInsets.all(32),
          footer: (pw.Context context) {
            return pw.Container(
              alignment: pw.Alignment.centerRight,
              margin: const pw.EdgeInsets.only(top: 10),
              child: pw.Text('Halaman ${context.pageNumber} dari ${context.pagesCount} | Dicetak oleh Smart Hajj Monitor', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500)),
            );
          },
          build: (pw.Context context) {
            return [
              // KOP SURAT RESMI
              pw.Container(
                padding: const pw.EdgeInsets.only(bottom: 15),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(width: 3, color: PdfColors.black),
                  ),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Text('KEMENTERIAN KESEHATAN REPUBLIK INDONESIA', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                          pw.Text('PUSAT KESEHATAN HAJI NASIONAL', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.teal800)),
                          pw.SizedBox(height: 2),
                          pw.Text('Sistem Pemantauan Cerdas Jemaah Haji (Smart Hajj Monitor)', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800)),
                          pw.Text('Makkah Al-Mukarramah, Arab Saudi', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              pw.Container(
                margin: const pw.EdgeInsets.only(top: 2),
                height: 1,
                color: PdfColors.black,
              ),
              pw.SizedBox(height: 24),
              
              // JUDUL LAPORAN
              pw.Center(
                child: pw.Text('REKAPITULASI HASIL PEMERIKSAAN RUTIN JEMAAH', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline)),
              ),
              pw.SizedBox(height: 6),
              pw.Center(
                child: pw.Text('Waktu Unduh: $dateStr', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
              ),
              pw.SizedBox(height: 24),
              
              // RINGKASAN EKSEKUTIF (DASHBOARD STYLE)
              pw.Container(
                decoration: pw.BoxDecoration(
                  color: PdfColors.blueGrey50,
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: PdfColors.blueGrey200),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.teal800,
                        borderRadius: pw.BorderRadius.only(topLeft: pw.Radius.circular(7), topRight: pw.Radius.circular(7)),
                      ),
                      child: pw.Text('RINGKASAN EKSEKUTIF KONDISI KLOTER', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                        children: [
                          _buildPdfSummaryItem('Total Jemaah', '${histories.length}', PdfColors.teal900),
                          _buildPdfSummaryItem('Risiko Tinggi', '$tinggi', PdfColors.red700),
                          _buildPdfSummaryItem('Risiko Sedang', '$sedang', PdfColors.orange700),
                          _buildPdfSummaryItem('Risiko Rendah', '$rendah', PdfColors.green700),
                          _buildPdfSummaryItem('Rata-rata Suhu', '${avgSuhu} °C', PdfColors.blueGrey800),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 30),
              
              pw.Text('Rincian Data Medis Jemaah:', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
              pw.SizedBox(height: 8),

              pw.TableHelper.fromTextArray(
                headers: ['No', 'Nama Jemaah', 'Usia', 'L/P', 'Suhu', 'Risiko', 'Gejala', 'Waktu Lapor'],
                data: List.generate(histories.length, (index) {
                  final h = histories[index];
                  DateTime? date;
                  try {
                    date = DateTime.parse(h.tanggal);
                  } catch(e) {
                    date = DateTime.now();
                  }
                  final formattedDate = DateFormat('dd/MM HH:mm').format(date);
                  return [
                    '${index + 1}',
                    h.namaJemaah,
                    h.usia.toString(),
                    h.jenisKelamin.startsWith('L') ? 'L' : 'P',
                    '${h.suhuTubuh.toStringAsFixed(1)} °C',
                    h.tingkatRisiko,
                    h.gejala.isEmpty ? '-' : h.gejala,
                    formattedDate,
                  ];
                }),
                headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.teal800),
                cellStyle: const pw.TextStyle(fontSize: 9),
                rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
                cellAlignment: pw.Alignment.centerLeft,
                columnWidths: {
                  0: const pw.FlexColumnWidth(0.6),
                  1: const pw.FlexColumnWidth(2.5),
                  2: const pw.FlexColumnWidth(0.8),
                  3: const pw.FlexColumnWidth(0.8),
                  4: const pw.FlexColumnWidth(1.2),
                  5: const pw.FlexColumnWidth(1.2),
                  6: const pw.FlexColumnWidth(3.0),
                  7: const pw.FlexColumnWidth(1.5),
                },
              ),
              pw.SizedBox(height: 50),
              
              // Signature Area
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('Mengetahui,', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('Ketua Rombongan / Kloter', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 60),
                      pw.Text('_________________________', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                    ]
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text('Makkah, $dateStr', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('Tenaga Kesehatan Haji (TKH)', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 60),
                      pw.Text('_________________________', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.Text('NIP. ....................', style: const pw.TextStyle(fontSize: 10)),
                    ]
                  ),
                ]
              )
            ];
          },
        ),
      );

      return await pdf.save();
    } catch (e) {
      final errorPdf = pw.Document();
      errorPdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Text('Gagal membuat PDF:\n$e', style: const pw.TextStyle(fontSize: 14)),
            );
          }
        )
      );
      return await errorPdf.save();
    }
  }

  static Future<void> exportToCsv(List<AssessmentHistory> histories, BuildContext context) async {
    List<List<dynamic>> rows = [];
    
    // Header
    rows.add([
      "No",
      "Nama Jemaah",
      "Usia",
      "Jenis Kelamin",
      "Suhu Tubuh (C)",
      "Gejala",
      "Kondisi",
      "Batuk",
      "Sesak Napas",
      "Penyakit Bawaan",
      "Tingkat Risiko",
      "Tanggal Lapor"
    ]);

    // Data
    for (int i = 0; i < histories.length; i++) {
      final h = histories[i];
      DateTime? date;
      try {
        date = DateTime.parse(h.tanggal);
      } catch(e) {
        date = DateTime.now();
      }
      final formattedDate = DateFormat('yyyy-MM-dd HH:mm').format(date);
      
      rows.add([
        i + 1,
        h.namaJemaah,
        h.usia,
        h.jenisKelamin,
        h.suhuTubuh,
        h.gejala,
        h.kondisi,
        h.batuk,
        h.sesakNapas,
        h.riwayatPenyakit,
        h.tingkatRisiko,
        formattedDate,
      ]);
    }

    String csvData = const ListToCsvConverter().convert(rows);

    final directory = await getTemporaryDirectory();
    final dateStr = '${DateTime.now().day.toString().padLeft(2, '0')}_${DateTime.now().month.toString().padLeft(2, '0')}_${DateTime.now().year}';
    final path = "${directory.path}/Laporan_Kesehatan_Jemaah_$dateStr.csv";
    final file = File(path);
    await file.writeAsString(csvData);

    final result = await Share.shareXFiles(
      [XFile(path, mimeType: 'text/csv')],
      text: 'Berikut adalah lampiran laporan kesehatan Jemaah (Format Excel/CSV).',
    );
    
    if (result.status == ShareResultStatus.success) {
      debugPrint("Berhasil membagikan file Excel");
    }
  }

  static pw.Widget _buildPdfSummaryItem(String label, String value, PdfColor color) {
    return pw.Column(
      children: [
        pw.Text(value, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: color)),
        pw.SizedBox(height: 4),
        pw.Text(label, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
      ],
    );
  }
}
