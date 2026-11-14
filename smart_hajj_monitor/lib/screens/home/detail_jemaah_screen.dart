import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../models/assessment_history.dart';
import '../../providers/assessment_provider.dart';
import '../../utils/constants.dart';
import 'medical_record_screen.dart';

class DetailJemaahScreen extends StatefulWidget {
  final Map<String, dynamic> jemaah;

  const DetailJemaahScreen({super.key, required this.jemaah});

  @override
  State<DetailJemaahScreen> createState() => _DetailJemaahScreenState();
}

class _DetailJemaahScreenState extends State<DetailJemaahScreen> {
  bool _isLoading = true;
  List<AssessmentHistory> _assessments = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final provider = Provider.of<AssessmentProvider>(context, listen: false);
    final idUser = widget.jemaah['id_user'] as int;
    final results = await provider.fetchJemaahAssessments(idUser);
    
    if (mounted) {
      setState(() {
        _assessments = results;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Profil Jemaah',
          style: GoogleFonts.plusJakartaSans(color: AppConstants.textDark, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        iconTheme: IconThemeData(color: AppConstants.textDark),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Theme.of(context).brightness == Brightness.dark ? Colors.white12 : Colors.grey.withOpacity(0.1), height: 1),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppConstants.petugasPrimary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- HEADER PROFIL ---
                  Center(
                    child: Column(
                      children: [
                        widget.jemaah['foto_profil'] != null
                            ? ClipOval(
                                child: Image.network(
                                  '${AppConstants.baseUrl}/${widget.jemaah['foto_profil']}',
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return CircleAvatar(
                                      radius: 50,
                                      backgroundColor: AppConstants.petugasPrimary.withOpacity(0.1),
                                      child: Text(
                                        widget.jemaah['nama'].toString().isNotEmpty ? widget.jemaah['nama'].toString()[0].toUpperCase() : '?',
                                        style: GoogleFonts.plusJakartaSans(fontSize: 40, fontWeight: FontWeight.bold, color: AppConstants.petugasPrimary),
                                      ),
                                    );
                                  },
                                ),
                              ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack)
                            : CircleAvatar(
                                radius: 50,
                                backgroundColor: AppConstants.petugasPrimary.withOpacity(0.1),
                                child: Text(
                                  widget.jemaah['nama'].toString().isNotEmpty ? widget.jemaah['nama'].toString()[0].toUpperCase() : '?',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 40, fontWeight: FontWeight.bold, color: AppConstants.petugasPrimary),
                                ),
                              ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                        const SizedBox(height: 16),
                        Text(
                          widget.jemaah['nama'],
                          style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.bold, color: AppConstants.textDark),
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(delay: 100.ms),
                        const SizedBox(height: 4),
                        Text(
                          '@${widget.jemaah['username']}',
                          style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppConstants.petugasPrimary, fontWeight: FontWeight.w600),
                        ).animate().fadeIn(delay: 200.ms),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // --- INFO DEMOGRAFIS ---
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: AppConstants.premiumShadow,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildInfoItem(Icons.cake_outlined, 'Usia', '${widget.jemaah['usia']} Tahun'),
                        Container(width: 1, height: 40, color: Colors.grey.withOpacity(0.2)),
                        _buildInfoItem(Icons.male_outlined, 'Kelamin', widget.jemaah['jenis_kelamin']),
                        Container(width: 1, height: 40, color: Colors.grey.withOpacity(0.2)),
                        _buildInfoItem(Icons.phone_outlined, 'No. HP', widget.jemaah['no_hp'] ?? '-'),
                      ],
                    ),
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),

                  const SizedBox(height: 32),

                  Text(
                    'Riwayat Pemeriksaan',
                    style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: AppConstants.textDark),
                  ).animate().fadeIn(delay: 400.ms),
                  
                  const SizedBox(height: 16),

                  // --- TIMELINE PEMERIKSAAN ---
                  if (_assessments.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          children: [
                            Icon(Icons.history_toggle_off, size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text('Belum ada riwayat pemeriksaan', style: GoogleFonts.plusJakartaSans(color: AppConstants.textLight)),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: 500.ms)
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _assessments.length,
                      itemBuilder: (context, index) {
                        final record = _assessments[index];
                        return _buildHistoryCard(record, index);
                      },
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppConstants.textLight),
        const SizedBox(height: 8),
        Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppConstants.textLight)),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: AppConstants.textDark)),
      ],
    );
  }

  Widget _buildHistoryCard(AssessmentHistory record, int index) {
    Color riskColor;
    switch (record.tingkatRisiko) {
      case 'Tinggi':
        riskColor = AppConstants.statusTinggi;
        break;
      case 'Sedang':
        riskColor = AppConstants.statusSedang;
        break;
      default:
        riskColor = AppConstants.statusRendah;
    }

    String formattedDate = record.tanggal;
    try {
      final dt = DateTime.parse(record.tanggal);
      formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(dt);
    } catch (_) {}

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MedicalRecordScreen(record: record)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppConstants.premiumShadow,
          border: Border.all(color: riskColor.withOpacity(0.2)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: riskColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(formattedDate, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppConstants.textLight, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Text(record.gejala, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: AppConstants.textDark), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text('${record.suhuTubuh}°C • Risiko ${record.tingkatRisiko}', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: riskColor, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppConstants.textLight),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: (400 + (100 * index)).ms).slideX(begin: 0.1);
  }
}
