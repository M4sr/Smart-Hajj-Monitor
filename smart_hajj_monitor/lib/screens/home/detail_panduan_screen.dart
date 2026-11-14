import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:audioplayers/audioplayers.dart';

import '../../utils/constants.dart';
import '../../utils/dynamic_island.dart';

class DetailPanduanScreen extends StatefulWidget {
  final int currentIndex;
  final List<Map<String, dynamic>> items;

  const DetailPanduanScreen({
    super.key,
    required this.currentIndex,
    required this.items,
  });

  @override
  State<DetailPanduanScreen> createState() => _DetailPanduanScreenState();
}

class _DetailPanduanScreenState extends State<DetailPanduanScreen> with SingleTickerProviderStateMixin {
  bool _isPlaying = false;
  bool _isPlayingTranslation = false;
  double _audioProgress = 0.0;
  late AnimationController _pulseController;
  late ScrollController _scrollController;
  bool _showNextButton = false;

  late AudioPlayer _audioPlayer;
  Duration? _totalDuration;

  Map<String, dynamic> get currentData => widget.items[widget.currentIndex];

  String get title => currentData['title']!;
  String get arabic => currentData['arabic']!;
  String get latin => currentData['latin']!;
  String get translation => currentData['translation']!;
  String get explanation => currentData['explanation']!;
  List<String>? get steps => currentData['steps'] as List<String>?;

  bool get hasPrevious => widget.currentIndex > 0;
  Map<String, dynamic>? get previousData => hasPrevious ? widget.items[widget.currentIndex - 1] : null;

  bool get hasNext => widget.currentIndex < widget.items.length - 1;
  Map<String, dynamic>? get nextData => hasNext ? widget.items[widget.currentIndex + 1] : null;

  String get _arabicAudioUrl {
    final encodedText = Uri.encodeComponent(arabic);
    return '${AppConstants.baseUrl}/tts/audio.mp3?text=$encodedText&lang=ar';
  }

