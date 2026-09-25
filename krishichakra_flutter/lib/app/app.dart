import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router.dart';
import '../core/theme/app_theme.dart';
import '../core/providers/language_provider.dart';
import '../l10n/app_localizations.dart';

class KrishiChakraApp extends ConsumerWidget {
  const KrishiChakraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(languageProvider);

    return MaterialApp.router(
      title: 'KrishiChakra',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      routerConfig: router,
      // ── Localization ──────────────────────────────────────────────────────
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
