// Theme_Engine — четыре монохромные темы NOCTIS:
// Pure White, Pure Black, Graphite (тёмно-серый), Paper (тёплый светлый).
// Все цвета строго R==G==B.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'monochrome_palette.dart';

enum NoctisThemePalette { pureWhite, pureBlack, graphite, paper }

extension NoctisThemePaletteX on NoctisThemePalette {
  String get title {
    switch (this) {
      case NoctisThemePalette.pureWhite:
        return 'Pure White';
      case NoctisThemePalette.pureBlack:
        return 'Pure Black';
      case NoctisThemePalette.graphite:
        return 'Graphite';
      case NoctisThemePalette.paper:
        return 'Paper';
    }
  }

  bool get isDark =>
      this == NoctisThemePalette.pureBlack || this == NoctisThemePalette.graphite;
}

enum NoctisThemeMode { system, light, dark }

extension NoctisThemeModeMaterial on NoctisThemeMode {
  ThemeMode toMaterial() {
    switch (this) {
      case NoctisThemeMode.system:
        return ThemeMode.system;
      case NoctisThemeMode.light:
        return ThemeMode.light;
      case NoctisThemeMode.dark:
        return ThemeMode.dark;
    }
  }
}

final StateProvider<NoctisThemeMode> themeModeProvider =
    StateProvider<NoctisThemeMode>((Ref ref) => NoctisThemeMode.system);

/// Активные палитры для светлого и тёмного режимов.
final StateProvider<NoctisThemePalette> lightPaletteProvider =
    StateProvider<NoctisThemePalette>((Ref ref) => NoctisThemePalette.pureWhite);

final StateProvider<NoctisThemePalette> darkPaletteProvider =
    StateProvider<NoctisThemePalette>((Ref ref) => NoctisThemePalette.pureBlack);

class ThemeEngine {
  ThemeEngine._();

  static const String _fontFamily = 'NoctisSans';

  static ThemeData buildFor(NoctisThemePalette p) {
    switch (p) {
      case NoctisThemePalette.pureWhite:
        return _build(
          brightness: Brightness.light,
          background: MonochromePalette.white,
          surface: MonochromePalette.porcelain,
          surfaceAlt: MonochromePalette.paper,
          outline: MonochromePalette.pearl,
          outlineStrong: MonochromePalette.silver,
          primary: MonochromePalette.black,
          onPrimary: MonochromePalette.white,
          text: MonochromePalette.black,
          textMuted: MonochromePalette.stone,
          textFaint: MonochromePalette.ash,
        );
      case NoctisThemePalette.paper:
        // Paper — тёплый светлый: чуть приглушённый фон, мягкие границы.
        return _build(
          brightness: Brightness.light,
          background: MonochromePalette.paper,
          surface: MonochromePalette.porcelain,
          surfaceAlt: MonochromePalette.pearl,
          outline: MonochromePalette.silver,
          outlineStrong: MonochromePalette.smoke,
          primary: MonochromePalette.graphite,
          onPrimary: MonochromePalette.porcelain,
          text: MonochromePalette.graphite,
          textMuted: MonochromePalette.stone,
          textFaint: MonochromePalette.ash,
        );
      case NoctisThemePalette.pureBlack:
        return _build(
          brightness: Brightness.dark,
          background: MonochromePalette.black,
          surface: MonochromePalette.ink,
          surfaceAlt: MonochromePalette.graphite,
          outline: MonochromePalette.iron,
          outlineStrong: MonochromePalette.steel,
          primary: MonochromePalette.white,
          onPrimary: MonochromePalette.black,
          text: MonochromePalette.white,
          textMuted: MonochromePalette.silver,
          textFaint: MonochromePalette.smoke,
        );
      case NoctisThemePalette.graphite:
        // Graphite — приглушённый тёмный без чистого чёрного.
        return _build(
          brightness: Brightness.dark,
          background: MonochromePalette.obsidian,
          surface: MonochromePalette.graphite,
          surfaceAlt: MonochromePalette.slate,
          outline: MonochromePalette.iron,
          outlineStrong: MonochromePalette.steel,
          primary: MonochromePalette.pearl,
          onPrimary: MonochromePalette.obsidian,
          text: MonochromePalette.pearl,
          textMuted: MonochromePalette.silver,
          textFaint: MonochromePalette.ash,
        );
    }
  }

