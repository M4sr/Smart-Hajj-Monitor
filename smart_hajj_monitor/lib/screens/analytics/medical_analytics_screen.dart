import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../../providers/assessment_provider.dart';
import '../../models/assessment_history.dart';
import '../../utils/constants.dart';
import '../../services/export_service.dart';
import 'pdf_preview_screen.dart';

class MedicalAnalyticsScreen extends StatefulWidget {
  const MedicalAnalyticsScreen({super.key});

  @override
  State<MedicalAnalyticsScreen> createState() => _MedicalAnalyticsScreenState();
}

class _MedicalAnalyticsScreenState extends State<MedicalAnalyticsScreen> {
  int touchedPieIndex = -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AssessmentProvider>().fetchAllAssessments();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 130.0,
                floating: true,
                pinned: true,
                stretch: true,
                backgroundColor: AppConstants.petugasPrimary,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [
                    StretchMode.zoomBackground,
                    StretchMode.blurBackground,
                  ],
                  titlePadding: const EdgeInsets.only(left: 24, bottom: 65),
                  title: Text(
                    'Pusat Analisis',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(color: AppConstants.petugasPrimary),
                      Positioned(
                        top: -50,
                        right: -20,
                        child: Icon(Icons.analytics_outlined, size: 150, color: Colors.white.withOpacity(0.05)),
                      ),
                    ],
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(56),
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: TabBar(
                      indicatorColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppConstants.petugasPrimary,
                      indicatorWeight: 3,
                      labelColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppConstants.petugasPrimary,
                      unselectedLabelColor: AppConstants.textLight,
                      labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                      tabs: const [
                        Tab(text: 'OVERVIEW'),
                        Tab(text: 'DEMOGRAFI'),
                        Tab(text: 'LAPORAN'),
                      ],
                    ),
                  ),
                ),
              ),
            ];
          },
          body: Consumer<AssessmentProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
                return const Center(child: CircularProgressIndicator(color: AppConstants.petugasPrimary));
              }

              final histories = provider.histories;
              if (histories.isEmpty) {
                return Center(
                  child: Text(
                    'Belum ada data jemaah',
                    style: GoogleFonts.plusJakartaSans(color: AppConstants.textLight),
                  ),
                );
              }

              return TabBarView(
                children: [
                  _buildOverviewTab(histories),
                  _buildDemografiTab(histories),
                  _buildLaporanTab(histories),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ==========================================
  // TAB 1: OVERVIEW
  // ==========================================
  Widget _buildOverviewTab(List<AssessmentHistory> histories) {
    int tinggi = 0, sedang = 0, rendah = 0;
    for (var h in histories) {
      if (h.tingkatRisiko == 'Tinggi') tinggi++;
      else if (h.tingkatRisiko == 'Sedang') sedang++;
      else rendah++;
    }
    int total = tinggi + sedang + rendah;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row Ringkasan Angka
          Row(
            children: [
              Expanded(child: _buildSummaryCard('Tinggi', tinggi, total, AppConstants.statusTinggi, Icons.emergency).animate().fade().slideY()),
              const SizedBox(width: 12),
              Expanded(child: _buildSummaryCard('Sedang', sedang, total, AppConstants.statusSedang, Icons.warning_amber_rounded).animate().fade(delay: 100.ms).slideY()),
              const SizedBox(width: 12),
              Expanded(child: _buildSummaryCard('Rendah', rendah, total, AppConstants.statusRendah, Icons.check_circle_outline).animate().fade(delay: 200.ms).slideY()),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Pie Chart
          _buildPieChartCard(tinggi, sedang, rendah, total).animate().fade(delay: 300.ms).slideY(),

          const SizedBox(height: 24),

          // Gejala Terbanyak
          _buildTopSymptomsCard(histories).animate().fade(delay: 400.ms).slideY(),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: DEMOGRAFI
  // ==========================================
  Widget _buildDemografiTab(List<AssessmentHistory> histories) {
    // Hitung Umur
    int lansia = 0; // > 60
    int dewasa = 0; // 40 - 60
    int muda = 0;   // < 40

    // Hitung Jenis Kelamin Risiko Tinggi
    int lTinggi = 0, pTinggi = 0;

    for (var h in histories) {
      if (h.usia > 60) lansia++;
      else if (h.usia >= 40) dewasa++;
      else muda++;

      if (h.tingkatRisiko == 'Tinggi') {
        if (h.jenisKelamin.toLowerCase().contains('perempuan')) {
          pTinggi++;
        } else {
          lTinggi++;
        }
      }
    }

    int totalUmur = lansia + dewasa + muda;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPremiumCard(
            title: 'Distribusi Kelompok Usia',
            icon: Icons.people_alt_outlined,
            child: Column(
              children: [
                _buildDemografiRow('Lansia (>60 thn)', lansia, totalUmur, Colors.deepOrange),
                const SizedBox(height: 16),
                _buildDemografiRow('Dewasa (40-60 thn)', dewasa, totalUmur, Colors.blue),
                const SizedBox(height: 16),
                _buildDemografiRow('Muda (<40 thn)', muda, totalUmur, Colors.green),
              ],
            ),
          ).animate().fade().slideX(),

          const SizedBox(height: 24),

          _buildPremiumCard(
            title: 'Risiko Tinggi Berdasarkan Gender',
            icon: Icons.transgender,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      children: [
                        const Icon(Icons.male, color: Colors.blue, size: 40),
                        const SizedBox(height: 8),
                        Text('$lTinggi Kasus', style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, color: AppConstants.textDark)),
                        Text('Laki-laki', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppConstants.textLight)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.pink.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      children: [
                        const Icon(Icons.female, color: Colors.pink, size: 40),
                        const SizedBox(height: 8),
                        Text('$pTinggi Kasus', style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, color: AppConstants.textDark)),
                        Text('Perempuan', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppConstants.textLight)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fade(delay: 200.ms).slideX(),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 3: LAPORAN (RAW DATA)
  // ==========================================
  Widget _buildRisikoBadge(String risiko) {
    Color color = AppConstants.statusRendah;
    if (risiko == 'Tinggi') color = AppConstants.statusTinggi;
    if (risiko == 'Sedang') color = AppConstants.statusSedang;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(risiko, style: GoogleFonts.plusJakartaSans(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppConstants.petugasPrimary.withOpacity(0.6)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppConstants.textLight, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppConstants.textDark)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPageButton({required IconData icon, required bool isEnabled, required VoidCallback onTap}) {
    return InkWell(
      onTap: isEnabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isEnabled ? AppConstants.petugasPrimary.withOpacity(0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 20, color: isEnabled ? AppConstants.petugasPrimary : Colors.grey.shade400),
      ),
    );
  }

  Widget _buildLaporanTab(List<AssessmentHistory> histories) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // FIXED HEADER
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Data Laporan', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: AppConstants.textDark)),
                    const SizedBox(height: 4),
                    Text('${histories.length} Kasus tercatat', style: GoogleFonts.plusJakartaSans(color: AppConstants.textLight, fontSize: 12)),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => PdfPreviewScreen(histories: histories)));
                },
                icon: const Icon(Icons.picture_as_pdf, color: Colors.white, size: 16),
                label: Text('PDF', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => ExportService.exportToCsv(histories, context),
                icon: const Icon(Icons.table_view_rounded, color: Colors.white, size: 16),
                label: Text('EXCEL', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
        
        // SCROLLABLE LIST
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
            physics: const BouncingScrollPhysics(),
            itemCount: histories.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final h = histories[index];
              DateTime? date;
              try { date = DateTime.parse(h.tanggal); } catch(e) { date = DateTime.now(); }
              
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: AppConstants.premiumShadow,
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    iconColor: AppConstants.petugasPrimary,
                    collapsedIconColor: Colors.grey,
                    title: Text(h.namaJemaah, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: AppConstants.textDark, fontSize: 15)),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Row(
                        children: [
                          Text('${h.usia} Thn • ${h.jenisKelamin}', style: GoogleFonts.plusJakartaSans(color: AppConstants.textLight, fontSize: 12)),
                          const SizedBox(width: 12),
                          _buildRisikoBadge(h.tingkatRisiko),
                        ],
                      ),
                    ),
                    children: [
                      const Divider(height: 1),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildDetailItem('Suhu Tubuh', '${h.suhuTubuh}°C', Icons.thermostat_rounded)),
                          Expanded(child: _buildDetailItem('Waktu Lapor', DateFormat('dd MMM, HH:mm').format(date), Icons.access_time_rounded)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildDetailItem('Gejala Utama', h.gejala.isEmpty ? 'Tidak ada keluhan' : h.gejala, Icons.sick_outlined),
                      const SizedBox(height: 12),
                      _buildDetailItem('Riwayat Penyakit', h.riwayatPenyakit.isEmpty ? 'Tidak ada riwayat' : h.riwayatPenyakit, Icons.medical_information_outlined),
                      const SizedBox(height: 16),
                      
                      // AI Recommendation Box
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppConstants.petugasPrimary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppConstants.petugasPrimary.withOpacity(0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.auto_awesome_rounded, size: 16, color: AppConstants.petugasPrimary),
                                const SizedBox(width: 8),
                                Text('Analisis & Rekomendasi AI', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: AppConstants.petugasPrimary)),
                                const Spacer(),
                                if (h.probabilitas > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: AppConstants.petugasPrimary, borderRadius: BorderRadius.circular(4)),
                                    child: Text('${(h.probabilitas * 100).toStringAsFixed(0)}% Akurasi', style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              h.rekomendasi.isEmpty ? 'Sistem AI tidak mendeteksi anomali yang memerlukan rekomendasi khusus saat ini.' : h.rekomendasi, 
                              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppConstants.textDark, height: 1.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fade(delay: (50 * (index % 10)).ms).slideX();
            },
          ),
        ),
      ],
    );
  }

  // ==========================================
  // WIDGETS BUILDER
  // ==========================================
  
  Widget _buildSummaryCard(String title, int count, int total, Color color, IconData icon) {
    double percentage = total == 0 ? 0 : (count / total);
    return Builder(
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppConstants.premiumShadow,
          ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(count.toString(), style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, color: AppConstants.textDark)),
          Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppConstants.textLight, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percentage,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            borderRadius: BorderRadius.circular(10),
            minHeight: 4,
          ),
        ],
      ),
        );
      }
    );
  }

  Widget _buildPieChartCard(int tinggi, int sedang, int rendah, int total) {
    return _buildPremiumCard(
      title: 'Distribusi Tingkat Risiko',
      icon: Icons.pie_chart_outline,
      child: Column(
        children: [
          SizedBox(
            height: 250,
            child: Stack(
              children: [
                PieChart(
                  swapAnimationDuration: const Duration(milliseconds: 800),
                  swapAnimationCurve: Curves.easeOutBack,
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions || pieTouchResponse == null || pieTouchResponse.touchedSection == null) {
                            touchedPieIndex = -1;
                            return;
                          }
                          touchedPieIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 4,
                    centerSpaceRadius: 70,
                    sections: [
                      PieChartSectionData(
                        color: AppConstants.statusTinggi,
                        value: tinggi.toDouble(),
                        title: '${total == 0 ? 0 : (tinggi/total*100).toStringAsFixed(0)}%',
                        radius: touchedPieIndex == 0 ? 55.0 : 45.0,
                        titleStyle: GoogleFonts.plusJakartaSans(fontSize: touchedPieIndex == 0 ? 14 : 12, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      PieChartSectionData(
                        color: AppConstants.statusSedang,
                        value: sedang.toDouble(),
                        title: '${total == 0 ? 0 : (sedang/total*100).toStringAsFixed(0)}%',
                        radius: touchedPieIndex == 1 ? 55.0 : 45.0,
                        titleStyle: GoogleFonts.plusJakartaSans(fontSize: touchedPieIndex == 1 ? 14 : 12, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      PieChartSectionData(
                        color: AppConstants.statusRendah,
                        value: rendah.toDouble(),
                        title: '${total == 0 ? 0 : (rendah/total*100).toStringAsFixed(0)}%',
                        radius: touchedPieIndex == 2 ? 55.0 : 45.0,
                        titleStyle: GoogleFonts.plusJakartaSans(fontSize: touchedPieIndex == 2 ? 14 : 12, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$total', style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.bold, color: AppConstants.textDark)),
                      Text('Total', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: AppConstants.textLight)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 12,
            children: [
              _buildLegend(AppConstants.statusTinggi, 'Tinggi'),
              _buildLegend(AppConstants.statusSedang, 'Sedang'),
              _buildLegend(AppConstants.statusRendah, 'Rendah'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopSymptomsCard(List<AssessmentHistory> histories) {
    Map<String, int> symptomCounts = {};
    for (var h in histories) {
      if (h.gejala.isNotEmpty && h.gejala != '-' && h.gejala != 'Tidak Ada') {
        List<String> gejalaList = h.gejala.split(RegExp(r',|;'));
        for (var g in gejalaList) {
          String cleanGejala = g.trim().toLowerCase();
          if (cleanGejala.isNotEmpty) {
            symptomCounts[cleanGejala] = (symptomCounts[cleanGejala] ?? 0) + 1;
          }
        }
      }
    }

    var sortedSymptoms = symptomCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    var top3 = sortedSymptoms.take(3).toList();

    return _buildPremiumCard(
      title: 'Top 3 Keluhan Jemaah',
      icon: Icons.sick_outlined,
      child: top3.isEmpty
          ? Text('Belum ada keluhan tercatat.', style: GoogleFonts.plusJakartaSans(color: AppConstants.textLight))
          : Column(
              children: top3.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: Text(entry.value.toString(), style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: Colors.orange)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _capitalize(entry.key),
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: AppConstants.textDark),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  // --- Helpers ---

  Widget _buildDemografiRow(String label, int count, int total, Color color) {
    double percent = total == 0 ? 0 : count / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: AppConstants.textDark)),
            Text('$count Orang', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: percent,
          backgroundColor: color.withOpacity(0.1),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildPremiumCard({required String title, required IconData icon, required Widget child}) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppConstants.premiumShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: isDark ? Colors.white70 : AppConstants.petugasPrimary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: AppConstants.textDark),
                    ),
                  ),
                ],
              ),
          const SizedBox(height: 24),
          child,
        ],
      ),
        );
      }
    );
  }

  Widget _buildLegend(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(text, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: AppConstants.textLight)),
      ],
    );
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
