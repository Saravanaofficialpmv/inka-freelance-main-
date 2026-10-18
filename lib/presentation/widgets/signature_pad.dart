import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/constants/colors.dart';

class DrawStroke {
  final List<Offset> points;
  final Color color;
  final double width;

  DrawStroke({
    required this.points,
    required this.color,
    required this.width,
  });
}

class SignaturePadController extends ChangeNotifier {
  final List<DrawStroke> _strokes = [];
  Color _activeColor = const Color(0xFF0F172A); // Midnight Black
  double _activeWidth = 3.2;

  List<DrawStroke> get strokes => List.unmodifiable(_strokes);
  bool get isEmpty => _strokes.isEmpty;
  bool get isNotEmpty => _strokes.isNotEmpty;
  Color get activeColor => _activeColor;
  double get activeWidth => _activeWidth;

  void setColor(Color color) {
    _activeColor = color;
    notifyListeners();
  }

  void setWidth(double width) {
    _activeWidth = width;
    notifyListeners();
  }

  void addPointToCurrentStroke(Offset point) {
    if (_strokes.isEmpty) {
      _strokes.add(DrawStroke(
        points: [point],
        color: _activeColor,
        width: _activeWidth,
      ));
    } else {
      _strokes.last.points.add(point);
    }
    notifyListeners();
  }

  void startStroke(Offset point) {
    _strokes.add(DrawStroke(
      points: [point],
      color: _activeColor,
      width: _activeWidth,
    ));
    notifyListeners();
  }

  void endStroke() {
    notifyListeners();
  }

  void undo() {
    if (_strokes.isNotEmpty) {
      _strokes.removeLast();
      notifyListeners();
    }
  }

  void clear() {
    _strokes.clear();
    notifyListeners();
  }

  /// Exports the canvas strokes into transparent PNG bytes at 2x resolution
  Future<Uint8List?> exportPngBytes({required Size canvasSize}) async {
    if (isEmpty) return null;

    const double scale = 2.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, canvasSize.width * scale, canvasSize.height * scale),
    );

    canvas.scale(scale);

    for (final stroke in _strokes) {
      if (stroke.points.isEmpty) continue;

      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      if (stroke.points.length == 1) {
        canvas.drawCircle(
          stroke.points.first,
          stroke.width / 2,
          Paint()..color = stroke.color,
        );
        continue;
      }

      final path = Path();
      path.moveTo(stroke.points.first.dx, stroke.points.first.dy);

      for (int i = 1; i < stroke.points.length - 1; i++) {
        final p0 = stroke.points[i];
        final p1 = stroke.points[i + 1];
        path.quadraticBezierTo(
          p0.dx,
          p0.dy,
          (p0.dx + p1.dx) / 2,
          (p0.dy + p1.dy) / 2,
        );
      }
      path.lineTo(stroke.points.last.dx, stroke.points.last.dy);
      canvas.drawPath(path, paint);
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(
      (canvasSize.width * scale).toInt(),
      (canvasSize.height * scale).toInt(),
    );
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  /// Exports signature to a PNG file on disk and returns the absolute path
  Future<String?> saveSignatureFile({required Size canvasSize}) async {
    final bytes = await exportPngBytes(canvasSize: canvasSize);
    if (bytes == null) return null;

    Directory dir;
    try {
      dir = await getApplicationDocumentsDirectory();
    } catch (_) {
      dir = Directory.systemTemp;
    }

    final filename = 'signature_${DateTime.now().millisecondsSinceEpoch}.png';
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes);
    return file.path;
  }
}

class SignaturePad extends StatefulWidget {
  final SignaturePadController controller;
  final double height;
  final VoidCallback? onStrokeChanged;

  const SignaturePad({
    super.key,
    required this.controller,
    this.height = 220,
    this.onStrokeChanged,
  });

  @override
  State<SignaturePad> createState() => _SignaturePadState();
}

class _SignaturePadState extends State<SignaturePad> {
  static const List<Map<String, dynamic>> _colorOptions = [
    {'name': 'Black', 'color': Color(0xFF0F172A)},
    {'name': 'Navy', 'color': Color(0xFF1E3A8A)},
    {'name': 'Royal', 'color': Color(0xFF2563EB)},
    {'name': 'Coral', 'color': Color(0xFFFF5722)},
  ];

