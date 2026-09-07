import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Light Mode Colors
  static const Color lightBackground = Color(0xFFF7F9F7);
  static const Color lightForeground = Color(0xFF17212B);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightCardForeground = Color(0xFF17212B);
  static const Color lightPopover = Color(0xFFFFFFFF);
  static const Color lightPopoverForeground = Color(0xFF17212B);

  static const Color lightPrimary = Color(0xFF123B46); // Deep Navy
  static const Color lightPrimaryForeground = Color(0xFFFFFFFF);

  static const Color lightSecondary = Color(0xFFE6F3F0); // Soft Mint
  static const Color lightSecondaryForeground = Color(0xFF174A52);

  static const Color lightMuted = Color(0xFFEEF2F1);
  static const Color lightMutedForeground = Color(0xFF64747A);

  static const Color lightAccent = Color(0xFFD8F0EB);
  static const Color lightAccentForeground = Color(0xFF123B46);

  static const Color lightDestructive = Color(0xFFD95C5C);
  static const Color lightDestructiveForeground = Color(0xFFFFFFFF);

  static const Color lightBorder = Color(0xFFDCE5E3);
  static const Color lightInput = Color(0xFFE3EAE8);

  static const Color lightRing = Color(0xFF159A8C); // Echo Teal
  static const Color lightTeal = Color(0xFF159A8C);

  // Dark Mode Colors
  static const Color darkBackground = Color(0xFF0B171B);
  static const Color darkForeground = Color(0xFFEDF7F5);
  static const Color darkCard = Color(0xFF112328);
  static const Color darkCardForeground = Color(0xFFEDF7F5);
  static const Color darkPopover = Color(0xFF112328);
  static const Color darkPopoverForeground = Color(0xFFEDF7F5);

  static const Color darkPrimary = Color(0xFF45C4B4); // Luminous Teal
  static const Color darkPrimaryForeground = Color(0xFF092024);

  static const Color darkSecondary = Color(0xFF183238);
  static const Color darkSecondaryForeground = Color(0xFFCBE9E4);

  static const Color darkMuted = Color(0xFF14282D);
  static const Color darkMutedForeground = Color(0xFF91AAA9);

  static const Color darkAccent = Color(0xFF183C3D);
  static const Color darkAccentForeground = Color(0xFFBDEDE6);

  static const Color darkBorder = Color(0xFF254247);
  static const Color darkInput = Color(0xFF203A3F);

  static const Color darkRing = Color(0xFF45C4B4);
  static const Color darkTeal = Color(0xFF45C4B4);

  // Chart & Progress Colors
  static const Color chart1 = Color(0xFF159A8C); // Teal
  static const Color chart2 = Color(0xFF123B46); // Navy
  static const Color chart3 = Color(0xFF4DB6AC); // Mint-Teal
  static const Color chart4 = Color(0xFFF2B35D); // Subtle Amber
  static const Color chart5 = Color(0xFFE47763); // Subtle Coral
}

class AppRadii {
  static const double sm = 8.0;
  static const double button = 10.0;
  static const double card = 14.0;
  static const double feature = 18.0;
  static const double pill = 999.0;

  static BorderRadius smRadius = BorderRadius.circular(sm);
  static BorderRadius buttonRadius = BorderRadius.circular(button);
  static BorderRadius cardRadius = BorderRadius.circular(card);
  static BorderRadius featureRadius = BorderRadius.circular(feature);
  static BorderRadius pillRadius = BorderRadius.circular(pill);
}

class AppShadows {
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x0F123B46), // 6% Deep Navy
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> elevated = [
    BoxShadow(
      color: Color(0x14123B46), // 8% Deep Navy
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> darkCard = [
    BoxShadow(
      color: Color(0x33000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: const ColorScheme.light(
        primary: AppColors.lightPrimary,
        onPrimary: AppColors.lightPrimaryForeground,
        secondary: AppColors.lightSecondary,
        onSecondary: AppColors.lightSecondaryForeground,
        surface: AppColors.lightCard,
        onSurface: AppColors.lightForeground,
        error: AppColors.lightDestructive,
        onError: AppColors.lightDestructiveForeground,
        outline: AppColors.lightBorder,
        outlineVariant: AppColors.lightMuted,
        tertiary: AppColors.lightTeal,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme().copyWith(
        displayLarge: GoogleFonts.plusJakartaSans(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: AppColors.lightForeground,
          letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.plusJakartaSans(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: AppColors.lightForeground,
          letterSpacing: -0.3,
        ),
        headlineSmall: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.lightForeground,
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.lightForeground,
        ),
        titleSmall: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.lightForeground,
        ),
        bodyLarge: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.lightForeground,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.lightMutedForeground,
          height: 1.5,
        ),
        labelLarge: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.lightForeground,
        ),
        labelSmall: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.lightMutedForeground,
          letterSpacing: 0.8,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.cardRadius,
          side: const BorderSide(color: AppColors.lightBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.lightPrimary,
          foregroundColor: AppColors.lightPrimaryForeground,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadii.buttonRadius,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.lightPrimary,
          side: const BorderSide(color: AppColors.lightBorder, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadii.buttonRadius,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: AppRadii.cardRadius,
          borderSide: const BorderSide(color: AppColors.lightBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.cardRadius,
          borderSide: const BorderSide(color: AppColors.lightBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.cardRadius,
          borderSide: const BorderSide(color: AppColors.lightTeal, width: 1.5),
        ),
        hintStyle: GoogleFonts.plusJakartaSans(
          color: AppColors.lightMutedForeground,
          fontSize: 14,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightCard,
        selectedItemColor: AppColors.lightTeal,
        unselectedItemColor: AppColors.lightMutedForeground,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.darkPrimary,
        onPrimary: AppColors.darkPrimaryForeground,
        secondary: AppColors.darkSecondary,
        onSecondary: AppColors.darkSecondaryForeground,
        surface: AppColors.darkCard,
        onSurface: AppColors.darkForeground,
        error: AppColors.lightDestructive,
        onError: Colors.white,
        outline: AppColors.darkBorder,
        outlineVariant: AppColors.darkMuted,
        tertiary: AppColors.darkTeal,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.plusJakartaSans(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: AppColors.darkForeground,
          letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.plusJakartaSans(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: AppColors.darkForeground,
          letterSpacing: -0.3,
        ),
        headlineSmall: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.darkForeground,
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.darkForeground,
        ),
        bodyLarge: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.darkForeground,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.darkMutedForeground,
          height: 1.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.cardRadius,
          side: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.darkPrimary,
          foregroundColor: AppColors.darkPrimaryForeground,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadii.buttonRadius,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          elevation: 0,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: AppRadii.cardRadius,
          borderSide: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.cardRadius,
          borderSide: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.cardRadius,
          borderSide: const BorderSide(color: AppColors.darkTeal, width: 1.5),
        ),
        hintStyle: GoogleFonts.plusJakartaSans(
          color: AppColors.darkMutedForeground,
          fontSize: 14,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkCard,
        selectedItemColor: AppColors.darkTeal,
        unselectedItemColor: AppColors.darkMutedForeground,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}
