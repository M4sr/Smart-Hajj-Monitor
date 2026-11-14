import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../services/api_service.dart';
import '../../utils/constants.dart';
import '../../utils/dynamic_island.dart';
import 'detail_jemaah_screen.dart';

class DirectoryJemaahScreen extends StatefulWidget {
  const DirectoryJemaahScreen({super.key});

  @override
  State<DirectoryJemaahScreen> createState() => _DirectoryJemaahScreenState();
}

class _DirectoryJemaahScreenState extends State<DirectoryJemaahScreen> {
  bool _isLoading = true;
  List<dynamic> _jemaahList = [];
  List<dynamic> _filteredList = [];
  final TextEditingController _searchController = TextEditingController();
  String _selectedGender = 'Semua';

  @override
  void initState() {
    super.initState();
    _fetchJemaahList();
    _searchController.addListener(_filterJemaah);
  }

  Future<void> _fetchJemaahList() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.dio.get('/users/jemaah');
      if (response.statusCode == 200) {
        setState(() {
          _jemaahList = response.data;
          _filteredList = _jemaahList;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        DynamicIsland.show(context, message: 'Gagal mengambil data Jemaah', type: IslandType.error);
      }
    }
  }

  void _filterJemaah() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredList = _jemaahList.where((jemaah) {
        // Filter by gender
        bool matchGender = _selectedGender == 'Semua' || jemaah['jenis_kelamin'] == _selectedGender;
        
        // Filter by query
        final nama = jemaah['nama'].toString().toLowerCase();
        final username = jemaah['username'].toString().toLowerCase();
        bool matchQuery = query.isEmpty || nama.contains(query) || username.contains(query);

        return matchGender && matchQuery;
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A5F),
        elevation: 0,
        title: Text(
          'Direktori Jemaah',
          style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchJemaahList,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar Area
          Container(
            color: const Color(0xFF1E3A5F),
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppConstants.premiumShadow,
              ),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.plusJakartaSans(color: AppConstants.textDark),
                decoration: InputDecoration(
                  hintText: 'Cari nama atau username...',
                  hintStyle: GoogleFonts.plusJakartaSans(color: AppConstants.textLight),
                  prefixIcon: const Icon(Icons.search, color: AppConstants.petugasPrimary),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: AppConstants.textLight),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                ),
              ),
            ),
          ),
          
          // Filter Chips Area
          Container(
            width: double.infinity,
            color: const Color(0xFF1E3A5F),
            padding: const EdgeInsets.only(bottom: 24),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: ['Semua', 'Laki-laki', 'Perempuan'].map((gender) {
                  final isSelected = _selectedGender == gender;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedGender = gender);
                        _filterJemaah();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isSelected ? Colors.white : Colors.white.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            if (gender != 'Semua')
                              Icon(
                                gender == 'Laki-laki' ? Icons.male : Icons.female,
                                size: 16,
                                color: isSelected ? const Color(0xFF1E3A5F) : Colors.white70,
                              ),
                            if (gender != 'Semua') const SizedBox(width: 6),
                            Text(
                              gender,
                              style: GoogleFonts.plusJakartaSans(
                                color: isSelected ? const Color(0xFF1E3A5F) : Colors.white,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Result Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Jemaah',
                  style: GoogleFonts.plusJakartaSans(color: AppConstants.textLight, fontWeight: FontWeight.w600),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: AppConstants.petugasPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Text(
                    '${_filteredList.length}',
                    style: GoogleFonts.plusJakartaSans(color: AppConstants.petugasPrimary, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          
          // List View
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppConstants.petugasPrimary))
                : _filteredList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_off_outlined, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text('Tidak ada jemaah ditemukan', style: GoogleFonts.plusJakartaSans(color: AppConstants.textLight)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
                        itemCount: _filteredList.length,
                        itemBuilder: (context, index) {
                          final jemaah = _filteredList[index];
                          return _buildJemaahCard(jemaah, index);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildJemaahCard(Map<String, dynamic> jemaah, int index) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DetailJemaahScreen(jemaah: jemaah)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppConstants.premiumShadow,
          border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.white12 : const Color(0xFFF0F4F8), width: 2),
        ),
      child: Row(
        children: [
          jemaah['foto_profil'] != null
              ? ClipOval(
                  child: Image.network(
                    '${AppConstants.baseUrl}/${jemaah['foto_profil']}',
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return CircleAvatar(
                        radius: 28,
                        backgroundColor: AppConstants.petugasPrimary.withOpacity(0.1),
                        child: Text(
                          jemaah['nama'].toString().isNotEmpty ? jemaah['nama'].toString()[0].toUpperCase() : '?',
                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 24, color: AppConstants.petugasPrimary),
                        ),
                      );
                    },
                  ),
                )
              : CircleAvatar(
                  radius: 28,
                  backgroundColor: AppConstants.petugasPrimary.withOpacity(0.1),
                  child: Text(
                    jemaah['nama'].toString().isNotEmpty ? jemaah['nama'].toString()[0].toUpperCase() : '?',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 24, color: AppConstants.petugasPrimary),
                  ),
                ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  jemaah['nama'],
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16, color: AppConstants.textDark),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '@${jemaah['username']}',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppConstants.petugasPrimary, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.cake_outlined, size: 14, color: AppConstants.textLight),
                    const SizedBox(width: 4),
                    Text('${jemaah['usia'] ?? '-'} Thn', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppConstants.textLight)),
                    const SizedBox(width: 12),
                    Icon(Icons.male_outlined, size: 14, color: AppConstants.textLight),
                    const SizedBox(width: 4),
                    Text(jemaah['jenis_kelamin'] ?? 'Belum diatur', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppConstants.textLight)),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppConstants.petugasPrimary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppConstants.petugasPrimary),
          ),
        ],
      ),
    )).animate().fade().slideX(begin: 0.1);
  }
}
