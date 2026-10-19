import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_motion.dart';

/// A premium, fintech-grade interactive button wrapper providing immediate
/// tactile scale feedback (1.0 → 0.96), optional loading spinners, success checkmarks,
/// and complete accessibility support for reduced motion.
class BouncingButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleFactor;
  final Duration duration;
  final bool enableHaptic;
  final BorderRadius? borderRadius;
  final bool isLoading;
  final bool isSuccess;
  final Color? loadingColor;

  const BouncingButton({
    super.key,
    required this.child,
    this.onTap,
    this.scaleFactor = 0.96,
    this.duration = AppMotion.micro,
    this.enableHaptic = true,
    this.borderRadius,
    this.isLoading = false,
    this.isSuccess = false,
    this.loadingColor,
  });

  @override
  State<BouncingButton> createState() => _BouncingButtonState();
}

class _BouncingButtonState extends State<BouncingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      reverseDuration: widget.duration,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleFactor,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: AppMotion.entrance,
        reverseCurve: AppMotion.subtleSpring,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap == null || widget.isLoading) return;
    if (widget.enableHaptic) {
      HapticFeedback.lightImpact();
    }
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onTap == null || widget.isLoading) return;
    _controller.reverse();
    widget.onTap?.call();
  }

  void _onTapCancel() {
    if (widget.onTap == null || widget.isLoading) return;
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = widget.onTap == null;
    final bool reducedMotion = AppMotion.isReducedMotion(context);

    Widget content = widget.child;

    if (widget.isLoading || widget.isSuccess) {
      content = AnimatedSwitcher(
        duration: AppMotion.standard,
        switchInCurve: AppMotion.entrance,
        switchOutCurve: AppMotion.stateChange,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(scale: animation, child: child),
          );
        },
        child: widget.isLoading
            ? Center(
                key: const ValueKey('loading'),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      widget.loadingColor ?? Colors.white,
                    ),
                  ),
                ),
              )
            : widget.isSuccess
                ? const Center(
                    key: ValueKey('success'),
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  )
                : widget.child,
      );
    }

    if (isDisabled) {
      return Opacity(
        opacity: 0.55,
        child: content,
      );
    }

    if (reducedMotion) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.isLoading ? null : widget.onTap,
          child: content,
        ),
      );
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: child,
            );
          },
          child: content,
        ),
      ),
    );
  }
}
