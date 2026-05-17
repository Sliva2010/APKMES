// Корневой виджет приложения NOCTIS.
// Настраивает Theme_Engine и роутер навигации.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/routing/router.dart';
import 'core/theme/theme_engine.dart';

class NoctisApp extends ConsumerWidget {
  const NoctisApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final NoctisThemeMode mode = ref.watch(themeModeProvider);
    final NoctisThemePalette light = ref.watch(lightPaletteProvider);
    final NoctisThemePalette dark = ref.watch(darkPaletteProvider);

    final ThemeData lightTheme = ThemeEngine.buildFor(light);
    final ThemeData darkTheme = ThemeEngine.buildFor(dark);
    final GoRouterConfig config = ref.watch(routerProvider);

    final bool isDarkActive = mode == NoctisThemeMode.dark ||
        (mode == NoctisThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            isDarkActive ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness:
            isDarkActive ? Brightness.light : Brightness.dark,
      ),
      child: MaterialApp.router(
        title: 'NOCTIS',
        debugShowCheckedModeBanner: false,
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: mode.toMaterial(),
        themeAnimationDuration: const Duration(milliseconds: 300),
        themeAnimationCurve: Curves.easeInOutCubic,
        routerConfig: config.router,
      ),
    );
  }
}
