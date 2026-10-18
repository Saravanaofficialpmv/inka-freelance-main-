import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/theme_helper.dart';

enum VoiceState { idle, listening, processing, success, error }

/// A subtle, production-ready microphone listening and rhythmic waveform widget.
/// Distinctly visualizes idle, listening, processing, success, and error states.
class VoiceWaveformIndicator extends StatefulWidget {
  final VoiceState state;
  final double soundLevel;
  final VoidCallback onTap;
  final String label;

  const VoiceWaveformIndicator({
    super.key,
    required this.state,
    this.soundLevel = 0.0,
    required this.onTap,
    this.label = 'Voice',
  });

  @override
  State<VoiceWaveformIndicator> createState() => _VoiceWaveformIndicatorState();
}

class _VoiceWaveformIndicatorState extends State<VoiceWaveformIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    if (widget.state == VoiceState.listening) {
      _waveController.repeat();
    }
  }

  @override
  void didUpdateWidget(VoiceWaveformIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.state != oldWidget.state) {
      if (widget.state == VoiceState.listening) {
        _waveController.repeat();
      } else {
        _waveController.stop();
        _waveController.reset();
      }
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isListening = widget.state == VoiceState.listening;
    final isProcessing = widget.state == VoiceState.processing;
    final isSuccess = widget.state == VoiceState.success;
    final isError = widget.state == VoiceState.error;

    Color borderColor;
    Color bgColor;
    Color primaryColor;

    if (isListening) {
      borderColor = const Color(0xFF0F172A);
      bgColor = const Color(0xFFF1F5F9);
      primaryColor = const Color(0xFF0F172A);
    } else if (isProcessing) {
      borderColor = const Color(0xFF0284C7);
      bgColor = const Color(0xFF0284C7).withValues(alpha: 0.1);
      primaryColor = const Color(0xFF0284C7);
    } else if (isSuccess) {
      borderColor = const Color(0xFF10B981);
      bgColor = const Color(0xFF10B981).withValues(alpha: 0.1);
      primaryColor = const Color(0xFF10B981);
    } else if (isError) {
      borderColor = const Color(0xFFEF4444);
      bgColor = const Color(0xFFEF4444).withValues(alpha: 0.1);
      primaryColor = const Color(0xFFEF4444);
    } else {
      borderColor = context.cardBorder;
      bgColor = context.cardBg;
      primaryColor = context.textPrimary;
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: isListening ? 1.4 : 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isListening) ...[
              // Animated rhythmic waveform bars
              AnimatedBuilder(
                animation: _waveController,
                builder: (context, child) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(4, (index) {
                      final phase = (index * (math.pi / 2));
                      final normalized = (math.sin((_waveController.value * 2 * math.pi) + phase) + 1) / 2;
                      final levelBoost = (widget.soundLevel.clamp(0.0, 10.0) / 10.0) * 8.0;
                      final barHeight = (6.0 + (normalized * 12.0) + levelBoost).clamp(5.0, 22.0);

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1.5),
                        width: 3.0,
                        height: barHeight,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(1.5),
                        ),
                      );
                    }),
                  );
                },
              ),
              const SizedBox(width: 8),
              Text(
                'Listening...',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ] else if (isProcessing) ...[
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0284C7)),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Processing...',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0284C7),
                ),
              ),
            ] else if (isSuccess) ...[
              const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF10B981)),
              const SizedBox(width: 6),
              const Text(
                'Added!',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF10B981),
                ),
              ),
            ] else if (isError) ...[
              const Icon(Icons.error_outline_rounded, size: 16, color: Color(0xFFEF4444)),
              const SizedBox(width: 6),
              const Text(
                'Retry',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFEF4444),
                ),
              ),
            ] else ...[
              Icon(Icons.mic_none_rounded, size: 18, color: context.textSecondary),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
