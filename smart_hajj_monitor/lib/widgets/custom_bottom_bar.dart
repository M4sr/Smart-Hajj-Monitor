import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vibration/vibration.dart';

class CustomBottomBarItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  CustomBottomBarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class CustomBottomBar extends StatefulWidget {
  final int currentIndex;
  final List<CustomBottomBarItem> items;
  final ValueChanged<int> onTap;
  final Color activeColor;
  final Color inactiveColor;

  const CustomBottomBar({
    super.key,
    required this.currentIndex,
    required this.items,
    required this.onTap,
    required this.activeColor,
    this.inactiveColor = const Color(0xFF9EA3AE),
  });

  @override
  State<CustomBottomBar> createState() => _CustomBottomBarState();
}

class _CustomBottomBarState extends State<CustomBottomBar>
    with TickerProviderStateMixin {
  // Sliding capsule
  late AnimationController _capsuleCtrl;
  late Animation<double> _capsuleAnim;
  int _fromIndex = 0;

  // Per-item pop animations
  late List<AnimationController> _popCtrl;
  late List<Animation<double>> _popScale;
  late List<Animation<double>> _popY;

  // Pulsing glow on active
  late AnimationController _glowCtrl;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _fromIndex = widget.currentIndex;

    _capsuleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 420));
    _capsuleAnim = CurvedAnimation(
        parent: _capsuleCtrl, curve: Curves.easeOutCubic);

    _popCtrl = List.generate(
      widget.items.length,
      (_) => AnimationController(
          vsync: this, duration: const Duration(milliseconds: 480)),
    );
    _popScale = _popCtrl
        .map((c) => TweenSequence([
              TweenSequenceItem(
                  tween: Tween(begin: 1.0, end: 1.35)
                      .chain(CurveTween(curve: Curves.easeOut)),
                  weight: 40),
              TweenSequenceItem(
                  tween: Tween(begin: 1.35, end: 1.0)
                      .chain(CurveTween(curve: Curves.elasticOut)),
                  weight: 60),
            ]).animate(c))
        .toList();
    _popY = _popCtrl
        .map((c) => TweenSequence([
              TweenSequenceItem(
                  tween: Tween(begin: 0.0, end: -10.0)
                      .chain(CurveTween(curve: Curves.easeOut)),
                  weight: 40),
              TweenSequenceItem(
                  tween: Tween(begin: -10.0, end: 0.0)
                      .chain(CurveTween(curve: Curves.elasticOut)),
                  weight: 60),
            ]).animate(c))
        .toList();

    _glowCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400));
    _glowAnim = Tween<double>(begin: 0.15, end: 0.5).animate(
        CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));

    _popCtrl[widget.currentIndex].forward();
    _glowCtrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(CustomBottomBar old) {
    super.didUpdateWidget(old);
    if (old.currentIndex != widget.currentIndex) {
      _fromIndex = old.currentIndex;
      _capsuleCtrl.forward(from: 0);
      _popCtrl[old.currentIndex].reset();
      _popCtrl[widget.currentIndex].forward(from: 0);
    }
  }

  @override
  void dispose() {
    _capsuleCtrl.dispose();
    for (final c in _popCtrl) c.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final n = widget.items.length;

    final List<Color> capsuleColors =
        widget.activeColor == const Color(0xFF0F4C3A)
            ? [const Color(0xFF11C164), const Color(0xFF0A7A3F)]
            : [const Color(0xFF5BA6F5), const Color(0xFF1B4FC4)];

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.only(bottom: 22, left: 16, right: 16),
        width: (widget.items.length * 62.0 + 20.0),
        height: 72,
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF16161A).withValues(alpha: 0.94)
              : Colors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.07)
                : Colors.black.withValues(alpha: 0.06),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.10),
              blurRadius: 36,
              spreadRadius: -6,
              offset: const Offset(0, 16),
            ),
            BoxShadow(
              color: widget.activeColor.withValues(alpha: 0.07),
              blurRadius: 24,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
            child: LayoutBuilder(builder: (context, constraints) {
              final totalWidth = constraints.maxWidth;
              final itemWidth = totalWidth / n;

              return Stack(
                alignment: Alignment.center,
                children: [
                  // ── Sliding glowing capsule ──
                  AnimatedBuilder(
                    animation: Listenable.merge([_capsuleAnim, _glowAnim]),
                    builder: (_, __) {
                      final fromX = _fromIndex * itemWidth + itemWidth / 2;
                      final toX = widget.currentIndex * itemWidth + itemWidth / 2;
                      final cx = fromX + (toX - fromX) * _capsuleAnim.value;
                      const capsuleW = 52.0;
                      const capsuleH = 40.0;
                      // Pin capsule to icon area only (top of bar, not centered)
                      const capsuleTop = 8.0;

                      return Positioned(
                        left: cx - capsuleW / 2,
                        top: capsuleTop,
                        child: Container(
                          width: capsuleW,
                          height: capsuleH,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: capsuleColors,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: widget.activeColor
                                    .withValues(alpha: _glowAnim.value),
                                blurRadius: 20,
                                spreadRadius: 2,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  // ── Items row ──
                  Row(
                    children: [
                      for (int i = 0; i < n; i++)
                        _buildItem(context, i, isDark),
                    ],
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildItem(BuildContext context, int index, bool isDark) {
    final isActive = index == widget.currentIndex;
    final item = widget.items[index];

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (!isActive) {
            Vibration.vibrate(duration: 14);
            widget.onTap(index);
          }
        },
        child: AnimatedBuilder(
          animation: _popCtrl[index],
          builder: (_, __) {
            return Transform.translate(
              offset: Offset(0, _popY[index].value),
              child: Transform.scale(
                scale: _popScale[index].value,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon — aligned to capsule area (top)
                    SizedBox(
                      height: 40,
                      child: Center(
                        child: Icon(
                          isActive ? item.activeIcon : item.icon,
                          color: isActive
                              ? Colors.white
                              : widget.inactiveColor,
                          size: 22,
                        ),
                      ),
                    ),

                    // Label — below capsule, NOT inside it
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 220),
                        opacity: isActive ? 1.0 : 0.0,
                        child: isActive
                            ? Text(
                                item.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: widget.activeColor,
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
