import 'package:flutter/material.dart';
import '../widgets/ameex_animations.dart';

class AmeexColors {
  // Official Ameex Branding Colors (from ameex.ma)
  static const Color primaryBlue = Color(0xFF14307A); // Official Ameex Hero Royal Blue
  static const Color darkNavy = Color(0xFF04205F);    // Ameex Midnight Blue (Buttons, dark headers)
  static const Color deepNavy = Color(0xFF0A192F);    // Ameex Deep Contrast
  static const Color buttonDark = Color(0xFF0B2154);  // "Track my order" / "Become a client"
  
  // Accents & Surfaces
  static const Color lightBlue = Color(0xFFEFF5FF);   // Subtle highlight background
  static const Color softBlue = Color(0xFFDCE8FA);    // Card border / accent tint
  static const Color surfaceGray = Color(0xFFF8FAFC); // Clean page background
  static const Color cardBorder = Color(0xFFE2E8F0);  // Subtle card stroke
  static const Color textDark = Color(0xFF0F172A);    // Primary high-contrast text
  static const Color textMuted = Color(0xFF64748B);   // Secondary text
  
  // Status Colors
  static const Color successGreen = Color(0xFF10B981); // Delivered / Active GPS
  static const Color warningAmber = Color(0xFFF59E0B); // Pending / In Agency
  static const Color dangerRed = Color(0xFFDC2626);    // Cancelled / Destination Pin
}

class AmeexTheme {
  static const String fontFamily = 'PlusJakartaSans';

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AmeexColors.primaryBlue,
        primary: AmeexColors.primaryBlue,
        secondary: AmeexColors.darkNavy,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: AmeexColors.surfaceGray,
      appBarTheme: const AppBarTheme(
        backgroundColor: AmeexColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AmeexColors.primaryBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AmeexColors.cardBorder, width: 1),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: AmeexPageTransitionsBuilder(),
          TargetPlatform.iOS: AmeexPageTransitionsBuilder(),
          TargetPlatform.windows: AmeexPageTransitionsBuilder(),
          TargetPlatform.macOS: AmeexPageTransitionsBuilder(),
          TargetPlatform.linux: AmeexPageTransitionsBuilder(),
          TargetPlatform.fuchsia: AmeexPageTransitionsBuilder(),
        },
      ),
    );
  }
}

/// Official Ameex Logo Widget (Supports transparent asset + crisp font fallback)
class AmeexLogo extends StatelessWidget {
  final bool isWhite;
  final double height;
  final double? fontSize;

  const AmeexLogo({
    super.key,
    this.isWhite = false,
    this.height = 26,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      isWhite ? 'assets/images/logo_white.png' : 'assets/images/logo_dark.png',
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // High fidelity fallback typography
        return Text(
          'ameex',
          style: TextStyle(
            fontFamily: AmeexTheme.fontFamily,
            fontSize: fontSize ?? (height * 0.9),
            fontWeight: FontWeight.w900,
            letterSpacing: -1.2,
            color: isWhite ? Colors.white : AmeexColors.darkNavy,
          ),
        );
      },
    );
  }
}

/// Official Ameex Slogan Badge ("→ MORE THAN A DELIVERY, AN AMEEXCEPTIONAL EXPERIENCE.")
class AmeexSloganBadge extends StatelessWidget {
  final bool isLight;

  const AmeexSloganBadge({super.key, this.isLight = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isLight
            ? Colors.white.withValues(alpha: 0.15)
            : AmeexColors.primaryBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isLight
              ? Colors.white.withValues(alpha: 0.25)
              : AmeexColors.primaryBlue.withValues(alpha: 0.2),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.arrow_forward_rounded,
            size: 11,
            color: isLight ? Colors.white70 : AmeexColors.primaryBlue,
          ),
          const SizedBox(width: 5),
          Text(
            'MORE THAN A DELIVERY, AN AMEEXCEPTIONAL EXPERIENCE',
            style: TextStyle(
              fontFamily: AmeexTheme.fontFamily,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: isLight ? Colors.white : AmeexColors.primaryBlue,
            ),
          ),
        ],
      ),
    );
  }
}
