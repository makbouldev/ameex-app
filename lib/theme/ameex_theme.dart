import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/ameex_animations.dart';

class AmeexColors {
  // Official Ameex Branding Colors (unchanged)
  static const Color primaryBlue = Color(0xFF14307A);
  static const Color darkNavy = Color(0xFF04205F);
  static const Color deepNavy = Color(0xFF0A192F);
  static const Color buttonDark = Color(0xFF0B2154);

  // Neutral palette (inDrive / Yango style — restrained, light-mode first)
  static const Color background = Color(0xFFF7F8FA); // Page background
  static const Color surface = Colors.white;         // Cards / sheets
  static const Color surfaceAlt = Color(0xFFF1F3F6); // Inputs / chips
  static const Color border = Color(0xFFEDEEF2);     // Hairlines
  static const Color divider = Color(0xFFF0F1F4);

  // Text
  static const Color textDark = Color(0xFF0E1116);   // Primary text
  static const Color textMuted = Color(0xFF6B7280);  // Secondary text
  static const Color textFaint = Color(0xFF9CA3AF);  // Placeholder / caption

  // Status
  static const Color successGreen = Color(0xFF10B981);
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color dangerRed = Color(0xFFDC2626);

  // Legacy aliases (kept so existing screens keep compiling)
  static const Color lightBlue = Color(0xFFEFF3FB);
  static const Color softBlue = Color(0xFFE4EBF7);
  static const Color surfaceGray = background;
  static const Color cardBorder = border;
}

/// Minimal design tokens — spacing, radii, shadows.
class AmeexDesign {
  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 20;
  static const double space6 = 24;
  static const double space8 = 32;

  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 18;
  static const double radiusXl = 22;
  static const double radiusPill = 999;

  // Layered shadows — premium depth (Revolut/Linear/Stripe quality).
  static List<BoxShadow> shadowCard = [
    BoxShadow(
      color: const Color(0xFF0E1116).withValues(alpha: 0.025),
      blurRadius: 1,
      offset: const Offset(0, 1),
    ),
    BoxShadow(
      color: const Color(0xFF0E1116).withValues(alpha: 0.04),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> shadowElevated = [
    BoxShadow(
      color: const Color(0xFF0E1116).withValues(alpha: 0.03),
      blurRadius: 1,
      offset: const Offset(0, 1),
    ),
    BoxShadow(
      color: const Color(0xFF0E1116).withValues(alpha: 0.06),
      blurRadius: 28,
      offset: const Offset(0, 12),
    ),
  ];

  static List<BoxShadow> shadowHero = [
    BoxShadow(
      color: AmeexColors.primaryBlue.withValues(alpha: 0.10),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
    BoxShadow(
      color: AmeexColors.primaryBlue.withValues(alpha: 0.22),
      blurRadius: 40,
      offset: const Offset(0, 20),
      spreadRadius: -12,
    ),
  ];

  static List<BoxShadow> shadowButton = [
    BoxShadow(
      color: AmeexColors.primaryBlue.withValues(alpha: 0.18),
      blurRadius: 18,
      offset: const Offset(0, 8),
      spreadRadius: -6,
    ),
  ];

  // Signature brand gradient (used sparingly, only on hero card)
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1E3A8A),
      AmeexColors.primaryBlue,
      AmeexColors.darkNavy,
    ],
    stops: [0.0, 0.55, 1.0],
  );
}

class AmeexTheme {
  static const String fontFamily = 'PlusJakartaSans';

