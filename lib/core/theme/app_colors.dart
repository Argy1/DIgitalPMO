import 'package:flutter/material.dart';

class AppColors {
  // Primary brand colors
  static const Color primary = Color(0xFF1A6B5A);
  static const Color primaryDeep = Color(0xFF125146);
  static const Color dark = Color(0xFF1A2E2A);

  // Background & Cards
  static const Color background = Color(0xFFF0F7F5);
  static const Color card = Color(0xFFFFFFFF);

  // Accents
  static const Color amber = Color(0xFFF5A623);
  static const Color amberSoft = Color(0xFFFEF3E2);
  static const Color tealSoft = Color(0xFFE8F5F1);
  static const Color success = Color(0xFF27AE60);
  static const Color danger = Color(0xFFE74C3C);

  // Text colors
  static const Color text = Color(0xFF1A2E2A);
  static const Color textMute = Color(0xFF6B8080);
  static const Color border = Color(0xFFD4ECE6);

  // Medicine pill colors
  static const Color medR = Color(0xFFE74C3C); // Rifampicin - Red
  static const Color medH = Color(0xFF2E86DE); // Isoniazid - Blue
  static const Color medZ = Color(0xFFF5A623); // Pirazinamid - Amber
  static const Color medE = Color(0xFF8B5CF6); // Etambutol - Purple

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment(0.5, 0),
    end: Alignment(0.5, 1),
    colors: [primary, primaryDeep],
  );

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, Color(0xFF15594B)],
    stops: [0.0, 1.0],
  );

  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1FA15A), Color(0xFF167A45)],
  );

  static const LinearGradient amberGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [amber, Color(0xFFD88A12)],
  );

  // Helper method for medicine colors
  static Color getMedColor(String kind) {
    switch (kind) {
      case 'R':
        return medR;
      case 'H':
        return medH;
      case 'Z':
        return medZ;
      case 'E':
        return medE;
      default:
        return primary;
    }
  }

  static String getMedName(String kind) {
    switch (kind) {
      case 'R':
        return 'Rifampicin';
      case 'H':
        return 'Isoniazid';
      case 'Z':
        return 'Pirazinamid';
      case 'E':
        return 'Etambutol';
      default:
        return '';
    }
  }
}
