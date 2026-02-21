// ExecPrompt - AI LLM Mobile Client
// Copyright (C) 2026 DayOfGeek.com
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Available CyberTerm theme palettes
enum CyberTermTheme {
  p1Green('P1 Green', 'Classic green phosphor'),
  p3Amber('P3 Amber', 'Warm amber terminal'),
  p4White('P4 White', 'Cool bright terminal'),
  neonCyan('Neon Cyan', 'Cyberpunk edge'),
  synthwave('Synthwave', '80s retro vibes');

  final String displayName;
  final String description;
  const CyberTermTheme(this.displayName, this.description);

  static CyberTermTheme fromName(String name) {
    return CyberTermTheme.values.firstWhere(
      (t) => t.name == name,
      orElse: () => CyberTermTheme.p1Green,
    );
  }
}

/// Color palette for a CyberTerm theme
class CyberTermColors {
  final Color background;
  final Color surface;
  final Color surfaceLight;
  final Color primary;
  final Color primaryDim;
  final Color textColor;
  final Color textDim;
  final Color accent;
  final Color error;
  final Color border;
  final Color userBubble;
  final Color botBubble;
  final Color inputFill;
  final Color drawerBg;

  const CyberTermColors({
    required this.background,
    required this.surface,
    required this.surfaceLight,
    required this.primary,
    required this.primaryDim,
    required this.textColor,
    required this.textDim,
    required this.accent,
    required this.error,
    required this.border,
    required this.userBubble,
    required this.botBubble,
    required this.inputFill,
    required this.drawerBg,
  });
}

/// Get colors for a theme
CyberTermColors getThemeColors(CyberTermTheme theme) {
  switch (theme) {
    case CyberTermTheme.p1Green:
      return const CyberTermColors(
        background: Color(0xFF0A0F0A),
        surface: Color(0xFF0F1A0F),
        surfaceLight: Color(0xFF162016),
        primary: Color(0xFF33FF33),
        primaryDim: Color(0xFF1A8A1A),
        textColor: Color(0xFF33FF33),
        textDim: Color(0xFF1A6B1A),
        accent: Color(0xFF66FF66),
        error: Color(0xFFFF3333),
        border: Color(0xFF1A3A1A),
        userBubble: Color(0xFF1A2F1A),
        botBubble: Color(0xFF0F1A0F),
        inputFill: Color(0xFF0F1A0F),
        drawerBg: Color(0xFF0A120A),
      );
    case CyberTermTheme.p3Amber:
      return const CyberTermColors(
        background: Color(0xFF0F0A00),
        surface: Color(0xFF1A1200),
        surfaceLight: Color(0xFF241A00),
        primary: Color(0xFFFFB300),
        primaryDim: Color(0xFF8A6200),
        textColor: Color(0xFFFFB300),
        textDim: Color(0xFF8A7A33),
        accent: Color(0xFFFFD54F),
        error: Color(0xFFFF5252),
        border: Color(0xFF3A2A00),
        userBubble: Color(0xFF2A1F00),
        botBubble: Color(0xFF1A1200),
        inputFill: Color(0xFF1A1200),
        drawerBg: Color(0xFF0D0900),
      );
    case CyberTermTheme.p4White:
      return const CyberTermColors(
        background: Color(0xFF0A0A0F),
        surface: Color(0xFF12121A),
        surfaceLight: Color(0xFF1A1A24),
        primary: Color(0xFFE0E0FF),
        primaryDim: Color(0xFF7A7A8A),
        textColor: Color(0xFFE0E0FF),
        textDim: Color(0xFF7A7A9A),
        accent: Color(0xFFFFFFFF),
        error: Color(0xFFFF4444),
        border: Color(0xFF2A2A3A),
        userBubble: Color(0xFF1A1A2A),
        botBubble: Color(0xFF12121A),
        inputFill: Color(0xFF12121A),
        drawerBg: Color(0xFF08080D),
      );
    case CyberTermTheme.neonCyan:
      return const CyberTermColors(
        background: Color(0xFF050A0F),
        surface: Color(0xFF0A1520),
        surfaceLight: Color(0xFF0F1F2F),
        primary: Color(0xFF00FFFF),
        primaryDim: Color(0xFF007A7A),
        textColor: Color(0xFF00FFFF),
        textDim: Color(0xFF337A7A),
        accent: Color(0xFFFF00FF),
        error: Color(0xFFFF3366),
        border: Color(0xFF0A2A3A),
        userBubble: Color(0xFF0A1F2A),
        botBubble: Color(0xFF0A1520),
        inputFill: Color(0xFF0A1520),
        drawerBg: Color(0xFF040810),
      );
    case CyberTermTheme.synthwave:
      return const CyberTermColors(
        background: Color(0xFF0F0A1A),
        surface: Color(0xFF1A1030),
        surfaceLight: Color(0xFF241640),
        primary: Color(0xFFFF66FF),
        primaryDim: Color(0xFF8A3A8A),
        textColor: Color(0xFFE0B0FF),
        textDim: Color(0xFF8A6AAA),
        accent: Color(0xFF00FFFF),
        error: Color(0xFFFF3333),
        border: Color(0xFF2A1A3A),
        userBubble: Color(0xFF2A1040),
        botBubble: Color(0xFF1A1030),
        inputFill: Color(0xFF1A1030),
        drawerBg: Color(0xFF0A0614),
      );
  }
}

