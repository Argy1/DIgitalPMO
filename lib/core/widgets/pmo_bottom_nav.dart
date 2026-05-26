import 'dart:ui';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class PMOBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<PMONavItem> items;

  const PMOBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.95),
            border: Border(
              top: BorderSide(
                color: AppColors.dark.withValues(alpha: 0.08),
                width: 1,
              ),
            ),
          ),
          padding: const EdgeInsets.only(top: 10, left: 8, right: 8),
          child: SafeArea(
            top: false,
            child: Row(
              children: List.generate(
                items.length,
                (index) => Expanded(
                  child: _PMONavButton(
                    item: items[index],
                    active: currentIndex == index,
                    onTap: () => onTap(index),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PMONavButton extends StatelessWidget {
  final PMONavItem item;
  final bool active;
  final VoidCallback onTap;

  const _PMONavButton({
    required this.item,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : const Color(0xFF9AAFA8);

    return Semantics(
      label: item.label,
      selected: active,
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.icon, color: color, size: 24,
                  semanticLabel: item.label),
              const SizedBox(height: 4),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PMONavItem {
  final IconData icon;
  final String label;

  const PMONavItem({required this.icon, required this.label});
}
