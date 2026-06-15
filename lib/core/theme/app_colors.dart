import 'package:flutter/material.dart';

/// JAGO brand palette.
///
/// Jago's identity is built around a vibrant orange on a clean white surface,
/// with a set of playful accent colors used to distinguish "Kantong" (pockets).
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFFFF6B00); // Jago orange
  static const Color primaryDark = Color(0xFFE85D00);
  static const Color primaryLight = Color(0xFFFFE7D6);

  // Neutrals
  static const Color black = Color(0xFF111111);
  static const Color white = Color(0xFFFFFFFF);
  static const Color grey = Color(0xFFA4A4A4);
  static const Color lightGrey = Color(0xFFF6F7FB);
  static const Color border = Color(0x1F000000);

  // Semantic
  static const Color success = Color(0xFF1FB57A);
  static const Color error = Color(0xFFE5484D);

  // Pocket accent palette (cycled by index).
  static const List<Color> pocketAccents = <Color>[
    Color(0xFFFF6B00), // orange
    Color(0xFF7C4DFF), // purple
    Color(0xFF00BFA5), // teal
    Color(0xFF2979FF), // blue
    Color(0xFFFF4081), // pink
    Color(0xFFFFC400), // yellow
  ];

  static Color pocketAccent(int index) =>
      pocketAccents[index % pocketAccents.length];
}
