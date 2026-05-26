import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PMOPressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final bool haptic;

  const PMOPressScale({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.97,
    this.haptic = true,
  });

  @override
  State<PMOPressScale> createState() => _PMOPressScaleState();
}

class _PMOPressScaleState extends State<PMOPressScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 120),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: widget.scale)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        if (widget.haptic) HapticFeedback.lightImpact();
        widget.onTap?.call();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(scale: _scaleAnim, child: widget.child),
    );
  }
}
