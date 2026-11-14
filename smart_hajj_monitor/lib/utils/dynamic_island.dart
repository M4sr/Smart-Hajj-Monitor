import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

enum IslandType { success, error, info }

class DynamicIsland {
  static OverlayEntry? _overlayEntry;

  static void show(BuildContext context, {required String message, IslandType type = IslandType.info}) {
    // Hilangkan overlay sebelumnya jika ada
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
    }

    _overlayEntry = _createOverlayEntry(context, message, type);
    Overlay.of(context).insert(_overlayEntry!);

    // Hilangkan otomatis setelah 3 detik
    Future.delayed(const Duration(seconds: 3), () {
      if (_overlayEntry != null) {
        _overlayEntry!.remove();
        _overlayEntry = null;
      }
    });
  }

  static OverlayEntry _createOverlayEntry(BuildContext context, String message, IslandType type) {
    IconData icon;
    Color iconColor;

    switch (type) {
      case IslandType.success:
        icon = Icons.check_circle;
        iconColor = Colors.greenAccent;
        break;
      case IslandType.error:
        icon = Icons.error;
        iconColor = Colors.redAccent;
        break;
      case IslandType.info:
      default:
        icon = Icons.info;
        iconColor = Colors.blueAccent;
        break;
    }

    return OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.85),
                borderRadius: BorderRadius.circular(40), // Bentuk pil ala Dynamic Island
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: iconColor, size: 24).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      message,
                      style: GoogleFonts.poppins(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ).animate().slideY(begin: -1, end: 0, duration: 400.ms, curve: Curves.easeOutCubic).fade(),
          ),
        ),
      ),
    );
  }
}