  static ThemeData _build({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color surfaceAlt,
    required Color outline,
    required Color outlineStrong,
    required Color primary,
    required Color onPrimary,
    required Color text,
    required Color textMuted,
    required Color textFaint,
  }) {
    final ColorScheme scheme = ColorScheme(
      brightness: brightness,
      primary: MonochromePalette.guard(primary),
      onPrimary: MonochromePalette.guard(onPrimary),
      secondary: MonochromePalette.guard(primary),
      onSecondary: MonochromePalette.guard(onPrimary),
      error: MonochromePalette.guard(text),
      onError: MonochromePalette.guard(onPrimary),
      surface: MonochromePalette.guard(surface),
      onSurface: MonochromePalette.guard(text),
      surfaceContainerHighest: MonochromePalette.guard(surfaceAlt),
      onSurfaceVariant: MonochromePalette.guard(textMuted),
      outline: MonochromePalette.guard(outline),
      outlineVariant: MonochromePalette.guard(outlineStrong),
      shadow: MonochromePalette.guard(MonochromePalette.black),
      scrim: MonochromePalette.guard(MonochromePalette.black),
      inverseSurface: MonochromePalette.guard(text),
      onInverseSurface: MonochromePalette.guard(background),
      inversePrimary: MonochromePalette.guard(onPrimary),
    );

    final TextTheme textTheme = TextTheme(
      displayLarge: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 56,
        height: 1.05,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.5,
        color: scheme.onSurface,
      ),
      displayMedium: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 40,
        height: 1.1,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.0,
        color: scheme.onSurface,
      ),
      headlineLarge: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 30,
        height: 1.15,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: scheme.onSurface,
      ),
      headlineMedium: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 24,
        height: 1.2,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      titleLarge: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 20,
        height: 1.25,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      titleMedium: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 16,
        height: 1.3,
        fontWeight: FontWeight.w500,
        color: scheme.onSurface,
      ),
      bodyLarge: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 16,
        height: 1.45,
        fontWeight: FontWeight.w400,
        color: scheme.onSurface,
      ),
      bodyMedium: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 14,
        height: 1.45,
        fontWeight: FontWeight.w400,
        color: scheme.onSurfaceVariant,
      ),
      bodySmall: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 12,
        height: 1.4,
        fontWeight: FontWeight.w400,
        color: MonochromePalette.guard(textFaint),
      ),
      labelLarge: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 14,
        height: 1.2,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        color: scheme.onSurface,
      ),
      labelMedium: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 12,
        height: 1.2,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: scheme.onSurfaceVariant,
      ),
    );

    return ThemeData(
      brightness: brightness,
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: MonochromePalette.guard(background),
      canvasColor: MonochromePalette.guard(background),
      splashColor: scheme.onSurface.withOpacity(0.04),
      highlightColor: scheme.onSurface.withOpacity(0.04),
      dividerColor: scheme.outline,
      iconTheme: IconThemeData(color: scheme.onSurface, size: 22),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: MonochromePalette.guard(background),
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: IconThemeData(color: scheme.onSurface, size: 22),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: MonochromePalette.guard(background),
        selectedItemColor: scheme.onSurface,
        unselectedItemColor: scheme.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: MonochromePalette.guard(surface),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        hintStyle: textTheme.bodyLarge?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        labelStyle: textTheme.bodyMedium,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: scheme.outline, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: scheme.outline, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: scheme.onSurface, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: scheme.onSurface, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: scheme.onSurface, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          minimumSize: const Size.fromHeight(56),
          side: BorderSide(color: scheme.outlineVariant, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.onSurface,
          textStyle: textTheme.labelLarge,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outline,
        thickness: 0.5,
        space: 0.5,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
