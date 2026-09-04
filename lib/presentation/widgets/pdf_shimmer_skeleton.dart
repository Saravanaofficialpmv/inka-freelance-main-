import 'package:flutter/material.dart';

class PdfShimmerSkeleton extends StatefulWidget {
  final double? height;
  final double? width;

  const PdfShimmerSkeleton({
    super.key,
    this.height,
    this.width,
  });

  @override
  State<PdfShimmerSkeleton> createState() => _PdfShimmerSkeletonState();
}

class _PdfShimmerSkeletonState extends State<PdfShimmerSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _animation = Tween<double>(begin: -1.5, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width ?? double.infinity,
          height: widget.height,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header (Logo + Title) ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildShimmerBox(width: 140, height: 18, radius: 4),
                      const SizedBox(height: 8),
                      _buildShimmerBox(width: 90, height: 12, radius: 4),
                    ],
                  ),
                  _buildShimmerBox(width: 44, height: 44, radius: 22),
                ],
              ),
              const SizedBox(height: 24),

              // ── Invoice Number & Date ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildShimmerBox(width: 110, height: 14, radius: 4),
                  _buildShimmerBox(width: 80, height: 14, radius: 4),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: Color(0xFFF1F5F9), height: 1),
              const SizedBox(height: 16),

              // ── Bill From & Bill To ──
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildShimmerBox(width: 60, height: 11, radius: 3),
                        const SizedBox(height: 6),
                        _buildShimmerBox(width: 100, height: 13, radius: 4),
                        const SizedBox(height: 4),
                        _buildShimmerBox(width: 80, height: 10, radius: 3),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildShimmerBox(width: 60, height: 11, radius: 3),
                        const SizedBox(height: 6),
                        _buildShimmerBox(width: 100, height: 13, radius: 4),
                        const SizedBox(height: 4),
                        _buildShimmerBox(width: 80, height: 10, radius: 3),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Items Table Header ──
              _buildShimmerBox(width: double.infinity, height: 28, radius: 8),
              const SizedBox(height: 10),

              // ── Item Rows ──
              _buildShimmerRow(),
              const SizedBox(height: 10),
              _buildShimmerRow(),
              const SizedBox(height: 10),
              _buildShimmerRow(),
              const SizedBox(height: 20),

              // ── Totals Box ──
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildShimmerBox(width: 100, height: 12, radius: 4),
                      const SizedBox(height: 6),
                      _buildShimmerBox(width: 80, height: 12, radius: 4),
                      const SizedBox(height: 8),
                      _buildShimmerBox(width: 130, height: 20, radius: 6),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShimmerRow() {
    return Row(
      children: [
        _buildShimmerBox(width: 24, height: 12, radius: 3),
        const SizedBox(width: 12),
        Expanded(child: _buildShimmerBox(width: double.infinity, height: 12, radius: 3)),
        const SizedBox(width: 16),
        _buildShimmerBox(width: 48, height: 12, radius: 3),
      ],
    );
  }

  Widget _buildShimmerBox({
    required double width,
    required double height,
    required double radius,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment(_animation.value - 1, 0),
          end: Alignment(_animation.value + 1, 0),
          colors: const [
            Color(0xFFF1F5F9),
            Color(0xFFE2E8F0),
            Color(0xFFF1F5F9),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}