/// Build a full ThemeData from a CyberTerm theme
ThemeData buildCyberTermTheme(CyberTermTheme theme) {
  final colors = getThemeColors(theme);
  final monoTextTheme = GoogleFonts.jetBrainsMonoTextTheme();

  return ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    scaffoldBackgroundColor: colors.background,

    colorScheme: ColorScheme.dark(
      primary: colors.primary,
      onPrimary: colors.background,
      secondary: colors.accent,
      onSecondary: colors.background,
      surface: colors.surface,
      onSurface: colors.textColor,
      error: colors.error,
      onError: Colors.white,
      primaryContainer: colors.userBubble,
      onPrimaryContainer: colors.textColor,
      secondaryContainer: colors.primaryDim,
      onSecondaryContainer: colors.textColor,
      surfaceContainerHighest: colors.surfaceLight,
      outline: colors.border,
    ),

    // Typography — all monospace
    textTheme: monoTextTheme.apply(
      bodyColor: colors.textColor,
      displayColor: colors.textColor,
    ),

    // AppBar
    appBarTheme: AppBarTheme(
      backgroundColor: colors.background,
      foregroundColor: colors.primary,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.jetBrainsMono(
        color: colors.primary,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(color: colors.primary),
      shape: Border(
        bottom: BorderSide(color: colors.border, width: 1),
      ),
    ),

    // Drawer
    drawerTheme: DrawerThemeData(
      backgroundColor: colors.drawerBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    ),

    // Cards — sharp corners, bordered
    cardTheme: CardThemeData(
      color: colors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: colors.border, width: 1),
      ),
      margin: const EdgeInsets.symmetric(vertical: 4),
    ),

    // Input fields
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colors.inputFill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: colors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: colors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: colors.primary, width: 2),
      ),
      labelStyle: TextStyle(color: colors.primaryDim),
      hintStyle: TextStyle(color: colors.textDim),
      helperStyle: TextStyle(color: colors.textDim, fontSize: 11),
      prefixIconColor: colors.primaryDim,
      suffixIconColor: colors.primaryDim,
    ),

    // Dialogs
    dialogTheme: DialogThemeData(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: colors.primary, width: 1),
      ),
      titleTextStyle: GoogleFonts.jetBrainsMono(
        color: colors.primary,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),

    // Buttons
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: colors.primary,
        foregroundColor: colors.background,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        textStyle: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.bold),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colors.primary,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        textStyle: GoogleFonts.jetBrainsMono(),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.primary,
        side: BorderSide(color: colors.border),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        textStyle: GoogleFonts.jetBrainsMono(),
      ),
    ),

    // FAB
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: colors.primary,
      foregroundColor: colors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      elevation: 0,
    ),

    // ListTile
    listTileTheme: ListTileThemeData(
      textColor: colors.textColor,
      iconColor: colors.primaryDim,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    ),

    // Slider
    sliderTheme: SliderThemeData(
      activeTrackColor: colors.primary,
      inactiveTrackColor: colors.border,
      thumbColor: colors.primary,
      overlayColor: colors.primary.withOpacity(0.2),
      valueIndicatorColor: colors.primary,
      valueIndicatorTextStyle: GoogleFonts.jetBrainsMono(
        color: colors.background,
        fontSize: 12,
      ),
    ),

    // Divider
    dividerTheme: DividerThemeData(
      color: colors.border,
      thickness: 1,
    ),

    // SnackBar
    snackBarTheme: SnackBarThemeData(
      backgroundColor: colors.surface,
      contentTextStyle: GoogleFonts.jetBrainsMono(color: colors.textColor),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colors.primary),
      ),
      behavior: SnackBarBehavior.floating,
    ),

    // Bottom Sheet
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: colors.border),
      ),
    ),

    // ExpansionTile
    expansionTileTheme: ExpansionTileThemeData(
      iconColor: colors.primaryDim,
      collapsedIconColor: colors.primaryDim,
      textColor: colors.textColor,
      collapsedTextColor: colors.textDim,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
    ),

    // Icon
    iconTheme: IconThemeData(color: colors.primaryDim),

    // Page transitions
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}

/// Extension to access CyberTerm colors from BuildContext
extension CyberTermColorsExtension on ThemeData {
  /// Get CyberTerm-specific colors. Falls back to P1 Green if theme not recognized.
  CyberTermColors get cyberTermColors {
    // Match by background color
    for (final theme in CyberTermTheme.values) {
      final colors = getThemeColors(theme);
      if (scaffoldBackgroundColor == colors.background) {
        return colors;
      }
    }
    return getThemeColors(CyberTermTheme.p1Green);
  }
}
