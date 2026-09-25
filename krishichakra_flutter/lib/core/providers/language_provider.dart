import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Constants ────────────────────────────────────────────────────────────────

const _kLangKey = 'kc_language_code';

const kSupportedLocales = [
  Locale('en'),
  Locale('mr'),
  Locale('hi'),
];

// ─── Language Notifier ────────────────────────────────────────────────────────

/// Global language controller.
/// Call [setLocale] to switch language — the entire app rebuilds immediately.
/// The choice is persisted via SharedPreferences.
class LanguageNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    _loadSaved();
    return const Locale('en');
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_kLangKey);
    if (code != null && code.isNotEmpty) {
      final saved = Locale(code);
      if (kSupportedLocales.contains(saved)) {
        state = saved;
      }
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (!kSupportedLocales.contains(locale)) return;
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLangKey, locale.languageCode);
  }

  String get currentLanguageLabel {
    switch (state.languageCode) {
      case 'mr':
        return 'मराठी';
      case 'hi':
        return 'हिन्दी';
      default:
        return 'English';
    }
  }
}

final languageProvider =
    NotifierProvider<LanguageNotifier, Locale>(LanguageNotifier.new);