  String get _translationAudioUrl {
    final prefix = "Artinya: ";
    final encodedText = Uri.encodeComponent("$prefix$translation");
    return '${AppConstants.baseUrl}/tts/audio.mp3?text=$encodedText&lang=id';
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    _audioPlayer = AudioPlayer();

    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted && _isPlaying) {
        setState(() {
          final totalMs = _totalDuration?.inMilliseconds ?? 15000;
          _audioProgress = (position.inMilliseconds / totalMs).clamp(0.0, 1.0);
        });
      }
    });

    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() {
          _totalDuration = duration;
        });
      }
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        if (!_isPlayingTranslation) {
          // Finished playing Arabic text, start playing translation immediately
          setState(() {
            _isPlayingTranslation = true;
            _audioProgress = 0.0;
            _totalDuration = null; // reset to fetch new duration
          });
          _playTranslationAudio();
        } else {
          // Finished playing translation
          setState(() {
            _isPlaying = false;
            _isPlayingTranslation = false;
            _audioProgress = 0.0;
          });
          _pulseController.stop();
          DynamicIsland.show(context, message: 'Putaran doa & arti selesai', type: IslandType.success);
        }
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _pulseController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    // Show button bar when scrolling close to bottom
    if (currentScroll >= maxScroll - 60) {
      if (!_showNextButton && (hasNext || hasPrevious)) {
        setState(() {
          _showNextButton = true;
        });
      }
    } else if (currentScroll < maxScroll - 120) {
      if (_showNextButton) {
        setState(() {
          _showNextButton = false;
        });
      }
    }
  }

  void _togglePlay() {
    if (_isPlaying) {
      _pauseAudio();
    } else {
      _resumeOrPlayAudio();
    }
  }

  void _resumeOrPlayAudio() async {
    setState(() {
      _isPlaying = true;
    });
    _pulseController.repeat();

    try {
      if (_audioPlayer.state == PlayerState.paused) {
        await _audioPlayer.resume();
      } else {
        final url = _isPlayingTranslation ? _translationAudioUrl : _arabicAudioUrl;
        await _audioPlayer.play(UrlSource(url));
      }
    } catch (e) {
      debugPrint("Audio play error: $e");
      _pulseController.stop();
      setState(() {
        _isPlaying = false;
      });
      if (mounted) {
        DynamicIsland.show(context, message: 'Gagal memutar audio bimbingan', type: IslandType.error);
      }
    }
  }

  void _playTranslationAudio() async {
    try {
      await _audioPlayer.play(UrlSource(_translationAudioUrl));
    } catch (e) {
      debugPrint("Translation audio play error: $e");
      _pulseController.stop();
      setState(() {
        _isPlaying = false;
        _isPlayingTranslation = false;
      });
      if (mounted) {
        DynamicIsland.show(context, message: 'Gagal memutar arti doa', type: IslandType.error);
      }
    }
  }

  void _pauseAudio() async {
    try {
      await _audioPlayer.pause();
    } catch (e) {
      debugPrint("Audio pause error: $e");
    }
    _pulseController.stop();
    setState(() {
      _isPlaying = false;
    });
  }

  void _copyToClipboard() {
    final textToCopy = "$title\n\n$arabic\n\n$latin\n\nArtinya: $translation";
    Clipboard.setData(ClipboardData(text: textToCopy));
    DynamicIsland.show(
      context,
      message: '📋 Doa berhasil disalin ke clipboard!',
      type: IslandType.success,
    );
    HapticFeedback.mediumImpact();
  }

  void _navigateToNext() {
    HapticFeedback.mediumImpact();
    context.pushReplacement(
      '/panduan-detail',
      extra: {
        'index': widget.currentIndex + 1,
        'items': widget.items,
      },
    );
  }

  void _navigateToPrevious() {
    HapticFeedback.mediumImpact();
    context.pushReplacement(
      '/panduan-detail',
      extra: {
        'index': widget.currentIndex - 1,
        'items': widget.items,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFFF57F17),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFFA726), Color(0xFFE65100)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_all_rounded),
            onPressed: _copyToClipboard,
            tooltip: 'Salin Doa',
          ),
        ],
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Scrollable Content
          Positioned.fill(
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Info Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFFE65100).withOpacity(0.15) : const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : const Color(0xFFFFE0B2), width: 1.5),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, color: Color(0xFFE65100), size: 24),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            explanation,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFE65100),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fade().slideY(begin: 0.1),
                  
                  const SizedBox(height: 24),

                  // Arabic text card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: AppConstants.premiumShadow,
                      border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.white12 : Colors.grey.withOpacity(0.1), width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          arabic,
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.rtl,
                          style: GoogleFonts.scheherazadeNew(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppConstants.textDark,
                            height: 1.8,
                          ),
                        ),
                        const SizedBox(height: 28),
                        Divider(color: Colors.grey.withOpacity(0.15)),
                        const SizedBox(height: 24),
                        
                        // Latin / Transliteration
                        Text(
                          latin,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFE65100),
                            fontStyle: FontStyle.italic,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // Translation
                        Text(
                          'Artinya:',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppConstants.textLight,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          translation,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: AppConstants.textDark,
                            fontWeight: FontWeight.w500,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fade(delay: 150.ms).slideY(begin: 0.1),

                  const SizedBox(height: 24),

                  // Simulated Audio Player
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: AppConstants.premiumShadow,
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                if (_isPlaying)
                                  ScaleTransition(
                                    scale: Tween<double>(begin: 1.0, end: 1.4).animate(
                                      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
                                    ),
                                    child: Container(
                                      width: 52,
                                      height: 52,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0xFFFFA726).withOpacity(0.2),
                                      ),
                                    ),
                                  ),
                                GestureDetector(
                                  onTap: _togglePlay,
                                  child: Container(
                                    width: 52,
                                    height: 52,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [Color(0xFFFFA726), Color(0xFFE65100)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                    child: Icon(
                                      _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                      color: Colors.white,
                                      size: 30,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _isPlaying
                                        ? (_isPlayingTranslation ? 'Sedang Memutar Arti Doa (ID)' : 'Sedang Memutar Doa (AR)')
                                        : 'Putar Audio Doa & Arti',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppConstants.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: _audioProgress,
                                      minHeight: 6,
                                      backgroundColor: Colors.grey.withOpacity(0.15),
                                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF57F17)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ).animate().fade(delay: 300.ms).slideY(begin: 0.1),

                  // Steps if available
                  if (steps != null && steps!.isNotEmpty) ...[
                    const SizedBox(height: 32),
                    Text(
                      'Langkah-Langkah Pelaksanaan',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppConstants.textDark,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...List.generate(steps!.length, (index) {
                      final isDark = Theme.of(context).brightness == Brightness.dark;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: AppConstants.premiumShadow,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFFE65100).withOpacity(0.2) : const Color(0xFFFFF3E0),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${index + 1}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFE65100),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                steps![index],
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.5,
                                  color: AppConstants.textDark,
                                  fontWeight: FontWeight.w500,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fade(delay: (400 + index * 100).ms).slideX(begin: 0.1);
                    }),
                  ],
                  
                  // Bottom margin spacing so that text isn't blocked by the navigation bar
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),

          // Slide Up Navigation Bar
          if (hasNext || hasPrevious)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutBack,
              bottom: _showNextButton ? 24 : -100,
              left: 24,
              right: 24,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _showNextButton ? 1.0 : 0.0,
                child: Row(
                  children: [
                    if (hasPrevious)
                      _buildPreviousButton(),
                    if (hasPrevious && hasNext)
                      const SizedBox(width: 12),
                    if (hasNext)
                      _buildNextButton(),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPreviousButton() {
    final isFullWidth = !hasNext;
    return Expanded(
      flex: isFullWidth ? 2 : 1,
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : const Color(0xFFFFE0B2), width: 1.5),
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppConstants.premiumShadow,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: _navigateToPrevious,
            child: isFullWidth
                ? Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        left: 20,
                        child: const Icon(Icons.arrow_back_rounded, color: Color(0xFFE65100), size: 18)
                            .animate(onPlay: (controller) => controller.repeat(reverse: true))
                            .moveX(begin: 0, end: -4, duration: 800.ms, curve: Curves.easeInOut),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 48),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Sebelumnya',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppConstants.textLight,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              previousData!['title'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFE65100),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const Icon(Icons.arrow_back_rounded, color: Color(0xFFE65100), size: 18)
                            .animate(onPlay: (controller) => controller.repeat(reverse: true))
                            .moveX(begin: 0, end: -4, duration: 800.ms, curve: Curves.easeInOut),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Sebelumnya',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppConstants.textLight,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                previousData!['title'],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFE65100),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildNextButton() {
    final isFullWidth = !hasPrevious;
    return Expanded(
      flex: isFullWidth ? 2 : 1,
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFA726), Color(0xFFE65100)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE65100).withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.15 : 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: _navigateToNext,
            child: isFullWidth
                ? Stack(
                    alignment: Alignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 48),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Selanjutnya',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              nextData!['title'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        right: 20,
                        child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18)
                            .animate(onPlay: (controller) => controller.repeat(reverse: true))
                            .moveX(begin: 0, end: 4, duration: 800.ms, curve: Curves.easeInOut),
                      ),
                    ],
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Selanjutnya',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                nextData!['title'],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18)
                            .animate(onPlay: (controller) => controller.repeat(reverse: true))
                            .moveX(begin: 0, end: 4, duration: 800.ms, curve: Curves.easeInOut),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
