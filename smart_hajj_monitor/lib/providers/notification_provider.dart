import 'package:flutter/material.dart';
import '../services/api_service.dart';

class NotificationProvider with ChangeNotifier {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Map<String, dynamic>> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get unreadCount => _notifications.where((n) => !n['isRead']).length;

  Future<void> fetchNotifications() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.dio.get('/notifications');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        _notifications = data
            .map((n) => _parseNotification(Map<String, dynamic>.from(n)))
            .toList();
        _errorMessage = null;
      } else {
        _errorMessage = 'Gagal memuat notifikasi';
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan koneksi';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Map<String, dynamic> _parseNotification(Map<String, dynamic> raw) {
    final String pesan = raw['pesan'] ?? '';
    final String status = raw['status'] ?? 'Belum dibaca';
    final int id = raw['id_notifikasi'] ?? 0;
    final String tanggalStr = raw['tanggal'] ?? '';

    String title = 'Notifikasi';
    String message = pesan;

    if (pesan.contains(':')) {
      final parts = pesan.split(':');
      title = parts[0].trim();
      message = parts.sublist(1).join(':').trim();
    }

    // Determine type and icon based on title
    String type = 'info';
    IconData icon = Icons.notifications_outlined;

    final lowercaseTitle = title.toLowerCase();
    if (lowercaseTitle.contains('analisis') || lowercaseTitle.contains('kelelahan')) {
      type = 'warning';
      icon = Icons.health_and_safety_rounded;
    } else if (lowercaseTitle.contains('cuaca') || lowercaseTitle.contains('ekstrem') || lowercaseTitle.contains('panas')) {
      type = 'danger';
      icon = Icons.wb_sunny_rounded;
    } else if (lowercaseTitle.contains('obat') || lowercaseTitle.contains('medis') || lowercaseTitle.contains('hipertensi')) {
      type = 'info';
      icon = Icons.medication_rounded;
    } else if (lowercaseTitle.contains('selamat') || lowercaseTitle.contains('sukses') || lowercaseTitle.contains('daftar')) {
      type = 'success';
      icon = Icons.check_circle_rounded;
    }

    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      'isRead': status == 'Sudah dibaca',
      'icon': icon,
      'time': _formatTimeDifference(tanggalStr),
    };
  }

  String _formatTimeDifference(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 1) {
        return 'Baru saja';
      } else if (diff.inMinutes < 60) {
        return '${diff.inMinutes} menit yang lalu';
      } else if (diff.inHours < 24) {
        return '${diff.inHours} jam yang lalu';
      } else if (diff.inDays == 1) {
        return 'Kemarin';
      } else {
        return '${diff.inDays} hari yang lalu';
      }
    } catch (_) {
      return 'Beberapa saat yang lalu';
    }
  }

  Future<void> markAsRead(int id, int index) async {
    if (index < 0 || index >= _notifications.length) return;
    if (_notifications[index]['isRead']) return;

    _notifications[index]['isRead'] = true;
    notifyListeners();

    try {
      await ApiService.dio.put('/notifications/$id/read');
    } catch (_) {
      // Revert if API fails
      _notifications[index]['isRead'] = false;
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    if (_notifications.every((n) => n['isRead'])) return;

    // Simpan salinan status sebelumnya untuk rollback jika gagal
    final previousStatus = _notifications.map((n) => n['isRead'] as bool).toList();

    for (var n in _notifications) {
      n['isRead'] = true;
    }
    notifyListeners();

    try {
      await ApiService.dio.put('/notifications/read-all');
    } catch (_) {
      // Rollback jika gagal
      for (int i = 0; i < _notifications.length; i++) {
        _notifications[i]['isRead'] = previousStatus[i];
      }
      notifyListeners();
    }
  }
}