  static ThemeData get lightTheme {
    final base = ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AmeexColors.primaryBlue,
        onPrimary: Colors.white,
        secondary: AmeexColors.darkNavy,
        onSecondary: Colors.white,
        surface: Colors.white,
        onSurface: AmeexColors.textDark,
        error: AmeexColors.dangerRed,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: AmeexColors.background,
      splashFactory: InkRipple.splashFactory,
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AmeexColors.textDark,
        surfaceTintColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        iconTheme: IconThemeData(color: AmeexColors.textDark, size: 22),
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontWeight: FontWeight.w600,
          fontSize: 17,
          letterSpacing: -0.1,
          color: AmeexColors.textDark,
        ),
      ),
      textTheme: base.textTheme.copyWith(
        displayLarge: const TextStyle(
          fontFamily: fontFamily, fontSize: 28, fontWeight: FontWeight.w700,
          letterSpacing: -0.6, color: AmeexColors.textDark, height: 1.15,
        ),
        headlineMedium: const TextStyle(
          fontFamily: fontFamily, fontSize: 22, fontWeight: FontWeight.w700,
          letterSpacing: -0.3, color: AmeexColors.textDark,
        ),
        titleLarge: const TextStyle(
          fontFamily: fontFamily, fontSize: 17, fontWeight: FontWeight.w600,
          letterSpacing: -0.1, color: AmeexColors.textDark,
        ),
        titleMedium: const TextStyle(
          fontFamily: fontFamily, fontSize: 15, fontWeight: FontWeight.w600,
          color: AmeexColors.textDark,
        ),
        bodyLarge: const TextStyle(
          fontFamily: fontFamily, fontSize: 15, fontWeight: FontWeight.w500,
          color: AmeexColors.textDark, height: 1.45,
        ),
        bodyMedium: const TextStyle(
          fontFamily: fontFamily, fontSize: 13.5, fontWeight: FontWeight.w500,
          color: AmeexColors.textMuted, height: 1.4,
        ),
        labelLarge: const TextStyle(
          fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w600,
          color: AmeexColors.textDark,
        ),
      ),
      iconTheme: const IconThemeData(
        color: AmeexColors.textDark,
        size: 22,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return AmeexColors.primaryBlue.withValues(alpha: 0.4);
            }
            return AmeexColors.primaryBlue;
          }),
          foregroundColor: const WidgetStatePropertyAll(Colors.white),
          elevation: const WidgetStatePropertyAll(0),
          overlayColor: WidgetStatePropertyAll(
            Colors.white.withValues(alpha: 0.08),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AmeexDesign.radiusMd),
            ),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(
              fontFamily: fontFamily,
              fontWeight: FontWeight.w600,
              fontSize: 15,
              letterSpacing: 0,
            ),
          ),
          minimumSize: const WidgetStatePropertyAll(Size(0, 52)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AmeexColors.primaryBlue,
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AmeexColors.textDark,
          backgroundColor: Colors.white,
          side: const BorderSide(color: AmeexColors.border, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AmeexDesign.radiusMd),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          minimumSize: const Size(0, 50),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AmeexDesign.radiusLg),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AmeexColors.surfaceAlt,
        hintStyle: const TextStyle(
          fontFamily: fontFamily,
          color: AmeexColors.textFaint,
          fontSize: 14.5,
          fontWeight: FontWeight.w500,
        ),
        labelStyle: const TextStyle(
          fontFamily: fontFamily,
          color: AmeexColors.textMuted,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        floatingLabelStyle: const TextStyle(
          fontFamily: fontFamily,
          color: AmeexColors.primaryBlue,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        prefixIconColor: AmeexColors.textMuted,
        suffixIconColor: AmeexColors.textMuted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AmeexDesign.radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AmeexDesign.radiusMd),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AmeexDesign.radiusMd),
          borderSide:
              const BorderSide(color: AmeexColors.primaryBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AmeexDesign.radiusMd),
          borderSide: const BorderSide(color: AmeexColors.dangerRed, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AmeexDesign.radiusMd),
          borderSide: const BorderSide(color: AmeexColors.dangerRed, width: 1.5),
        ),
        errorStyle: const TextStyle(
          fontFamily: fontFamily,
          color: AmeexColors.dangerRed,
          fontSize: 12.5,
          fontWeight: FontWeight.w500,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AmeexColors.surfaceAlt,
        selectedColor: AmeexColors.primaryBlue,
        disabledColor: AmeexColors.surfaceAlt,
        side: BorderSide.none,
        labelStyle: const TextStyle(
          fontFamily: fontFamily,
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: AmeexColors.textDark,
        ),
        secondaryLabelStyle: const TextStyle(
          fontFamily: fontFamily,
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: Colors.white,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AmeexDesign.radiusPill),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AmeexColors.divider,
        thickness: 1,
        space: 24,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AmeexColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 2,
        focusElevation: 2,
        hoverElevation: 3,
        highlightElevation: 4,
        shape: StadiumBorder(),
        extendedTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontWeight: FontWeight.w600,
          fontSize: 14.5,
          letterSpacing: 0,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AmeexColors.primaryBlue,
        unselectedItemColor: AmeexColors.textFaint,
        selectedLabelStyle: TextStyle(
          fontFamily: fontFamily,
          fontWeight: FontWeight.w600,
          fontSize: 11.5,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: fontFamily,
          fontWeight: FontWeight.w500,
          fontSize: 11.5,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AmeexColors.textDark,
        contentTextStyle: const TextStyle(
          fontFamily: fontFamily,
          color: Colors.white,
          fontWeight: FontWeight.w500,
          fontSize: 13.5,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AmeexDesign.radiusMd),
        ),
        elevation: 2,
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

/// Official Ameex Logo Widget (asset + font fallback)
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
        return Text(
          'ameex',
          style: TextStyle(
            fontFamily: AmeexTheme.fontFamily,
            fontSize: fontSize ?? (height * 0.95),
            fontWeight: FontWeight.w800,
            letterSpacing: -1.4,
            color: isWhite ? Colors.white : AmeexColors.darkNavy,
          ),
        );
      },
    );
  }
}

/// Subtle slogan badge — restrained, compact.
class AmeexSloganBadge extends StatelessWidget {
  final bool isLight;

  const AmeexSloganBadge({super.key, this.isLight = false});

  @override
  Widget build(BuildContext context) {
    final fg = isLight ? Colors.white : AmeexColors.primaryBlue;
    final bg = isLight
        ? Colors.white.withValues(alpha: 0.12)
        : AmeexColors.primaryBlue.withValues(alpha: 0.07);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AmeexDesign.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.arrow_forward_rounded, size: 11, color: fg),
          const SizedBox(width: 5),
          Text(
            'AMEEXCEPTIONAL EXPERIENCE',
            style: TextStyle(
              fontFamily: AmeexTheme.fontFamily,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
