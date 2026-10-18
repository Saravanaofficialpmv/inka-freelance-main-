import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_motion.dart';

/// Smoothly transitions numeric financial values (subtotal, tax, grand total)
/// with an animated rolling transition, preserving exact currency formatting.
class AnimatedCurrencyText extends StatefulWidget {
  final double value;
  final NumberFormat formatter;
  final TextStyle? style;
  final Duration duration;
  final Curve curve;
  final bool countUpInitial;

  final String? prefix;

  const AnimatedCurrencyText({
    super.key,
    required this.value,
    required this.formatter,
    this.prefix,
    this.style,
    this.duration = AppMotion.numberTransition,
    this.curve = AppMotion.numberCurve,
    this.countUpInitial = false,
  });

  @override
  State<AnimatedCurrencyText> createState() => _AnimatedCurrencyTextState();
}

class _AnimatedCurrencyTextState extends State<AnimatedCurrencyText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _fromValue = 0.0;
  double _toValue = 0.0;

  @override
  void initState() {
    super.initState();
    _fromValue = widget.countUpInitial ? 0.0 : widget.value;
    _toValue = widget.value;

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _animation = Tween<double>(begin: _fromValue, end: _toValue).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );

    if (widget.countUpInitial && _fromValue != _toValue) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(AnimatedCurrencyText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((oldWidget.value - widget.value).abs() > 0.001) {
      final disableAnimations = AppMotion.isReducedMotion(context);
      _fromValue = _animation.value;
      _toValue = widget.value;

      if (disableAnimations) {
        _controller.value = 1.0;
        return;
      }

      _animation = Tween<double>(begin: _fromValue, end: _toValue).animate(
        CurvedAnimation(parent: _controller, curve: widget.curve),
      );

      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = AppMotion.isReducedMotion(context);
    final p = widget.prefix ?? '';
    if (disableAnimations) {
      return Text(
        '$p${widget.formatter.format(widget.value)}',
        style: widget.style,
      );
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Text(
          '$p${widget.formatter.format(_animation.value)}',
          style: widget.style,
        );
      },
    );
  }
}

/// A signature fintech amount display widget that splits the value into an
/// emphatic integer portion and smaller decimal portion (.00) with smooth count-up.
class AnimatedFormattedAmount extends StatefulWidget {
  final double amount;
  final NumberFormat currencyFormat;
  final TextStyle? intStyle;
  final TextStyle? decStyle;
  final bool countUpInitial;

  const AnimatedFormattedAmount({
    super.key,
    required this.amount,
    required this.currencyFormat,
    this.intStyle,
    this.decStyle,
    this.countUpInitial = true,
  });

  @override
  State<AnimatedFormattedAmount> createState() => _AnimatedFormattedAmountState();
}

class _AnimatedFormattedAmountState extends State<AnimatedFormattedAmount>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _fromValue = 0.0;
  double _toValue = 0.0;

  @override
  void initState() {
    super.initState();
    _fromValue = widget.countUpInitial ? 0.0 : widget.amount;
    _toValue = widget.amount;

    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.numberTransition,
    );

    _animation = Tween<double>(begin: _fromValue, end: _toValue).animate(
      CurvedAnimation(parent: _controller, curve: AppMotion.numberCurve),
    );

    if (widget.countUpInitial && _fromValue != _toValue) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(AnimatedFormattedAmount oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((oldWidget.amount - widget.amount).abs() > 0.001) {
      final disableAnimations = AppMotion.isReducedMotion(context);
      _fromValue = _animation.value;
      _toValue = widget.amount;

      if (disableAnimations) {
        _controller.value = 1.0;
        return;
      }

      _animation = Tween<double>(begin: _fromValue, end: _toValue).animate(
        CurvedAnimation(parent: _controller, curve: AppMotion.numberCurve),
      );

      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  (String, String) _splitFormatted(double value) {
    final formatted = widget.currencyFormat.format(value);
    String intPart = formatted;
    String decPart = '.00';

    if (formatted.contains('.')) {
      final parts = formatted.split('.');
      intPart = parts[0];
      decPart = '.${parts[1]}';
    } else if (formatted.contains(',')) {
      final commaIndex = formatted.lastIndexOf(',');
      if (commaIndex != -1 && commaIndex > formatted.length - 4) {
        intPart = formatted.substring(0, commaIndex);
        decPart = formatted.substring(commaIndex);
      }
    }
    return (intPart, decPart);
  }

  @override
  Widget build(BuildContext context) {
    final defaultIntStyle = widget.intStyle ??
        const TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 21,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
        );

    final defaultDecStyle = widget.decStyle ??
        const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 15,
          fontWeight: FontWeight.w700,
        );

    final disableAnimations = AppMotion.isReducedMotion(context);
    if (disableAnimations) {
      final (intPart, decPart) = _splitFormatted(widget.amount);
      return FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: RichText(
          text: TextSpan(
            style: defaultIntStyle,
            children: [
              TextSpan(text: intPart),
              TextSpan(text: decPart, style: defaultDecStyle),
            ],
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final (intPart, decPart) = _splitFormatted(_animation.value);
        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: RichText(
            text: TextSpan(
              style: defaultIntStyle,
              children: [
                TextSpan(text: intPart),
                TextSpan(text: decPart, style: defaultDecStyle),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// An animated integer counter for counts such as overdue invoices or total clients.
class AnimatedCountText extends StatelessWidget {
  final int count;
  final TextStyle? style;
  final Duration duration;

  const AnimatedCountText({
    super.key,
    required this.count,
    this.style,
    this.duration = AppMotion.numberTransition,
  });

  @override
  Widget build(BuildContext context) {
    if (AppMotion.isReducedMotion(context)) {
      return Text('$count', style: style);
    }

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: count.toDouble()),
      duration: duration,
      curve: AppMotion.numberCurve,
      builder: (context, val, child) {
        return Text(
          '${val.round()}',
          style: style,
        );
      },
    );
  }
}
