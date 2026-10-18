import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/theme_helper.dart';

/// A production-ready, accessible, draggable swipe-to-confirm widget.
/// Designed for high-consequence operations like marking an invoice as paid or finalizing an order.
class SlideToConfirm extends StatefulWidget {
  final String label;
  final String completedLabel;
  final Future<void> Function() onConfirmed;
  final double height;
  final double? width;
  final Color? trackColor;
  final Color? progressColor;
  final Color? thumbColor;
  final IconData icon;
  final IconData completedIcon;
  final bool isCompleted;
  final bool isLoading;
  final BorderRadius? borderRadius;

  const SlideToConfirm({
    super.key,
    this.label = 'Slide to confirm',
    this.completedLabel = 'Confirmed',
    required this.onConfirmed,
    this.height = 54.0,
    this.width,
    this.trackColor,
    this.progressColor,
    this.thumbColor,
    this.icon = Icons.arrow_forward_rounded,
    this.completedIcon = Icons.check_rounded,
    this.isCompleted = false,
    this.isLoading = false,
    this.borderRadius,
  });

  @override
  State<SlideToConfirm> createState() => _SlideToConfirmState();
}

class _SlideToConfirmState extends State<SlideToConfirm>
    with SingleTickerProviderStateMixin {
  late AnimationController _resetController;
  late Animation<double> _dragAnimation;

  double _dragPosition = 0.0;
  bool _isThresholdReached = false;
  bool _isProcessing = false;
  bool _isLocalCompleted = false;

  final double _thumbPadding = 4.0;

  @override
  void initState() {
    super.initState();
    _isLocalCompleted = widget.isCompleted;
    _resetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );

    _dragAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(
      CurvedAnimation(parent: _resetController, curve: Curves.easeOutCubic),
    )..addListener(() {
        setState(() {
          _dragPosition = _dragAnimation.value;
        });
      });
  }

  @override
  void didUpdateWidget(SlideToConfirm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCompleted != oldWidget.isCompleted) {
      setState(() {
        _isLocalCompleted = widget.isCompleted;
      });
    }
  }

  @override
  void dispose() {
    _resetController.dispose();
    super.dispose();
  }

  double _getMaxDrag(double totalWidth, double thumbSize) {
    return (totalWidth - thumbSize - (_thumbPadding * 2)).clamp(0.0, double.infinity);
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details, double maxDrag) {
    if (_isProcessing || _isLocalCompleted || widget.isLoading) return;

    setState(() {
      _dragPosition = (_dragPosition + details.delta.dx).clamp(0.0, maxDrag);
      final progress = maxDrag > 0 ? _dragPosition / maxDrag : 0.0;

      if (progress >= 0.88 && !_isThresholdReached) {
        _isThresholdReached = true;
        HapticFeedback.mediumImpact();
      } else if (progress < 0.88 && _isThresholdReached) {
        _isThresholdReached = false;
      }
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details, double maxDrag) {
    if (_isProcessing || _isLocalCompleted || widget.isLoading) return;

    final progress = maxDrag > 0 ? _dragPosition / maxDrag : 0.0;
    if (progress >= 0.85) {
      _triggerConfirmation(maxDrag);
    } else {
      _snapBack();
    }
  }

  void _snapBack() {
    final disableAnimations = MediaQuery.of(context).disableAnimations;
    if (disableAnimations) {
      setState(() {
        _dragPosition = 0.0;
        _isThresholdReached = false;
      });
      return;
    }

    _dragAnimation = Tween<double>(
      begin: _dragPosition,
      end: 0.0,
    ).animate(
      CurvedAnimation(parent: _resetController, curve: Curves.easeOutCubic),
    );
    _resetController.forward(from: 0.0);
    _isThresholdReached = false;
  }

  Future<void> _triggerConfirmation(double maxDrag) async {
    if (_isProcessing || _isLocalCompleted) return;

    setState(() {
      _dragPosition = maxDrag;
      _isProcessing = true;
      _isThresholdReached = true;
    });

    HapticFeedback.heavyImpact();

    try {
      await widget.onConfirmed();
      if (mounted) {
        setState(() {
          _isLocalCompleted = true;
          _isProcessing = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        _snapBack();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius = widget.borderRadius ?? BorderRadius.circular(widget.height / 2);
    final thumbSize = widget.height - (_thumbPadding * 2);
    final effectiveTrackColor = widget.trackColor ?? (context.isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9));
    final effectiveProgressColor = widget.progressColor ?? const Color(0xFF10B981);

    return Semantics(
      button: true,
      enabled: !_isProcessing && !_isLocalCompleted && !widget.isLoading,
      label: widget.label,
      onTap: () {
        // Accessibility fallback: allows screen readers or assistive touch to execute the action
        final box = context.findRenderObject() as RenderBox?;
        final width = box?.size.width ?? 300.0;
        final maxDrag = _getMaxDrag(width, thumbSize);
        _triggerConfirmation(maxDrag);
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = widget.width ?? constraints.maxWidth;
          final maxDrag = _getMaxDrag(totalWidth, thumbSize);
          final progress = maxDrag > 0 ? (_dragPosition / maxDrag).clamp(0.0, 1.0) : 0.0;

          return Container(
            width: totalWidth,
            height: widget.height,
            decoration: BoxDecoration(
              color: effectiveTrackColor,
              borderRadius: effectiveBorderRadius,
              border: Border.all(
                color: _isThresholdReached
                    ? effectiveProgressColor.withValues(alpha: 0.5)
                    : context.cardBorder,
                width: 1.2,
              ),
            ),
            child: Stack(
              children: [
                // Animated progress fill background
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: _isLocalCompleted
                      ? totalWidth
                      : (_dragPosition + thumbSize + _thumbPadding),
                  child: ClipRRect(
                    borderRadius: effectiveBorderRadius,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 140),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            effectiveProgressColor.withValues(alpha: 0.15),
                            effectiveProgressColor.withValues(alpha: 0.35 + (progress * 0.4)),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                    ),
                  ),
                ),

                // Center hint label (fades out as thumb drags over it)
                Center(
                  child: Opacity(
                    opacity: _isLocalCompleted ? 1.0 : (1.0 - (progress * 1.4)).clamp(0.0, 1.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isLocalCompleted) ...[
                          Icon(widget.completedIcon, size: 18, color: effectiveProgressColor),
                          const SizedBox(width: 8),
                          Text(
                            widget.completedLabel,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w900,
                              color: effectiveProgressColor,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ] else ...[
                          Text(
                            widget.label,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: context.textSecondary,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: context.textSecondary.withValues(alpha: 0.6),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Draggable Thumb Handle
                if (!_isLocalCompleted)
                  Positioned(
                    left: _thumbPadding + _dragPosition,
                    top: _thumbPadding,
                    bottom: _thumbPadding,
                    width: thumbSize,
                    child: GestureDetector(
                      onHorizontalDragUpdate: (details) => _onHorizontalDragUpdate(details, maxDrag),
                      onHorizontalDragEnd: (details) => _onHorizontalDragEnd(details, maxDrag),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        decoration: BoxDecoration(
                          color: _isThresholdReached
                              ? effectiveProgressColor
                              : (widget.thumbColor ?? const Color(0xFF0F172A)),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.18),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: (widget.isLoading || _isProcessing)
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 180),
                                  transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                                  child: Icon(
                                    _isThresholdReached ? widget.completedIcon : widget.icon,
                                    key: ValueKey(_isThresholdReached),
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
