import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Smoothly transitions numeric financial values (subtotal, tax, grand total)
/// with an animated rolling transition, preserving exact currency formatting.
class AnimatedCurrencyText extends StatefulWidget {
  final double value;
  final NumberFormat formatter;
  final TextStyle? style;
  final Duration duration;
  final Curve curve;

  const AnimatedCurrencyText({
    super.key,
    required this.value,
    required this.formatter,
    this.style,
    this.duration = const Duration(milliseconds: 260),
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<AnimatedCurrencyText> createState() => _AnimatedCurrencyTextState();
}

class _AnimatedCurrencyTextState extends State<AnimatedCurrencyText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late double _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value;
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = Tween<double>(begin: _currentValue, end: _currentValue).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );
  }

  @override
  void didUpdateWidget(AnimatedCurrencyText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      final disableAnimations = MediaQuery.of(context).disableAnimations;
      if (disableAnimations) {
        _currentValue = widget.value;
        return;
      }

      _animation = Tween<double>(
        begin: _currentValue,
        end: widget.value,
      ).animate(
        CurvedAnimation(parent: _controller, curve: widget.curve),
      );

      _controller.forward(from: 0.0).then((_) {
        _currentValue = widget.value;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.of(context).disableAnimations;
    if (disableAnimations) {
      return Text(
        widget.formatter.format(widget.value),
        style: widget.style,
      );
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Text(
          widget.formatter.format(_animation.value),
          style: widget.style,
        );
      },
    );
  }
}
