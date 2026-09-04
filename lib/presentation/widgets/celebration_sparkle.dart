import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CelebrationSparkle {
  static void show(
    BuildContext context, {
    Offset? targetPosition,
    String message = 'Payment Recorded! 🎉',
  }) {
    HapticFeedback.heavyImpact();

    final overlay = Overlay.of(context, rootOverlay: true);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (ctx) => _CelebrationParticleOverlay(
        targetPosition: targetPosition,
        message: message,
        onDismiss: () {
          if (entry.mounted) {
            entry.remove();
          }
        },
      ),
    );

    overlay.insert(entry);
  }
}

class _CelebrationParticleOverlay extends StatefulWidget {
  final Offset? targetPosition;
  final String message;
  final VoidCallback onDismiss;

  const _CelebrationParticleOverlay({
    this.targetPosition,
    required this.message,
    required this.onDismiss,
  });

  @override
  State<_CelebrationParticleOverlay> createState() =>
      _CelebrationParticleOverlayState();
}

class _CelebrationParticleOverlayState
    extends State<_CelebrationParticleOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Particle> _particles;
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _particles = List.generate(42, (_) => _createParticle());

    _controller.forward().then((_) {
      widget.onDismiss();
    });
  }

  _Particle _createParticle() {
    final colors = [
      const Color(0xFF10B981), // Emerald Green
      const Color(0xFF34D399), // Mint Green
      const Color(0xFFF59E0B), // Warm Gold
      const Color(0xFFFBBF24), // Amber
      const Color(0xFFFF5722), // Inka Orange
      const Color(0xFF065F46), // Deep Emerald
      const Color(0xFF6EE7B7), // Light Mint
      Colors.white,
    ];

    final angle = _random.nextDouble() * 2 * math.pi;
    final speed = 120.0 + _random.nextDouble() * 260.0;
    final size = 5.0 + _random.nextDouble() * 7.0;
    final isCircle = _random.nextBool();
    final rotationSpeed = (_random.nextDouble() - 0.5) * 8.0;

    return _Particle(
      color: colors[_random.nextInt(colors.length)],
      angle: angle,
      speed: speed,
      size: size,
      isCircle: isCircle,
      rotationSpeed: rotationSpeed,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final center = widget.targetPosition ?? Offset(size.width / 2, size.height * 0.45);

    return IgnorePointer(
      child: Material(
        color: Colors.transparent,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final t = _controller.value;
            final pillOpacity = (t < 0.2)
                ? (t / 0.2)
                : (t > 0.75 ? (1.0 - (t - 0.75) / 0.25).clamp(0.0, 1.0) : 1.0);
            final pillScale = (t < 0.2)
                ? 0.7 + (t / 0.2) * 0.3
                : 1.0;

            return Stack(
              children: [
                // ── Shimmering Particles ──
                CustomPaint(
                  size: size,
                  painter: _ParticlePainter(
                    particles: _particles,
                    progress: t,
                    origin: center,
                  ),
                ),

                // ── Floating Celebration Badge ──
                Positioned(
                  top: center.dy - 60 - (t * 24),
                  left: 20,
                  right: 20,
                  child: Center(
                    child: Opacity(
                      opacity: pillOpacity,
                      child: Transform.scale(
                        scale: pillScale,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: const Color(0xFF10B981).withValues(alpha: 0.6),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF10B981).withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 26,
                                height: 26,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                widget.message,
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Particle {
  final Color color;
  final double angle;
  final double speed;
  final double size;
  final bool isCircle;
  final double rotationSpeed;

  _Particle({
    required this.color,
    required this.angle,
    required this.speed,
    required this.size,
    required this.isCircle,
    required this.rotationSpeed,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final Offset origin;

  _ParticlePainter({
    required this.particles,
    required this.progress,
    required this.origin,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const gravity = 220.0;
    final easeProgress = Curves.easeOutCubic.transform(progress);
    final fadeOut = (1.0 - progress).clamp(0.0, 1.0);

    for (final p in particles) {
      final distance = p.speed * easeProgress;
      final dx = origin.dx + math.cos(p.angle) * distance;
      final dy = origin.dy +
          math.sin(p.angle) * distance +
          (0.5 * gravity * progress * progress);

      final paint = Paint()
        ..color = p.color.withValues(alpha: fadeOut)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(p.rotationSpeed * progress);

      if (p.isCircle) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        final rect = Rect.fromCenter(
          center: Offset.zero,
          width: p.size * 1.3,
          height: p.size * 0.7,
        );
        canvas.drawRect(rect, paint);
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
