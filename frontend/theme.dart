import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// MindPay design system.
/// Amber is reserved ONLY for the pause moment — it never appears
/// anywhere else in the app, so when the user sees it, it means one thing.
class MindColors {
  static const forest = Color(0xFF1C3B36); // primary — grounding, calm
  static const forestLight = Color(0xFF2F5750);
  static const background = Color(0xFFF6F5F1); // warm off-white
  static const card = Color(0xFFFFFFFF);
  static const ink = Color(0xFF1B211F); // primary text
  static const inkSoft = Color(0xFF5C6B67); // secondary text
  static const pauseAmber = Color(0xFFC99A3D); // reserved: pause moments only
  static const rewardSage = Color(0xFF4F7965); // reserved: "you skipped this" moment
  static const divider = Color(0xFFE3E0D8);
}

class MindTheme {
  static ThemeData get theme {
    final displayFont = GoogleFonts.fraunces(); // characterful serif for headings
    final bodyFont = GoogleFonts.inter(); // clean grotesk for body/numbers

    return ThemeData(
      scaffoldBackgroundColor: MindColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: MindColors.forest,
        primary: MindColors.forest,
        background: MindColors.background,
      ),
      textTheme: TextTheme(
        headlineLarge: GoogleFonts.fraunces(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: MindColors.ink,
          height: 1.15,
        ),
        headlineMedium: GoogleFonts.fraunces(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: MindColors.ink,
        ),
        bodyLarge: bodyFont.copyWith(fontSize: 16, color: MindColors.ink),
        bodyMedium: bodyFont.copyWith(fontSize: 14, color: MindColors.inkSoft),
        labelLarge: bodyFont.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ).apply(fontFamily: displayFont.fontFamily),
      useMaterial3: true,
    );
  }
}
