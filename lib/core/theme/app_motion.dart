import 'package:flutter/material.dart';

/// Central motion tokens, timing curves, and accessibility-aware helpers
/// for Inka's premium fintech animation system.
class AppMotion {
  // ── Duration Tokens ──
  /// Quick snaps, button presses, micro-interactions (120ms)
  static const Duration micro = Duration(milliseconds: 120);

  /// Icon and filter state transitions (180ms)
  static const Duration iconTransition = Duration(milliseconds: 180);
  static const Duration iconState = Duration(milliseconds: 180);

  /// Standard state changes, toggles, icon transitions, border/color fades (200ms)
  static const Duration standard = Duration(milliseconds: 200);

  /// Navigation transitions, tab sliding indicator, sheet reveals (280ms)
  static const Duration navigation = Duration(milliseconds: 280);

  /// Modals, subtle emphasis, success checkmark reveals (450ms)
  static const Duration emphasis = Duration(milliseconds: 450);

  /// Financial number count-ups and rolling currency transitions (550ms)
  static const Duration numberTransition = Duration(milliseconds: 550);

  /// Stagger delay between sequential cards/elements (50ms)
  static const Duration staggerDelay = Duration(milliseconds: 50);

  // ── Curves ──
  /// Smooth natural deceleration for entering elements
  static const Curve entrance = Curves.easeOutCubic;

  /// Balanced acceleration/deceleration for state mutations
  static const Curve stateChange = Curves.easeInOutCubic;

  /// Subtle restrained spring for emphasis without bouncy cartoonishness
  static const Curve subtleSpring = Curves.easeOutBack;

  /// Smooth exponential curve for financial counting
  static const Curve numberCurve = Curves.easeOutCubic;

  // ── Accessibility Helpers ──
  /// Returns whether animations are disabled by system accessibility settings.
  static bool isReducedMotion(BuildContext context) {
    return MediaQuery.of(context).disableAnimations;
  }

  /// Returns [original] duration if motion is enabled, or [Duration.zero] if reduced.
  static Duration duration(BuildContext context, Duration original) {
    return isReducedMotion(context) ? Duration.zero : original;
  }
}

/// A lightweight, performance-focused staggered entrance widget that slides
/// in subtly and fades up without layout thrashing.
class StaggeredSlideFade extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration delay;
  final Offset offset;
  final Duration duration;

  const StaggeredSlideFade({
    super.key,
    required this.child,
    this.index = 0,
    this.delay = AppMotion.staggerDelay,
    this.offset = const Offset(0.0, 16.0),
    this.duration = const Duration(milliseconds: 320),
  });

  @override
  State<StaggeredSlideFade> createState() => _StaggeredSlideFadeState();
}

class _StaggeredSlideFadeState extends State<StaggeredSlideFade>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: AppMotion.entrance),
    );

    _slide = Tween<Offset>(
      begin: widget.offset,
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: AppMotion.entrance),
    );

    final totalDelay = widget.delay * widget.index;
    if (totalDelay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(totalDelay, () {
        if (!_disposed && mounted) {
          _controller.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (AppMotion.isReducedMotion(context)) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: Transform.translate(
            offset: _slide.value,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
