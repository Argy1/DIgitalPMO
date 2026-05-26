import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'pmo_bottom_nav.dart';
import 'pmo_header.dart';

class PMOScreen extends StatelessWidget {
  final Widget child;
  final PMOHeader? header;
  final PMOBottomNav? bottomNav;
  final Color? backgroundColor;
  final bool safeArea;

  const PMOScreen({
    super.key,
    required this.child,
    this.header,
    this.bottomNav,
    this.backgroundColor,
    this.safeArea = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = child;

    if (safeArea) {
      content = SafeArea(
        top: header == null,
        bottom: bottomNav == null,
        child: content,
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor ?? AppColors.background,
      appBar: header != null
          ? PreferredSize(
              preferredSize: const Size.fromHeight(kToolbarHeight + 40),
              child: header!,
            )
          : null,
      body: content,
      bottomNavigationBar: bottomNav,
    );
  }
}
