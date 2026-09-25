import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/language_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';

/// Compact 🌐 Language ▾ dropdown that fits in the home header.
/// Switches the global app locale immediately and persists the choice.
class LanguageSelectorButton extends ConsumerWidget {
  const LanguageSelectorButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(languageProvider.notifier);
    final currentLocale = ref.watch(languageProvider);
    final l10n = AppLocalizations.of(context);

    final items = [
      _LangItem(const Locale('en'), '🌐', 'English'),
      _LangItem(const Locale('mr'), '🌐', 'मराठी'),
      _LangItem(const Locale('hi'), '🌐', 'हिन्दी'),
    ];

    final currentItem = items.firstWhere(
      (i) => i.locale.languageCode == currentLocale.languageCode,
      orElse: () => items.first,
    );

    return PopupMenuButton<Locale>(
      initialValue: currentLocale,
      tooltip: l10n?.selectLanguage ?? 'Select Language',
      color: AppColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      onSelected: (locale) => notifier.setLocale(locale),
      itemBuilder: (_) => items
          .map(
            (item) => PopupMenuItem<Locale>(
              value: item.locale,
              child: Row(
                children: [
                  Text(item.flag, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: item.locale == currentLocale
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: item.locale == currentLocale
                          ? AppColors.primary
                          : AppColors.onSurface,
                    ),
                  ),
                  if (item.locale == currentLocale) ...[
                    const Spacer(),
                    Icon(Icons.check, size: 14, color: AppColors.primary),
                  ],
                ],
              ),
            ),
          )
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🌐', style: TextStyle(fontSize: 11)),
            const SizedBox(width: 4),
            Text(
              currentItem.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.arrow_drop_down, size: 14, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

class _LangItem {
  const _LangItem(this.locale, this.flag, this.label);
  final Locale locale;
  final String flag;
  final String label;
}
