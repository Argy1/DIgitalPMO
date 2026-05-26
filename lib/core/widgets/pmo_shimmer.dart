import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';

enum ShimmerVariant { card, text, circle }

class PMOShimmer extends StatefulWidget {
  final ShimmerVariant variant;
  final double width;
  final double height;

  const PMOShimmer({
    super.key,
    this.variant = ShimmerVariant.card,
    this.width = double.infinity,
    this.height = 100,
  });

  @override
  State<PMOShimmer> createState() => _PMOShimmerState();
}

class _PMOShimmerState extends State<PMOShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1.0 - _controller.value * 2, 0),
              end: Alignment(1.0 + _controller.value * 2, 0),
              colors: const [
                Colors.transparent,
                Colors.white24,
                Colors.transparent,
              ],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: _buildShimmerShape(),
    );
  }

  Widget _buildShimmerShape() {
    switch (widget.variant) {
      case ShimmerVariant.card:
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
          ),
        );
      case ShimmerVariant.text:
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      case ShimmerVariant.circle:
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: const BoxDecoration(
            color: Colors.grey,
            shape: BoxShape.circle,
          ),
        );
    }
  }
}
