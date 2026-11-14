import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../services/api_service.dart';
import '../../utils/dynamic_island.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> initialData;

  const EditProfileScreen({super.key, required this.initialData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _namaController;
  late TextEditingController _noHpController;
  
  late String _usia;
  late String _jenisKelamin;

  @override
  void initState() {
    super.initState();
    _namaController = TextEditingController(text: widget.initialData['nama']);
    _noHpController = TextEditingController(text: widget.initialData['no_hp'] ?? '');
    
    int initialUsia = widget.initialData['usia'] ?? 30;
    _usia = initialUsia.toString();
    
    _jenisKelamin = widget.initialData['jenis_kelamin'] ?? 'Laki-laki';
    if (!['Laki-laki', 'Perempuan'].contains(_jenisKelamin)) {
      _jenisKelamin = 'Laki-laki';
    }
  }

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isUploadingPhoto = false;

  @override
  void dispose() {
    _namaController.dispose();
    _noHpController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source, imageQuality: 70);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
        _uploadImage();
      }
    } catch (e) {
      DynamicIsland.show(context, message: 'Gagal memilih gambar', type: IslandType.error);
    }
  }

  Future<void> _uploadImage() async {
    if (_imageFile == null) return;
    
    setState(() => _isUploadingPhoto = true);
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(_imageFile!.path, filename: 'profile.jpg'),
      });

      final response = await ApiService.dio.post('/users/me/upload-photo', data: formData);
      
      if (response.statusCode == 200) {
        final fotoProfil = response.data['foto_profil'];
        final provider = Provider.of<AuthProvider>(context, listen: false);
        await provider.updateFotoProfil(fotoProfil);
        DynamicIsland.show(context, message: 'Foto profil berhasil diunggah', type: IslandType.success);
      }
    } on DioException catch (e) {
      String errorMessage = 'Gagal mengunggah foto';
      if (e.response != null && e.response?.data is Map) {
        errorMessage = e.response?.data['detail'] ?? errorMessage;
      } else if (e.response?.statusCode == 500) {
        errorMessage = 'Terjadi kesalahan di server backend (500)';
      }
      DynamicIsland.show(context, message: errorMessage, type: IslandType.error);
    } catch (e) {
      DynamicIsland.show(context, message: 'Terjadi kesalahan', type: IslandType.error);
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  void _showImagePickerModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Ubah Foto Profil',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppConstants.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pilih sumber foto untuk profil Anda',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: AppConstants.textLight,
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: _buildPickerOption(
                        icon: Icons.camera_alt_rounded,
                        label: 'Kamera',
                        color: AppConstants.petugasPrimary,
                        onTap: () {
                          Navigator.pop(context);
                          _pickImage(ImageSource.camera);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildPickerOption(
                        icon: Icons.photo_library_rounded,
                        label: 'Galeri',
                        color: Colors.blueAccent,
                        onTap: () {
                          Navigator.pop(context);
                          _pickImage(ImageSource.gallery);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildPickerOption({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: color.withOpacity(isDark ? 0.15 : 0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(isDark ? 0.3 : 0.1), width: 1.5),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                color: AppConstants.textDark,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ).animate().fade().scale(curve: Curves.easeOutBack, duration: 400.ms),
    );
  }

  void _doSave() async {
    if (_namaController.text.trim().isEmpty) {
      DynamicIsland.show(context, message: 'Nama tidak boleh kosong', type: IslandType.error);
      return;
    }

    final data = {
      "nama": _namaController.text.trim(),
      "usia": int.tryParse(_usia) ?? 30,
      "jenis_kelamin": _jenisKelamin,
      "no_hp": _noHpController.text.trim(),
    };

    final provider = Provider.of<AuthProvider>(context, listen: false);
    final success = await provider.updateProfile(data);

    if (mounted) {
      if (success) {
        DynamicIsland.show(context, message: 'Profil berhasil diperbarui!', type: IslandType.success);
        Navigator.pop(context, true); // return true to indicate success
      } else {
        DynamicIsland.show(context, message: 'Gagal memperbarui profil', type: IslandType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Edit Profil',
          style: GoogleFonts.plusJakartaSans(color: AppConstants.textDark, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        iconTheme: IconThemeData(color: AppConstants.textDark),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.withOpacity(0.1), height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: AppConstants.premiumShadow,
              ),
              child: Column(
                children: [
                  // --- AVATAR UPLOAD ---
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade800 : Colors.grey.shade200,
                          backgroundImage: _imageFile != null
                              ? FileImage(_imageFile!)
                              : (context.watch<AuthProvider>().user?.fotoProfil != null
                                  ? NetworkImage('${AppConstants.baseUrl}/${context.watch<AuthProvider>().user!.fotoProfil!}')
                                  : null) as ImageProvider?,
                          child: _imageFile == null && context.watch<AuthProvider>().user?.fotoProfil == null
                              ? Text(
                                  widget.initialData['nama'].toString().substring(0, 1).toUpperCase(),
                                  style: GoogleFonts.plusJakartaSans(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.grey.shade500),
                                )
                              : null,
                        ),
                        if (_isUploadingPhoto)
                          const Positioned.fill(
                            child: CircularProgressIndicator(color: AppConstants.petugasPrimary),
                          ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _isUploadingPhoto ? null : _showImagePickerModal,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: AppConstants.petugasPrimary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fade().slideY(begin: -0.2),
                  const SizedBox(height: 32),

                  _buildPremiumTextField(
                    label: 'Nama Lengkap',
                    controller: _namaController,
                    icon: Icons.person_outline,
                  ).animate().fade(delay: 100.ms).slideX(begin: 0.1),
                  
                  const SizedBox(height: 20),
                  
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildPremiumDropdown(
                          label: 'Usia',
                          value: _usia,
                          items: List.generate(70, (i) => (i + 17).toString()),
                          onChanged: (val) => setState(() => _usia = val!),
                          icon: Icons.cake_outlined,
                        ).animate().fade(delay: 200.ms).slideX(begin: 0.1),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 3,
                        child: _buildPremiumDropdown(
                          label: 'Kelamin',
                          value: _jenisKelamin,
                          items: const ['Laki-laki', 'Perempuan'],
                          onChanged: (val) => setState(() => _jenisKelamin = val!),
                          icon: Icons.male_outlined,
                        ).animate().fade(delay: 300.ms).slideX(begin: 0.1),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  _buildPremiumTextField(
                    label: 'Nomor HP',
                    controller: _noHpController,
                    icon: Icons.phone_outlined,
                    isNumber: true,
                  ).animate().fade(delay: 400.ms).slideX(begin: 0.1),
                  
                  const SizedBox(height: 40),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _doSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.petugasPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: isLoading
                          ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                          : Text(
                              'Simpan Perubahan',
                              style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                    ),
                  ).animate().fade(delay: 500.ms).scale(curve: Curves.easeOutBack),
                ],
              ),
            ).animate().slideY(begin: 0.1),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool isNumber = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(color: AppConstants.textDark, fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.white24 : const Color(0xFFE2E8F0), width: 1),
          ),
          child: TextField(
            controller: controller,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            style: GoogleFonts.plusJakartaSans(color: AppConstants.textDark, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: 'Masukkan $label',
              hintStyle: GoogleFonts.plusJakartaSans(color: AppConstants.textLight.withOpacity(0.5), fontSize: 14),
              prefixIcon: Icon(icon, color: AppConstants.textLight),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    required IconData icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Pastikan value ada di items
    if (!items.contains(value)) {
      value = items.first; // Fallback ke item pertama
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(color: AppConstants.textDark, fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.white24 : const Color(0xFFE2E8F0), width: 1),
          ),
          child: DropdownButtonFormField<String>(
            isExpanded: true,
            value: value,
            icon: Icon(Icons.keyboard_arrow_down, color: AppConstants.textLight),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: AppConstants.textLight),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: GoogleFonts.plusJakartaSans(color: AppConstants.textDark)))).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
