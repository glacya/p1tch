import 'package:flutter/material.dart';

/// A named set of colors for one category's screens/widgets - background,
/// text, button, border, the ripple effect, and the three tile aura states
/// (see level_play_view's _Aura: fixed/dragging/hover).
class CategoryPalette {
  const CategoryPalette({
    required this.background,
    required this.text,
    required this.button,
    required this.buttonText,
    required this.border,
    required this.surface,
    required this.ripple,
    required this.auraFixed,
    required this.auraDragging,
    required this.auraHover,
  });

  final Color background;
  final Color text;
  final Color button;
  final Color buttonText;
  final Color border;

  /// Fill color for raised elements over the background (e.g. a level_play
  /// tile) - distinct from [background] so they read as separate surfaces.
  final Color surface;
  final Color ripple;
  final Color auraFixed;
  final Color auraDragging;
  final Color auraHover;
}

/// Per-category color palettes, keyed by [Category.categoryId] (see
/// lib/app/models/category.dart) - each category gets its own distinct hue
/// family instead of one theme applied across the whole app. Add an entry
/// here whenever a new category is added to category.json.
///
/// The three aura colors (fixed/dragging/hover) stay in the same amber/
/// coral/green families across every category, since they signal
/// interaction state (locked tile, being dragged, valid drop target) rather
/// than category identity - only background/text/button/border/ripple vary
/// per category's hue.
class CategoryColors {
  CategoryColors._();

  static const Map<String, CategoryPalette> palettes = {
    'departure': CategoryPalette(
      background: Color.fromARGB(255, 0, 11, 49),
      text: Color.fromARGB(255, 216, 237, 255),
      button: Color.fromARGB(255, 137, 164, 255),
      buttonText: Color(0xFFFFFFFF),
      border: Color(0xFF8FB6D9),
      surface: Color(0xFFD6ECFB),
      ripple: Color.fromARGB(255, 0, 30, 94),
      auraFixed: Color(0xFFE0A736),
      auraDragging: Color(0xFFE8623D),
      auraHover: Color(0xFF4CAF6D),
    ),
    'dreaming': CategoryPalette(
      background: Color(0xFFF3E9FF),
      text: Color(0xFF2E1B3D),
      button: Color(0xFF8B5FBF),
      buttonText: Color(0xFFFFFFFF),
      border: Color(0xFFC5AEDB),
      surface: Color(0xFFE3D1F7),
      ripple: Color(0xFFB98EEB),
      auraFixed: Color(0xFFE0A736),
      auraDragging: Color(0xFFE8623D),
      auraHover: Color(0xFF4CAF6D),
    ),
  };
}
