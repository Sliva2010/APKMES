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
    final ThemeData lightTheme = ThemeEngine.buildLight();
    final ThemeData darkTheme = ThemeEngine.buildDark();
    final GoRouterConfig config = ref.watch(routerProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            mode == NoctisThemeMode.light ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness:
            mode == NoctisThemeMode.light ? Brightness.dark : Brightness.light,
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
