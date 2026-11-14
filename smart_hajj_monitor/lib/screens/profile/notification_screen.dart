import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../utils/constants.dart';
import '../../utils/dynamic_island.dart';
import '../../providers/notification_provider.dart';
import '../../providers/auth_provider.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<NotificationProvider>().fetchNotifications();
      }
    });
  }

  Future<void> _fetchNotifications() async {
    await context.read<NotificationProvider>().fetchNotifications();
  }

  Future<void> _markAsRead(int id, int index) async {
    HapticFeedback.lightImpact();
    await context.read<NotificationProvider>().markAsRead(id, index);
  }

  Future<void> _markAllAsRead() async {
    HapticFeedback.mediumImpact();
    await context.read<NotificationProvider>().markAllAsRead();
    if (mounted) {
      DynamicIsland.show(context, message: 'Semua notifikasi ditandai dibaca', type: IslandType.success);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final isPetugas = user?.role.toLowerCase() == 'petugas';
    final primaryColor = isPetugas ? AppConstants.petugasPrimary : AppConstants.jemaahPrimary;
    final gradientColors = isPetugas 
        ? [const Color(0xFF1E3A5F), AppConstants.petugasPrimary] 
        : [const Color(0xFF0F9D58), AppConstants.jemaahPrimary];

    final notificationProvider = context.watch<NotificationProvider>();
    final notifications = notificationProvider.notifications;
    final isLoading = notificationProvider.isLoading;
    final errorMessage = notificationProvider.errorMessage;
    final hasUnread = notificationProvider.unreadCount > 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: RefreshIndicator(
        onRefresh: _fetchNotifications,
        color: primaryColor,
        backgroundColor: Colors.white,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            SliverAppBar(
              expandedHeight: 120.0,
              floating: false,
              pinned: true,
              backgroundColor: primaryColor,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white),
              actions: [
                if (!isLoading && errorMessage == null && hasUnread)
                  IconButton(
                    icon: const Icon(Icons.done_all_rounded, color: Colors.white),
                    onPressed: _markAllAsRead,
                    tooltip: 'Tandai semua dibaca',
                  ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'Notifikasi',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    letterSpacing: -0.5,
                  ),
                ),
                centerTitle: true,
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: gradientColors,
                        ),
                      ),
                    ),
                    Positioned(
                      right: -20,
                      top: -20,
                      child: Icon(
                        Icons.notifications_rounded,
                        size: 100,
                        color: Colors.white.withValues(alpha: 0.1),
                      ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 2.seconds),
                    ),
                  ],
                ),
              ),
            ),
            if (isLoading)
              SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: primaryColor),
                ),
              )
            else if (errorMessage != null)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cloud_off_rounded, color: Colors.redAccent, size: 64),
                        const SizedBox(height: 16),
                        Text(
                          errorMessage,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppConstants.textDark,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _fetchNotifications,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Coba Lagi'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (notifications.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_none_rounded,
                        size: 80,
                        color: Colors.grey.shade400,
                      ).animate(onPlay: (c) => c.repeat(reverse: true)).rotate(begin: -0.05, end: 0.05, duration: 1.seconds),
                      const SizedBox(height: 16),
                      Text(
                        'Belum ada notifikasi',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final notif = notifications[index];
                      final bool isRead = notif['isRead'];
                      
                      Color iconColor;
                      Color bgColor;
                      switch (notif['type']) {
                        case 'danger':
                          iconColor = Colors.red;
                          bgColor = Colors.red.withValues(alpha: 0.1);
                          break;
                        case 'warning':
                          iconColor = Colors.orange;
                          bgColor = Colors.orange.withValues(alpha: 0.1);
                          break;
                        case 'success':
                          iconColor = Colors.green;
                          bgColor = Colors.green.withValues(alpha: 0.1);
                          break;
                        default:
                          iconColor = Colors.blue;
                          bgColor = Colors.blue.withValues(alpha: 0.1);
                      }

                      return GestureDetector(
                        onTap: () => _markAsRead(notif['id'], index),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isRead ? Colors.white : Colors.blue.shade50.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: isRead ? Colors.transparent : Colors.blue.withValues(alpha: 0.2)),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: bgColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(notif['icon'], color: iconColor, size: 24),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            notif['title'],
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 16,
                                              fontWeight: isRead ? FontWeight.bold : FontWeight.w900,
                                              color: AppConstants.textDark,
                                            ),
                                          ),
                                        ),
                                        if (!isRead)
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                              color: Colors.redAccent,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      notif['message'],
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        color: AppConstants.textLight,
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      notif['time'],
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ).animate().fade(delay: (100 * index).ms).slideY(begin: 0.1);
                    },
                    childCount: notifications.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
