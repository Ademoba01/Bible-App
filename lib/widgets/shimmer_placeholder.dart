import 'package:flutter/material.dart';

/// A shimmer effect widget that shows a pulsing skeleton placeholder.
class ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  const ShimmerBox({super.key, required this.width, required this.height, this.borderRadius = 8});

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF2B1E19) : const Color(0xFFE8E0D8);
    final highlightColor = isDark ? const Color(0xFF3E2723) : const Color(0xFFF5ECD7);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + 2.0 * _controller.value, 0),
              end: Alignment(-1.0 + 2.0 * _controller.value + 1.0, 0),
              colors: [baseColor, highlightColor, baseColor],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

/// A full reading screen shimmer skeleton
class ReadingShimmer extends StatelessWidget {
  const ReadingShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drop cap area
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ShimmerBox(width: 48, height: 48, borderRadius: 8),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  children: const [
                    ShimmerBox(width: double.infinity, height: 16),
                    SizedBox(height: 8),
                    ShimmerBox(width: double.infinity, height: 16),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Verse lines
          for (int i = 0; i < 8; i++) ...[
            ShimmerBox(width: double.infinity, height: 14, borderRadius: 4),
            const SizedBox(height: 10),
          ],
          const ShimmerBox(width: 200, height: 14, borderRadius: 4),
          const SizedBox(height: 20),
          for (int i = 0; i < 6; i++) ...[
            ShimmerBox(width: double.infinity, height: 14, borderRadius: 4),
            const SizedBox(height: 10),
          ],
          const ShimmerBox(width: 150, height: 14, borderRadius: 4),
        ],
      ),
    );
  }
}

/// A home screen card shimmer skeleton
class HomeCardShimmer extends StatelessWidget {
  const HomeCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerBox(width: double.infinity, height: 80, borderRadius: 20),
          SizedBox(height: 16),
          ShimmerBox(width: double.infinity, height: 48, borderRadius: 14),
          SizedBox(height: 16),
          Row(
            children: [
              ShimmerBox(width: 68, height: 80, borderRadius: 16),
              SizedBox(width: 8),
              ShimmerBox(width: 68, height: 80, borderRadius: 16),
              SizedBox(width: 8),
              ShimmerBox(width: 68, height: 80, borderRadius: 16),
              SizedBox(width: 8),
              ShimmerBox(width: 68, height: 80, borderRadius: 16),
            ],
          ),
        ],
      ),
    );
  }
}