  static const List<Map<String, dynamic>> _widthOptions = [
    {'label': 'Fine', 'width': 2.0},
    {'label': 'Medium', 'width': 3.5},
    {'label': 'Bold', 'width': 5.0},
  ];

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleControllerUpdate);
  }

  @override
  void didUpdateWidget(SignaturePad oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleControllerUpdate);
      widget.controller.addListener(_handleControllerUpdate);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerUpdate);
    super.dispose();
  }

  void _handleControllerUpdate() {
    if (mounted) setState(() {});
    widget.onStrokeChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Canvas Container ──
        Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.controller.isNotEmpty
                  ? AppColors.primary.withValues(alpha: 0.5)
                  : AppColors.cardBorder,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Subtle background guide line
              Positioned(
                left: 24,
                right: 24,
                bottom: 48,
                child: Row(
                  children: [
                    const Text(
                      '✕',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFCBD5E1),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        height: 1.5,
                        color: const Color(0xFFE2E8F0),
                      ),
                    ),
                  ],
                ),
              ),

              // Placeholder Hint when empty
              if (widget.controller.isEmpty)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.gesture_rounded,
                          color: Color(0xFF94A3B8),
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Draw your signature here',
                        style: TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Use your finger or stylus to sign above the line',
                        style: TextStyle(
                          color: Color(0xFFCBD5E1),
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),

              // Active Drawing Canvas
              GestureDetector(
                key: const ValueKey('signature_drawing_canvas'),
                behavior: HitTestBehavior.opaque,
                onPanStart: (details) {
                  widget.controller.startStroke(details.localPosition);
                },
                onPanUpdate: (details) {
                  widget.controller.addPointToCurrentStroke(details.localPosition);
                },
                onPanEnd: (_) {
                  widget.controller.endStroke();
                },
                child: SizedBox.expand(
                  child: CustomPaint(
                    painter: _SignatureCustomPainter(strokes: widget.controller.strokes),
                  ),
                ),
              ),

              // Top right action buttons (Undo / Clear)
              Positioned(
                top: 10,
                right: 10,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Undo stroke',
                      icon: const Icon(Icons.undo_rounded, size: 20),
                      color: widget.controller.isNotEmpty
                          ? AppColors.textPrimary
                          : const Color(0xFFCBD5E1),
                      onPressed: widget.controller.isNotEmpty
                          ? () => widget.controller.undo()
                          : null,
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFF8FAFC),
                        padding: const EdgeInsets.all(8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      tooltip: 'Clear canvas',
                      icon: const Icon(Icons.delete_outline_rounded, size: 20),
                      color: widget.controller.isNotEmpty
                          ? AppColors.error
                          : const Color(0xFFCBD5E1),
                      onPressed: widget.controller.isNotEmpty
                          ? () => widget.controller.clear()
                          : null,
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFF8FAFC),
                        padding: const EdgeInsets.all(8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ── Customization Controls Toolbar ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Ink Colors
                const Text(
                  'Ink:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 6),
                ..._colorOptions.map((opt) {
                  final color = opt['color'] as Color;
                  final isSelected = widget.controller.activeColor == color;
                  return GestureDetector(
                    onTap: () => widget.controller.setColor(color),
                    child: Container(
                      margin: const EdgeInsets.only(right: 5),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? AppColors.primary : Colors.white,
                          width: isSelected ? 2.2 : 1.2,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.4),
                                  blurRadius: 5,
                                  offset: const Offset(0, 1.5),
                                )
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, size: 13, color: Colors.white)
                          : null,
                    ),
                  );
                }),

                // Pen Thickness Divider
                Container(
                  height: 20,
                  width: 1,
                  color: const Color(0xFFE2E8F0),
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                ),

                ..._widthOptions.map((opt) {
                  final width = opt['width'] as double;
                  final label = opt['label'] as String;
                  final isSelected = widget.controller.activeWidth == width;
                  return GestureDetector(
                    onTap: () => widget.controller.setWidth(width),
                    child: Container(
                      margin: const EdgeInsets.only(left: 3),
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.white : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SignatureCustomPainter extends CustomPainter {
  final List<DrawStroke> strokes;

  _SignatureCustomPainter({required this.strokes});

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      if (stroke.points.isEmpty) continue;

      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      if (stroke.points.length == 1) {
        canvas.drawCircle(
          stroke.points.first,
          stroke.width / 2,
          Paint()..color = stroke.color,
        );
        continue;
      }

      final path = Path();
      path.moveTo(stroke.points.first.dx, stroke.points.first.dy);

      for (int i = 1; i < stroke.points.length - 1; i++) {
        final p0 = stroke.points[i];
        final p1 = stroke.points[i + 1];
        path.quadraticBezierTo(
          p0.dx,
          p0.dy,
          (p0.dx + p1.dx) / 2,
          (p0.dy + p1.dy) / 2,
        );
      }
      path.lineTo(stroke.points.last.dx, stroke.points.last.dy);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SignatureCustomPainter oldDelegate) => true;
}
