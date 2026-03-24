import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Brand Colors ──────────────────────────────────────────────────────────────
const _gold = Color(0xFFE8C97A);
const _blue = Color(0xFF7A9EE8);
const _green = Color(0xFF7AE8B8);
const _danger = Color(0xFFE87A7A);

// ── Dark Palette ──────────────────────────────────────────────────────────────
const _darkBg = Color(0xFF0D0D0F);
const _darkSurface = Color(0xFF141418);
const _darkPanel = Color(0xFF1A1A20);
const _darkBorder = Color(0xFF2A2A35);
const _darkText = Color(0xFFE8E6DF);
const _darkMuted = Color(0xFF6B6870);
const _darkUserBubble = Color(0xFF1E1E28);

// ── Light Palette ─────────────────────────────────────────────────────────────
const _lightBg = Color(0xFFF0EFF0);
const _lightSurface = Color(0xFFFFFFFF);
const _lightPanel = Color(0xFFF5F4F5);
const _lightBorder = Color(0xFFE2E1E4);
const _lightText = Color(0xFF1B1A1F);
const _lightMuted = Color(0xFF8B8891);
const _lightUserBubble = Color(0xFFEDE9FF);

class AppTheme {
  static ThemeData dark() => _build(
        brightness: Brightness.dark,
        bg: _darkBg,
        surface: _darkSurface,
        panel: _darkPanel,
        border: _darkBorder,
        text: _darkText,
        muted: _darkMuted,
        userBubble: _darkUserBubble,
      );

  static ThemeData light() => _build(
        brightness: Brightness.light,
        bg: _lightBg,
        surface: _lightSurface,
        panel: _lightPanel,
        border: _lightBorder,
        text: _lightText,
        muted: _lightMuted,
        userBubble: _lightUserBubble,
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color bg,
    required Color surface,
    required Color panel,
    required Color border,
    required Color text,
    required Color muted,
    required Color userBubble,
  }) {
    final mono = GoogleFonts.dmMono();
    final sans = GoogleFonts.syne();

    return ThemeData(
      brightness: brightness,
      useMaterial3: true,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: _gold,
        onPrimary: Colors.black,
        primaryContainer: panel,
        onPrimaryContainer: text,
        secondary: _blue,
        onSecondary: Colors.black,
        secondaryContainer: panel,
        onSecondaryContainer: text,
        tertiary: _green,
        onTertiary: Colors.black,
        error: _danger,
        onError: Colors.black,
        surface: surface,
        onSurface: text,
        surfaceContainerHighest: panel,
        outline: border,
        outlineVariant: border.withOpacity(0.5),
      ),
      scaffoldBackgroundColor: bg,
      drawerTheme: DrawerThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(),
        width: 300,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: sans.copyWith(
          color: text,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.02 * 14,
        ),
        iconTheme: IconThemeData(color: muted, size: 18),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: panel,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: border, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: border, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _gold, width: 1),
        ),
        hintStyle: mono.copyWith(color: muted, fontSize: 13),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      textTheme: GoogleFonts.dmMonoTextTheme().copyWith(
        bodyMedium: mono.copyWith(color: text, fontSize: 13, height: 1.7),
        bodySmall: mono.copyWith(color: muted, fontSize: 11),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 0.5, space: 0),
      extensions: [
        AppColors(
          gold: _gold,
          blue: _blue,
          green: _green,
          danger: _danger,
          bg: bg,
          surface: surface,
          panel: panel,
          border: border,
          text: text,
          muted: muted,
          userBubble: userBubble,
        ),
      ],
    );
  }
}

// ── Theme Extension for custom colors ─────────────────────────────────────────

class AppColors extends ThemeExtension<AppColors> {
  final Color gold;
  final Color blue;
  final Color green;
  final Color danger;
  final Color bg;
  final Color surface;
  final Color panel;
  final Color border;
  final Color text;
  final Color muted;
  final Color userBubble;

  const AppColors({
    required this.gold,
    required this.blue,
    required this.green,
    required this.danger,
    required this.bg,
    required this.surface,
    required this.panel,
    required this.border,
    required this.text,
    required this.muted,
    required this.userBubble,
  });

  @override
  AppColors copyWith({
    Color? gold, Color? blue, Color? green, Color? danger,
    Color? bg, Color? surface, Color? panel, Color? border,
    Color? text, Color? muted, Color? userBubble,
  }) => AppColors(
        gold: gold ?? this.gold,
        blue: blue ?? this.blue,
        green: green ?? this.green,
        danger: danger ?? this.danger,
        bg: bg ?? this.bg,
        surface: surface ?? this.surface,
        panel: panel ?? this.panel,
        border: border ?? this.border,
        text: text ?? this.text,
        muted: muted ?? this.muted,
        userBubble: userBubble ?? this.userBubble,
      );

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      gold: Color.lerp(gold, other.gold, t)!,
      blue: Color.lerp(blue, other.blue, t)!,
      green: Color.lerp(green, other.green, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      panel: Color.lerp(panel, other.panel, t)!,
      border: Color.lerp(border, other.border, t)!,
      text: Color.lerp(text, other.text, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      userBubble: Color.lerp(userBubble, other.userBubble, t)!,
    );
  }
}

// Helper extension
extension ThemeAppColors on ThemeData {
  AppColors get appColors =>
      extension<AppColors>() ?? AppColors(
        gold: const Color(0xFFE8C97A),
        blue: const Color(0xFF7A9EE8),
        green: const Color(0xFF7AE8B8),
        danger: const Color(0xFFE87A7A),
        bg: const Color(0xFF0D0D0F),
        surface: const Color(0xFF141418),
        panel: const Color(0xFF1A1A20),
        border: const Color(0xFF2A2A35),
        text: const Color(0xFFE8E6DF),
        muted: const Color(0xFF6B6870),
        userBubble: const Color(0xFF1E1E28),
      );
}
